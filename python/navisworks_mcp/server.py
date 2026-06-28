from __future__ import annotations

import logging
import os

from mcp.server.fastmcp import FastMCP
from mcp.server.transport_security import TransportSecuritySettings

from .navisworks_connection import bridge_from_env

logging.basicConfig(level=os.getenv("NAVISWORKS_MCP_LOG_LEVEL", "INFO"))

_disable_dns_rebinding_protection = os.getenv("MCP_DISABLE_DNS_REBINDING_PROTECTION", "").lower() in {
    "1",
    "true",
    "yes",
}
_allowed_hosts = [host.strip() for host in os.getenv("MCP_ALLOWED_HOSTS", "").split(",") if host.strip()]
_allowed_origins = [origin.strip() for origin in os.getenv("MCP_ALLOWED_ORIGINS", "").split(",") if origin.strip()]

mcp = FastMCP(
    "navisworks-mcp",
    host=os.getenv("MCP_HTTP_HOST", "127.0.0.1"),
    port=int(os.getenv("MCP_HTTP_PORT", "8000")),
    streamable_http_path=os.getenv("MCP_HTTP_PATH", "/mcp"),
    transport_security=TransportSecuritySettings(
        enable_dns_rebinding_protection=not _disable_dns_rebinding_protection,
        allowed_hosts=_allowed_hosts,
        allowed_origins=_allowed_origins,
    ),
)
_bridge = None

if os.getenv(
    "NAVISWORKS_MCP_START_BRIDGE_ON_IMPORT",
    "true",
).lower() in {"1", "true", "yes"}:
    try:
        _bridge = bridge_from_env()
    except RuntimeError:
        logging.exception("Could not start Navisworks WebSocket bridge during startup. It will retry on tool use.")


def get_bridge():
    global _bridge
    if _bridge is None:
        _bridge = bridge_from_env()
    return _bridge

RUN_NAVISWORKS_CODE_DESCRIPTION = """
Execute a C# snippet inside the active Navisworks document.

Important: send only the body of the generated C# method. Do not send a full
C# file, namespace, class, method declaration, or top-level using directives.
The runtime already injects these variables:

- doc: Autodesk.Navisworks.Api.Document

The runtime already imports common namespaces including Autodesk.Navisworks.Api,
System, System.Linq, and System.Collections.Generic. Do not redeclare doc.
Always return a string. Navisworks is primarily a coordination/review API; keep
operations focused on document inspection, selection, viewpoints, properties,
clash/coordination data, and supported Navisworks API changes.
"""

NAVISWORKS_MCP_PROMPT = """
You are using the Navisworks MCP tool `run_navisworks_code` to execute C# inside Autodesk Navisworks.

Rules for every call:

1. Send only the body of the C# method.
2. Do not include `using` directives, namespace declarations, class declarations, or a `Run` method.
3. Do not redeclare `doc`; it is already provided.
4. Available variables:
   - `doc`: Autodesk.Navisworks.Api.Document
5. Common namespaces are already imported: Autodesk.Navisworks.Api, System, System.Linq, System.Collections.Generic.
6. Always return a string.
7. Before using version-sensitive Navisworks API calls, call `get_navisworks_context()` and adapt the code to the returned version.
8. Prefer read-only inspection unless the user explicitly asks for a supported Navisworks document change.
9. Navisworks is not a BIM authoring environment like Revit; do not promise to create native walls, doors, families, or authored model geometry.
10. Keep snippets small and focused.
11. For large tasks, split the work into multiple `run_navisworks_code` calls, for example:
   - inspect document/version/selection
   - collect model item properties
   - create or inspect viewpoints
   - inspect selection/search sets
   - inspect clash/coordination information where the installed API supports it
12. Avoid combining document inspection, selection edits, viewpoints, clash checks, exports, and reporting in one snippet.
13. If a script is rejected or fails to compile, retry with a smaller snippet that performs one concrete step.
14. If an operation may be destructive, explain the intended change before running it.

Valid read example:

var selected = doc.CurrentSelection.SelectedItems;
return "Selected items: " + selected.Count;

Valid document info example:

return doc.Title;

Invalid examples:

using Autodesk.Navisworks.Api; // invalid: already imported by the wrapper
Document doc = Autodesk.Navisworks.Api.Application.ActiveDocument; // invalid: doc already exists
public class Script { ... } // invalid: wrapper already creates the class

Large-task strategy:

Instead of one huge script that inspects every model item, modifies selection, creates viewpoints, and exports reports, make several smaller calls. First validate context and selection, then collect properties, then perform focused changes or reports.
"""


@mcp.tool(description=RUN_NAVISWORKS_CODE_DESCRIPTION)
def run_navisworks_code(code: str, timeout_seconds: float = 60) -> str:
    """Execute a C# method-body snippet inside Navisworks through the loaded Navisworks MCP plugin."""
    response = get_bridge().run_code(code, timeout_seconds=timeout_seconds)
    if response.ok:
        return response.result or ""

    details = f"\n\n{response.details}" if response.details else ""
    raise RuntimeError(f"Navisworks code failed: {response.error or 'Unknown error'}{details}")


@mcp.tool()
def get_navisworks_mcp_prompt() -> str:
    """Return the usage prompt/instructions for generating valid run_navisworks_code snippets."""
    return NAVISWORKS_MCP_PROMPT.strip()


@mcp.tool()
def get_navisworks_context(timeout_seconds: float = 30) -> str:
    """Return Navisworks version and active document context for version-aware code generation."""
    code = """
var appType = typeof(Autodesk.Navisworks.Api.Application);
var versionProperty = appType.GetProperty("Version");
object versionValue = null;
if (versionProperty != null)
{
    versionValue = versionProperty.GetValue(null, null);
}
var appVersion = versionValue == null ? "" : versionValue.ToString();

object titleValue = null;
var titleProperty = doc.GetType().GetProperty("Title");
if (titleProperty != null)
{
    titleValue = titleProperty.GetValue(doc, null);
}
var title = titleValue == null ? "" : titleValue.ToString();

object fileNameValue = null;
var fileNameProperty = doc.GetType().GetProperty("FileName");
if (fileNameProperty != null)
{
    fileNameValue = fileNameProperty.GetValue(doc, null);
}
var fileName = fileNameValue == null ? "" : fileNameValue.ToString();

var selectionCount = 0;
try
{
    object currentSelection = null;
    var currentSelectionProperty = doc.GetType().GetProperty("CurrentSelection");
    if (currentSelectionProperty != null)
    {
        currentSelection = currentSelectionProperty.GetValue(doc, null);
    }

    object selectedItems = null;
    if (currentSelection != null)
    {
        var selectedItemsProperty = currentSelection.GetType().GetProperty("SelectedItems");
        if (selectedItemsProperty != null)
        {
            selectedItems = selectedItemsProperty.GetValue(currentSelection, null);
        }
    }

    object countValue = null;
    if (selectedItems != null)
    {
        var countProperty = selectedItems.GetType().GetProperty("Count");
        if (countProperty != null)
        {
            countValue = countProperty.GetValue(selectedItems, null);
        }
    }

    selectionCount = countValue == null ? 0 : Convert.ToInt32(countValue);
}
catch
{
    selectionCount = 0;
}

var context = new Dictionary<string, object>();
context["connected"] = true;
context["navisworksVersion"] = appVersion;
context["documentTitle"] = title;
context["documentPath"] = fileName;
context["selectedItemCount"] = selectionCount;
return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(context);
"""
    response = get_bridge().run_code(code, timeout_seconds=timeout_seconds)
    if response.ok:
        return response.result or "{}"

    details = f"\n\n{response.details}" if response.details else ""
    raise RuntimeError(f"Could not get Navisworks context: {response.error or 'Unknown error'}{details}")



def main() -> None:
    transport = os.getenv("MCP_TRANSPORT", "stdio")
    if transport not in {"stdio", "sse", "streamable-http"}:
        raise ValueError("MCP_TRANSPORT must be one of: stdio, sse, streamable-http")
    mcp.run(transport=transport)


if __name__ == "__main__":
    main()
