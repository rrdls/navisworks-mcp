param(
    [string]$RevitVersion = "2026",
    [string]$Configuration = "Debug",
    [string]$RevitInstallDir = "",
    [string]$TargetFramework = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot

Write-Host "== Python tests =="
& (Join-Path $PSScriptRoot "test-python.ps1")

Write-Host ""
Write-Host "== Build and install Revit add-in =="
$installArgs = @{
    RevitVersion = $RevitVersion
    Configuration = $Configuration
}
if (![string]::IsNullOrWhiteSpace($RevitInstallDir)) {
    $installArgs.RevitInstallDir = $RevitInstallDir
}
if (![string]::IsNullOrWhiteSpace($TargetFramework)) {
    $installArgs.TargetFramework = $TargetFramework
}
& (Join-Path $PSScriptRoot "install-addin.ps1") @installArgs

Write-Host ""
Write-Host "== MCP client config =="
& (Join-Path $PSScriptRoot "write-mcp-config.ps1")

Write-Host ""
Write-Host "Verification completed. Open or restart Revit $RevitVersion and test run_revit_code with: return doc.Title;"
