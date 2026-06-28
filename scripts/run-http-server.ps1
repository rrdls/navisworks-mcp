param(
    [string]$HttpHostAddress = "127.0.0.1",
    [int]$HttpPort = 8000,
    [string]$HttpPath = "/mcp",
    [string]$NavisworksWsHostAddress = "127.0.0.1",
    [int]$NavisworksWsPort = 8765,
    [string]$PublicHost = "",
    [switch]$EnableHostProtection,
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

$env:MCP_TRANSPORT = "streamable-http"
$env:MCP_HTTP_HOST = $HttpHostAddress
$env:MCP_HTTP_PORT = "$HttpPort"
$env:MCP_HTTP_PATH = $HttpPath
if ($EnableHostProtection -and ![string]::IsNullOrWhiteSpace($PublicHost)) {
    $env:MCP_ALLOWED_HOSTS = $PublicHost
    $env:MCP_ALLOWED_ORIGINS = "https://$PublicHost"
}
else {
    $env:MCP_DISABLE_DNS_REBINDING_PROTECTION = "true"
    Remove-Item Env:MCP_ALLOWED_HOSTS -ErrorAction SilentlyContinue
    Remove-Item Env:MCP_ALLOWED_ORIGINS -ErrorAction SilentlyContinue
}

$env:NAVISWORKS_MCP_HOST = $NavisworksWsHostAddress
$env:NAVISWORKS_MCP_PORT = "$NavisworksWsPort"
if (![string]::IsNullOrWhiteSpace($Token)) {
    $env:NAVISWORKS_MCP_TOKEN = $Token
}

Write-Host "Starting MCP HTTP server at http://$HttpHostAddress`:$HttpPort$HttpPath"
Write-Host "Navisworks plugin WebSocket remains ws://$NavisworksWsHostAddress`:$NavisworksWsPort"
& $pythonExe -m navisworks_mcp.server
