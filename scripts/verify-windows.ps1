param(
    [string]$NavisworksVersion = "2026",
    [string]$Configuration = "Debug",
    [string]$NavisworksInstallDir = "",
    [string]$TargetFramework = "net48"
)

$ErrorActionPreference = "Stop"

Write-Host "== Python tests =="
& (Join-Path $PSScriptRoot "test-python.ps1")

Write-Host ""
Write-Host "== Build and install Navisworks plugin =="
$installArgs = @{
    NavisworksVersion = $NavisworksVersion
    Configuration = $Configuration
    TargetFramework = $TargetFramework
}
if (![string]::IsNullOrWhiteSpace($NavisworksInstallDir)) {
    $installArgs.NavisworksInstallDir = $NavisworksInstallDir
}
& (Join-Path $PSScriptRoot "install-addin.ps1") @installArgs

Write-Host ""
Write-Host "== MCP client config =="
& (Join-Path $PSScriptRoot "write-mcp-config.ps1")

Write-Host ""
Write-Host "Verification completed. Open or restart Navisworks $NavisworksVersion, use Tool add-ins > Start MCP, then test run_navisworks_code with: return doc.Title;"
