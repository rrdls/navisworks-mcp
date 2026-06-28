from __future__ import annotations

import asyncio
import json
import logging
import os
import threading
import uuid
from concurrent.futures import Future as ThreadFuture
from concurrent.futures import TimeoutError as ThreadTimeoutError
from dataclasses import dataclass
from typing import Any

import websockets

from .navisworks_loader import try_load_navisworks_plugin, wait_for
from .protocol import NavisworksCommand, NavisworksResponse

LOGGER = logging.getLogger("navisworks_mcp.websocket")


@dataclass
class _PendingCall:
    future: asyncio.Future[NavisworksResponse]
    code: str


class NavisworksBridge:
    def __init__(self, host: str = "127.0.0.1", port: int = 8765, token: str | None = None) -> None:
        self.host = host
        self.port = port
        self.token = token
        self._loop: asyncio.AbstractEventLoop | None = None
        self._thread: threading.Thread | None = None
        self._ready = threading.Event()
        self._start_error: BaseException | None = None
        self._client: Any | None = None
        self._server: Any | None = None
        self._pending: dict[str, _PendingCall] = {}
        self._lock = threading.Lock()

    def start(self) -> None:
        with self._lock:
            if self._thread and self._thread.is_alive():
                return

            self._thread = threading.Thread(target=self._run_loop, name="navisworks-mcp-websocket", daemon=True)
            self._thread.start()

        if not self._ready.wait(timeout=5):
            raise RuntimeError("Timed out starting Navisworks WebSocket server.")
        if self._start_error:
            raise RuntimeError("Could not start Navisworks WebSocket server.") from self._start_error

    def stop(self) -> None:
        loop = self._loop
        if loop is None or not loop.is_running():
            return

        async def shutdown() -> None:
            self._fail_pending("Navisworks MCP bridge stopped.")
            if self._client is not None:
                await self._client.close()
                self._client = None
            if self._server is not None:
                self._server.close()
                await self._server.wait_closed()
                self._server = None
            loop.call_soon(loop.stop)

        asyncio.run_coroutine_threadsafe(shutdown(), loop).result(timeout=5)
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout=5)

    def is_connected(self) -> bool:
        return _websocket_is_open(self._client)

    def run_code(self, code: str, timeout_seconds: float = 60) -> NavisworksResponse:
        if not code or not code.strip():
            raise ValueError("code must not be empty")

        self.start()
        if not self._loop:
            raise RuntimeError("WebSocket loop is not running.")

        if not self.is_connected():
            try_load_navisworks_plugin()
            wait_for(self.is_connected, timeout_seconds=5)

        command = NavisworksCommand(id=str(uuid.uuid4()), code=code)
        future: ThreadFuture[NavisworksResponse] = asyncio.run_coroutine_threadsafe(
            self._send_and_wait(command),
            self._loop,
        )
        try:
            return future.result(timeout=timeout_seconds)
        except ThreadTimeoutError as exc:
            future.cancel()
            raise TimeoutError(f"Timed out waiting for Navisworks response after {timeout_seconds} seconds.") from exc

    async def _send_and_wait(self, command: NavisworksCommand) -> NavisworksResponse:
        client = self._client
        if not _websocket_is_open(client):
            raise RuntimeError("Navisworks plugin is not connected. Open Navisworks and run the Navisworks MCP plugin.")

        future: asyncio.Future[NavisworksResponse] = asyncio.get_running_loop().create_future()
        self._pending[command.id] = _PendingCall(future=future, code=command.code)

        try:
            await client.send(json.dumps(command.to_json()))
            return await future
        finally:
            self._pending.pop(command.id, None)

    def _run_loop(self) -> None:
        loop = asyncio.new_event_loop()
        self._loop = loop
        asyncio.set_event_loop(loop)
        try:
            loop.run_until_complete(self._serve())
        except BaseException as exc:
            self._start_error = exc
            self._ready.set()
            return
        self._ready.set()
        loop.run_forever()

    async def _serve(self) -> None:
        self._server = await websockets.serve(self._handle_client, self.host, self.port)
        LOGGER.info("Navisworks WebSocket server listening on ws://%s:%s", self.host, self.port)

    async def _handle_client(self, websocket: Any) -> None:
        if _websocket_is_open(self._client):
            await websocket.close(code=1013, reason="A Navisworks client is already connected.")
            return

        self._client = websocket
        LOGGER.info("Navisworks plugin connected.")

        try:
            async for raw_message in websocket:
                await self._handle_message(raw_message)
        finally:
            if self._client is websocket:
                self._client = None
            self._fail_pending("Navisworks plugin disconnected before returning a response.")
            LOGGER.info("Navisworks plugin disconnected.")

    async def _handle_message(self, raw_message: str | bytes) -> None:
        if isinstance(raw_message, bytes):
            raw_message = raw_message.decode("utf-8")

        payload = json.loads(raw_message)
        if not isinstance(payload, dict):
            raise ValueError("WebSocket message must be a JSON object.")

        if payload.get("type") == "hello":
            await self._handle_hello(payload)
            return

        response = NavisworksResponse.from_json(payload)
        pending = self._pending.get(response.id)
        if pending and not pending.future.done():
            pending.future.set_result(response)
        else:
            LOGGER.warning("Received response for unknown command id %s", response.id)

    async def _handle_hello(self, payload: dict[str, Any]) -> None:
        if self.token and payload.get("token") != self.token:
            if self._client:
                await self._client.close(code=1008, reason="Invalid token.")
            return
        LOGGER.info("Navisworks plugin handshake accepted.")

    def _fail_pending(self, message: str) -> None:
        for pending in list(self._pending.values()):
            if not pending.future.done():
                pending.future.set_exception(RuntimeError(message))
        self._pending.clear()


def bridge_from_env() -> NavisworksBridge:
    host = os.getenv("NAVISWORKS_MCP_HOST", "127.0.0.1")
    port = int(os.getenv("NAVISWORKS_MCP_PORT", "8765"))
    token = os.getenv("NAVISWORKS_MCP_TOKEN") or None
    bridge = NavisworksBridge(host=host, port=port, token=token)
    bridge.start()
    return bridge


def _websocket_is_open(websocket: Any | None) -> bool:
    if websocket is None:
        return False

    closed = getattr(websocket, "closed", None)
    if isinstance(closed, bool):
        return not closed

    state = getattr(websocket, "state", None)
    if state is not None:
        name = getattr(state, "name", "")
        if name:
            return name.upper() == "OPEN"
        return str(state).upper().endswith("OPEN")

    return True
