param(
    [string]$HostAddress = "127.0.0.1",
    [int]$Port = 8765,
    [switch]$InstallDependencies,
    [string]$Token = ""
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

$env:NAVISWORKS_MCP_HOST = $HostAddress
$env:NAVISWORKS_MCP_PORT = "$Port"
if (![string]::IsNullOrWhiteSpace($Token)) {
    $env:NAVISWORKS_MCP_TOKEN = $Token
}

Write-Host "Starting Navisworks MCP server on ws://$HostAddress`:$Port"
Write-Host "This process also speaks MCP over stdio when launched by an MCP client."
& $pythonExe -m navisworks_mcp.server
