from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "python"))

from navisworks_mcp.protocol import NavisworksResponse

REPO_ROOT = Path(__file__).resolve().parents[1]


class FakeBridge:
    def __init__(self) -> None:
        self.code = ""
        self.timeout_seconds = 0.0

    def run_code(self, code: str, timeout_seconds: float) -> NavisworksResponse:
        self.code = code
        self.timeout_seconds = timeout_seconds
        return NavisworksResponse(id="test", ok=True, result="Sample.nwd")


def test_run_navisworks_code_uses_bridge(monkeypatch) -> None:
    monkeypatch.setenv("NAVISWORKS_MCP_START_BRIDGE_ON_IMPORT", "false")

    import navisworks_mcp.server as server

    fake_bridge = FakeBridge()
    monkeypatch.setattr(server, "_bridge", fake_bridge)

    result = server.run_navisworks_code("return doc.Title;", timeout_seconds=12)

    assert result == "Sample.nwd"
    assert fake_bridge.code == "return doc.Title;"
    assert fake_bridge.timeout_seconds == 12


def test_prompt_names_navisworks_tool(monkeypatch) -> None:
    monkeypatch.setenv("NAVISWORKS_MCP_START_BRIDGE_ON_IMPORT", "false")

    import navisworks_mcp.server as server

    prompt = server.get_navisworks_mcp_prompt()

    assert "run_navisworks_code" in prompt
    assert "Autodesk Navisworks" in prompt


def test_prompt_does_not_expose_revit_tool_names(monkeypatch) -> None:
    monkeypatch.setenv("NAVISWORKS_MCP_START_BRIDGE_ON_IMPORT", "false")

    import navisworks_mcp.server as server

    prompt = server.get_navisworks_mcp_prompt()

    assert "run_revit_code" not in prompt
    assert "get_revit_context" not in prompt


def test_package_contents_template_points_to_navisworks_plugin() -> None:
    template_path = REPO_ROOT / "addin" / "NavisworksMcpAddin" / "PackageContents.xml.template"

    root = ET.parse(template_path).getroot()
    component_entry = root.find("./Components/ComponentEntry")
    runtime_requirements = root.find("./Components/RuntimeRequirements")

    assert root.attrib["AutodeskProduct"] == "Navisworks"
    assert component_entry is not None
    assert component_entry.attrib["ModuleName"] == "./Contents/NavisworksMcpAddin.Plugin.dll"
    assert runtime_requirements is not None
    assert runtime_requirements.attrib["OS"] == "Win64"
    assert "Platform" not in runtime_requirements.attrib
    assert "SeriesMin" not in runtime_requirements.attrib

    component_modules = {
        entry.attrib["ModuleName"]
        for entry in root.findall("./Components/ComponentEntry")
    }
    assert "./Contents/NavisworksMcpProbe.Plugin.dll" in component_modules
