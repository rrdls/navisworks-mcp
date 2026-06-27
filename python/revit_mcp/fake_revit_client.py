from __future__ import annotations

import argparse
import asyncio
import json
import os

import websockets


async def run_fake_client(url: str, token: str | None, result_prefix: str) -> None:
    async with websockets.connect(url) as websocket:
        await websocket.send(json.dumps({"type": "hello", "token": token}))
        print(f"Connected fake Revit client to {url}")

        async for raw_message in websocket:
            payload = json.loads(raw_message)
            command_id = payload.get("id")
            code = payload.get("code")
            print(f"Received command {command_id}: {code}")

            if not command_id:
                continue

            await websocket.send(
                json.dumps(
                    {
                        "id": command_id,
                        "ok": True,
                        "result": f"{result_prefix}{code}",
                    }
                )
            )


def main() -> None:
    parser = argparse.ArgumentParser(description="Fake Revit WebSocket client for local MCP bridge testing.")
    parser.add_argument("--url", default=os.getenv("REVIT_MCP_WS_URL", "ws://127.0.0.1:8765"))
    parser.add_argument("--token", default=os.getenv("REVIT_MCP_TOKEN"))
    parser.add_argument("--result-prefix", default="fake-result: ")
    args = parser.parse_args()

    asyncio.run(run_fake_client(args.url, args.token, args.result_prefix))


if __name__ == "__main__":
    main()

