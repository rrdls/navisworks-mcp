param(
    [string]$BundleName = "NavisworksMcp.bundle"
)

$ErrorActionPreference = "Stop"

$bundlePath = Join-Path $env:APPDATA "Autodesk\ApplicationPlugins\$BundleName"
if (Test-Path $bundlePath) {
    Remove-Item -Recurse -Force $bundlePath
    Write-Host "Removed $bundlePath"
}
else {
    Write-Host "Plugin bundle not found: $bundlePath"
}
