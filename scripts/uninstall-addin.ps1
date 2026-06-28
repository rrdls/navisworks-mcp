param(
    [string]$NavisworksVersion = "2024",
    [string]$NavisworksInstallDir = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($NavisworksInstallDir)) {
    $NavisworksInstallDir = "C:\Program Files\Autodesk\Navisworks Manage $NavisworksVersion"
}

$paths = @(
    (Join-Path $NavisworksInstallDir "Plugins\NavisworksMcpAddin.Plugin"),
    (Join-Path $NavisworksInstallDir "Plugins\NavisworksMcp"),
    (Join-Path $env:APPDATA "Autodesk\ApplicationPlugins\NavisworksMcp.bundle"),
    (Join-Path $env:ProgramData "Autodesk\ApplicationPlugins\NavisworksMcp.bundle")
)

foreach ($path in $paths) {
    if (Test-Path $path) {
        Remove-Item -Recurse -Force $path
        Write-Host "Removed $path"
    }
    else {
        Write-Host "Not found: $path"
    }
}
