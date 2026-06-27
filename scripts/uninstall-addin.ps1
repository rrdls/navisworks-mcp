param(
    [string]$RevitVersion = "2026"
)

$ErrorActionPreference = "Stop"

$addinPath = Join-Path $env:APPDATA "Autodesk\Revit\Addins\$RevitVersion\RevitMcp.addin"
if (Test-Path $addinPath) {
    Remove-Item $addinPath
    Write-Host "Removed $addinPath"
}
else {
    Write-Host "Add-in file not found: $addinPath"
}

