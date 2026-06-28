from __future__ import annotations

import logging
import os
import subprocess
import time
from pathlib import Path

LOGGER = logging.getLogger("navisworks_mcp.loader")


def try_load_navisworks_plugin(timeout_seconds: float = 10) -> bool:
    if os.name != "nt":
        return False

    plugin_path = _find_plugin_path()
    automation_path = _find_automation_path()
    if plugin_path is None or automation_path is None:
        LOGGER.info("Could not find Navisworks plugin or Automation API for explicit load.")
        return False

    command = [
        "powershell.exe",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-Command",
        _build_powershell_command(automation_path, plugin_path),
    ]
    try:
        completed = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=timeout_seconds,
            creationflags=subprocess.CREATE_NO_WINDOW if hasattr(subprocess, "CREATE_NO_WINDOW") else 0,
        )
    except Exception:
        LOGGER.exception("Could not invoke Navisworks Automation plugin loader.")
        return False

    if completed.returncode != 0:
        LOGGER.warning(
            "Navisworks Automation plugin loader failed with code %s. stdout=%r stderr=%r",
            completed.returncode,
            completed.stdout,
            completed.stderr,
        )
        return False

    LOGGER.info("Navisworks Automation plugin loader completed: %s", completed.stdout.strip())
    return True


def wait_for(predicate, timeout_seconds: float = 5, interval_seconds: float = 0.2) -> bool:
    deadline = time.monotonic() + timeout_seconds
    while time.monotonic() < deadline:
        if predicate():
            return True
        time.sleep(interval_seconds)
    return predicate()


def _find_plugin_path() -> Path | None:
    candidates: list[Path] = []

    program_files = os.environ.get("ProgramFiles")
    if program_files:
        autodesk = Path(program_files) / "Autodesk"
        for product in ("Navisworks Manage", "Navisworks Simulate"):
            candidates.extend(autodesk.glob(f"{product} */Plugins/NavisworksMcpAddin.dll"))
            candidates.extend(autodesk.glob(f"{product} */Plugins/NavisworksMcp/NavisworksMcpAddin.dll"))

    appdata = os.environ.get("APPDATA")
    if appdata:
        candidates.append(Path(appdata) / "Autodesk/ApplicationPlugins/NavisworksMcp.bundle/Contents/NavisworksMcpAddin.dll")

    program_data = os.environ.get("ProgramData")
    if program_data:
        candidates.append(Path(program_data) / "Autodesk/ApplicationPlugins/NavisworksMcp.bundle/Contents/NavisworksMcpAddin.dll")

    return _newest_existing(candidates)


def _find_automation_path() -> Path | None:
    candidates: list[Path] = []
    program_files = os.environ.get("ProgramFiles")
    if program_files:
        autodesk = Path(program_files) / "Autodesk"
        for product in ("Navisworks Manage", "Navisworks Simulate"):
            candidates.extend(autodesk.glob(f"{product} */Autodesk.Navisworks.Automation.dll"))
    return _newest_existing(candidates)


def _newest_existing(paths: list[Path]) -> Path | None:
    existing = [path for path in paths if path.exists()]
    if not existing:
        return None
    return max(existing, key=lambda path: path.stat().st_mtime)


def _build_powershell_command(automation_path: Path, plugin_path: Path) -> str:
    automation = _ps_single_quote(str(automation_path))
    plugin = _ps_single_quote(str(plugin_path))
    return f"""
$ErrorActionPreference = 'Stop'
Add-Type -Path {automation}
$app = [Autodesk.Navisworks.Api.Automation.NavisworksApplication]::TryGetRunningInstance()
if ($null -eq $app) {{
    throw 'No running Navisworks instance was found.'
}}
$app.AddPluginAssembly({plugin})
$app.ExecuteAddInPlugin('NavisworksMcpAddin.Plugin.RRDL', @())
Write-Output 'Navisworks MCP plugin load requested.'
"""


def _ps_single_quote(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"
