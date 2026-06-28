param(
    [string]$OutputPath = "",
    [string]$HostAddress = "127.0.0.1",
    [int]$Port = 8765
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pythonExe = Join-Path $repoRoot ".venv\Scripts\python.exe"

if (!(Test-Path $pythonExe)) {
    throw "Virtual environment not found. Run .\scripts\run-server.ps1 once first, or create .venv manually."
}

$config = [ordered]@{
    mcpServers = [ordered]@{
        "navisworks-mcp" = [ordered]@{
            command = $pythonExe
            args = @("-m", "navisworks_mcp.server")
            env = [ordered]@{
                NAVISWORKS_MCP_HOST = $HostAddress
                NAVISWORKS_MCP_PORT = "$Port"
            }
        }
    }
}

$json = $config | ConvertTo-Json -Depth 10

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    Write-Output $json
}
else {
    $directory = Split-Path -Parent $OutputPath
    if (![string]::IsNullOrWhiteSpace($directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }

    $json | Set-Content -Encoding UTF8 $OutputPath
    Write-Host "Wrote MCP config to $OutputPath"
}
