# Navisworks MCP

Navisworks MCP lets ChatGPT or another MCP client execute focused C# snippets inside Autodesk Navisworks.

The local architecture is:

```text
ChatGPT / MCP client
  -> local MCP server
  -> localhost WebSocket
  -> Navisworks plugin
  -> Roslyn C# runtime
  -> Navisworks .NET API
```

The project is local-first. There is no hosted backend required.

## Current Status

This repository was migrated from the Revit MCP project. The Python MCP server, WebSocket bridge, in-product controls, fixed ngrok public URL flow, and packaging structure have been adapted to Navisworks.

The first supported workflow is:

1. Open Navisworks.
2. Open the native `Tool add-ins` tab.
3. Run the `Start MCP` command.
4. Copy the local MCP URL from `Copy Local URL`.
5. Execute small C# snippets against the active Navisworks document.

Navisworks MCP does not create a custom ribbon tab. The commands are exposed through the native Navisworks
`Tool add-ins` tab, matching the standard `AddInPlugin` loading pattern used by Navisworks plugins.

Navisworks is primarily a coordination/review environment. Do not expect Revit-style BIM authoring operations such as creating native walls, doors, families, or levels.

## MCP Tools

```text
run_navisworks_code(code: string, timeout_seconds: number = 60) -> string
get_navisworks_mcp_prompt() -> string
get_navisworks_context(timeout_seconds: number = 30) -> string
```

`run_navisworks_code` expects only the body of a generated C# method. Do not send `using` directives, namespace/class declarations, or a `Run` method.

The runtime already provides:

```csharp
Document doc
```

Common namespaces are already imported:

```csharp
Autodesk.Navisworks.Api
System
System.Linq
System.Collections.Generic
```

Correct:

```csharp
return doc.Title;
```

Wrong:

```csharp
using Autodesk.Navisworks.Api;
Document doc = Autodesk.Navisworks.Api.Application.ActiveDocument;
```

For version-sensitive API usage, call `get_navisworks_context()` first and adapt generated code to the returned Navisworks version/context.

## Developer Setup

Requirements:

- Windows
- Autodesk Navisworks Manage or Simulate
- .NET SDK
- Python 3.11+
- PowerShell

Detect Navisworks:

```powershell
.\scripts\find-navisworks.ps1
```

Build and install the plugin:

```powershell
.\scripts\install-addin.ps1 -NavisworksVersion 2026 -NavisworksInstallDir "C:\Program Files\Autodesk\Navisworks Manage 2026"
```

This creates:

```text
C:\Program Files\Autodesk\Navisworks Manage <version>\Plugins\NavisworksMcpAddin.Plugin\NavisworksMcpAddin.Plugin.dll
C:\Program Files\Autodesk\Navisworks Manage <version>\Plugins\NavisworksMcpAddin.Plugin\NavisworksMcpProbe.Plugin.dll
```

Start MCP over HTTP for development:

```powershell
.\scripts\run-http-server.ps1
```

This starts:

```text
http://127.0.0.1:8000/mcp
```

The Navisworks plugin connects locally to:

```text
ws://127.0.0.1:8765
```

The packaged plugin exposes Navisworks MCP commands inside Navisworks:

```text
Start MCP
Stop MCP
Start Public URL
Stop Public URL
Copy Local URL
Copy Public URL
MCP Status
MCP Settings
Open MCP Logs
```

These commands appear in the native Navisworks `Tool add-ins` tab.

The local URL used by the packaged app includes a generated auth token:

```text
http://127.0.0.1:8000/<token>/mcp
```

Navisworks plugin loading can be diagnosed with:

```powershell
.\scripts\diagnose-installed-plugin.ps1 -NavisworksVersion 2026 -RequireRuntime
```

For development-only manual loading, the loader script remains available:

```powershell
.\scripts\load-navisworks-addin.ps1 -NavisworksInstallDir "C:\Program Files\Autodesk\Navisworks Manage 2026" -StartNavisworks
```

To test the Python/WebSocket path without Navisworks:

Terminal 1:

```powershell
.\scripts\run-server.ps1
```

Terminal 2:

```powershell
.\.venv\Scripts\python.exe -m navisworks_mcp.fake_navisworks_client
```

Run local Python tests:

```powershell
.\scripts\test-python.ps1
```

## Packaging

Build Python executables:

```powershell
.\scripts\build-server-exe.ps1
```

Outputs:

```text
dist\NavisworksMcp\app\NavisworksMcpServer.exe
dist\NavisworksMcp\app\NavisworksMcpLauncher.exe
```

Package available Navisworks plugin builds:

```powershell
.\scripts\package-addins.ps1
```

Build a release layout:

```powershell
.\scripts\package-release.ps1
```

The installer script is:

```text
installer\NavisworksMcp.iss
```

## Troubleshooting

Logs are written to:

```text
%LOCALAPPDATA%\NavisworksMcp\addin.log
%LOCALAPPDATA%\NavisworksMcp\probe.log
```

If Navisworks does not connect:

- Confirm the buttons are under the native `Tool add-ins` tab; no custom `Navisworks MCP` tab is expected.
- Open Navisworks and run `Start MCP` from `Tool add-ins`.
- Use `MCP Status` to confirm the local URL and process state.
- Use `Open MCP Logs` to inspect `%LOCALAPPDATA%\NavisworksMcp`.
- Confirm port `8765` is free.
- Check `probe.log` first. If it exists, Navisworks loaded the minimal MCP probe and discovery is working.
- Check `addin.log` next. If `probe.log` exists but `addin.log` does not, the full MCP addin is failing before startup.
- Run `.\scripts\diagnose-installed-plugin.ps1 -NavisworksVersion 2026 -RequireRuntime` after opening Navisworks.

If snippets fail to compile:

- Send only the method body.
- Do not include `using` statements.
- Do not redeclare `doc`.
- Keep snippets small.
- Call `get_navisworks_context()` before using version-sensitive API calls.

## Security

This project executes generated C# inside Navisworks. Treat it like a local automation console.

- Only connect trusted MCP clients.
- Keep the generated MCP auth token private; it is part of the local/public MCP URL.
- Review destructive operations before running them.
- Prefer read-only inspection unless a document change is explicitly requested.
