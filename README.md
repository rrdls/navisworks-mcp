# Revit MCP

MCP server in Python plus a Revit add-in that executes C# snippets inside Revit through `ExternalEvent` and Roslyn.

The MCP surface is intentionally one generic tool:

```text
run_revit_code(code: string, timeout_seconds: number = 60) -> string
```

There is also an instruction tool for ChatGPT clients that do not consume MCP prompts:

```text
get_revit_mcp_prompt() -> string
```

And a context tool for version-aware code generation:

```text
get_revit_context() -> string
```

## Flow

```text
LLM / MCP client
  -> Python MCP server
  -> localhost WebSocket
  -> Revit add-in
  -> ExternalEvent
  -> Roslyn compiled C#
  -> Revit API
  -> response back to MCP
```

## Requirements

- Windows with Revit 2024, 2025, or 2026.
- .NET SDK 8.
- Python 3.11+.
- PowerShell.

The C# project uses `net48` for Revit 2024 and `net8.0-windows` for Revit 2025/2026.

## Install The Add-in

From the repository root:

```powershell
.\scripts\install-addin.ps1 -RevitVersion 2026
```

To list detected Revit installs first:

```powershell
.\scripts\find-revit.ps1
```

For a fuller Windows verification pass:

```powershell
.\scripts\verify-windows.ps1 -RevitVersion 2026
```

If Revit is installed in a non-default folder:

```powershell
.\scripts\install-addin.ps1 -RevitVersion 2026 -RevitInstallDir "D:\Apps\Autodesk\Revit 2026"
```

The script builds the add-in and writes:

```text
%APPDATA%\Autodesk\Revit\Addins\2026\RevitMcp.addin
```

The `.addin` points to the compiled DLL in this repo.

## Run The MCP Server

For manual testing:

```powershell
.\scripts\run-server.ps1
```

For ChatGPT through a tunnel, run the MCP server over Streamable HTTP:

```powershell
.\scripts\run-http-server.ps1
```

If dependencies changed or this is the first setup and you want to force reinstall:

```powershell
.\scripts\run-http-server.ps1 -InstallDependencies
```

This exposes MCP locally at:

```text
http://127.0.0.1:8000/mcp
```

Tunnel that HTTP URL, not the Revit WebSocket URL. The Revit add-in still connects locally to `ws://127.0.0.1:8765`.

For development tunnels, this script disables MCP Host header protection so changing ngrok URLs do not require restarting with a new host value. Use `-EnableHostProtection -PublicHost "your-domain"` if you want strict host checking.

Then open or restart Revit. The add-in connects to:

```text
ws://127.0.0.1:8765
```

Add-in logs are written to:

```text
%LOCALAPPDATA%\RevitMcp\addin.log
```

For MCP client configuration, use the Python module command from the virtual environment or install the package and run:

```powershell
python -m revit_mcp.server
```

There is also a starter config at:

```text
config\mcp-client.example.json
```

To print a config using your repo's actual `.venv` path:

```powershell
.\scripts\write-mcp-config.ps1
```

## Test Without Revit

You can validate the Python MCP/WebSocket path before opening Revit.

Terminal 1:

```powershell
.\scripts\run-server.ps1
```

Terminal 2:

```powershell
.\.venv\Scripts\python.exe -m revit_mcp.fake_revit_client
```

Then call `run_revit_code` from your MCP client. The fake client will return the code with a `fake-result:` prefix. This only tests the Python/WebSocket path; Revit API execution still requires the add-in loaded in Revit.

To run the automated Python tests:

```powershell
.\scripts\test-python.ps1
```

## First Code Tests

Important: `run_revit_code` expects only the body of a generated C# method. Do not send `using` directives, namespace/class declarations, or a `Run` method. The add-in already provides:

```csharp
UIApplication app
UIDocument uidoc
Document doc
```

So do this:

```csharp
return doc.Title;
```

Do not redeclare `doc`:

```csharp
Document doc = uidoc.Document; // wrong
```

For larger tasks, split the work into multiple calls. Do not try to create the whole model, rooms, views, sheets, annotations, doors, and windows in one script. Create core geometry first, then hosted elements, then documentation objects.

For version-sensitive API usage, call `get_revit_context()` first and adapt the generated C# to the returned Revit version.

Read active document title:

```csharp
return doc.Title;
```

Count walls:

```csharp
var wallCount = new FilteredElementCollector(doc)
    .OfClass(typeof(Wall))
    .Count();

return wallCount.ToString();
```

List levels:

```csharp
var levels = new FilteredElementCollector(doc)
    .OfClass(typeof(Level))
    .Cast<Level>()
    .Select(level => level.Name);

return string.Join(", ", levels);
```

Modify the model:

```csharp
using (var tx = new Transaction(doc, "Criar parede via MCP"))
{
    tx.Start();

    var level = new FilteredElementCollector(doc)
        .OfClass(typeof(Level))
        .Cast<Level>()
        .First();

    var wallType = new FilteredElementCollector(doc)
        .OfClass(typeof(WallType))
        .Cast<WallType>()
        .First();

    var p1 = new XYZ(0, 0, 0);
    var p2 = new XYZ(10, 0, 0);
    var line = Line.CreateBound(p1, p2);

    Wall.Create(doc, line, wallType.Id, level.Id, 3, 0, false, false);

    tx.Commit();
}

return "Parede criada.";
```

## Optional Token

Set the same token for the MCP process and the Revit process:

```powershell
$env:REVIT_MCP_TOKEN = "local-secret"
```

The add-in reads `REVIT_MCP_TOKEN` from the Revit process environment.

## Uninstall

```powershell
.\scripts\uninstall-addin.ps1 -RevitVersion 2026
```

## Troubleshooting

If Revit does not connect, check:

- The MCP server is running before or after Revit starts. The add-in retries every 2 seconds.
- `%LOCALAPPDATA%\RevitMcp\addin.log`
- `%APPDATA%\Autodesk\Revit\Addins\2026\RevitMcp.addin`
- The `.addin` file points to the built `RevitMcpAddin.dll`.
- `REVIT_MCP_WS_URL` if you changed the default WebSocket URL.
