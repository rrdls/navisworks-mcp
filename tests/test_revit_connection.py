from __future__ import annotations

import asyncio
import json
import socket
import sys
from pathlib import Path

import websockets

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "python"))

from revit_mcp.revit_connection import RevitBridge


def free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


async def fake_revit_client(port: int, expected_code: str, result: str) -> None:
    async with websockets.connect(f"ws://127.0.0.1:{port}") as websocket:
        await websocket.send(json.dumps({"type": "hello"}))
        command = json.loads(await websocket.recv())
        assert command["code"] == expected_code
        assert command["id"]
        await websocket.send(json.dumps({"id": command["id"], "ok": True, "result": result}))


def test_run_code_round_trips_to_connected_revit_client() -> None:
    port = free_port()
    bridge = RevitBridge(port=port)
    bridge.start()

    async def scenario() -> None:
        code = "return doc.Title;"
        client_task = asyncio.create_task(fake_revit_client(port, code, "Sample.rvt"))
        await asyncio.sleep(0.1)
        response = await asyncio.to_thread(bridge.run_code, code, 5)
        await client_task
        assert response.ok is True
        assert response.result == "Sample.rvt"

    try:
        asyncio.run(scenario())
    finally:
        bridge.stop()


def test_run_code_reports_missing_revit_connection() -> None:
    port = free_port()
    bridge = RevitBridge(port=port)
    bridge.start()

    try:
        try:
            bridge.run_code("return doc.Title;", timeout_seconds=1)
        except RuntimeError as exc:
            assert "Revit add-in is not connected" in str(exc)
        else:
            raise AssertionError("Expected RuntimeError when no Revit client is connected.")
    finally:
        bridge.stop()

