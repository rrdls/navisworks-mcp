param(
    [string]$McpUrl = "",
    [switch]$InstallDependencies
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pythonDir = Join-Path $repoRoot "python"
$venvDir = Join-Path $repoRoot ".venv"

if (!(Test-Path $venvDir)) {
    python -m venv $venvDir
    $InstallDependencies = $true
}

$pythonExe = Join-Path $venvDir "Scripts\python.exe"
if ($InstallDependencies) {
    & $pythonExe -m pip install --upgrade pip
    & $pythonExe -m pip install -e $pythonDir
}

Get-ChildItem -Path $venvDir -Recurse -Force -Filter "*:Zone.Identifier" -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

if ([string]::IsNullOrWhiteSpace($McpUrl)) {
    $settingsPath = Join-Path $env:LOCALAPPDATA "NavisworksMcp\settings.json"
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        if ($settings.McpAuthToken) {
            $McpUrl = "http://127.0.0.1:8000/$($settings.McpAuthToken)/mcp"
        }
    }
}

if ([string]::IsNullOrWhiteSpace($McpUrl)) {
    $McpUrl = "http://127.0.0.1:8000/mcp"
}

$clientScript = @'
import asyncio
import sys

from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client


async def main() -> None:
    url = sys.argv[1]
    async with streamablehttp_client(url) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            result = await session.call_tool("get_navisworks_context", {})
            for item in result.content:
                text = getattr(item, "text", None)
                if text is not None:
                    print(text)
                else:
                    print(item)


asyncio.run(main())
'@

$tempScript = Join-Path $env:TEMP "navisworks_mcp_context_client.py"
Set-Content -Encoding UTF8 -Path $tempScript -Value $clientScript
try {
    & $pythonExe $tempScript $McpUrl
}
finally {
    Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
}
