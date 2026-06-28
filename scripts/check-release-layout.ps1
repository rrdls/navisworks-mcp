param(
    [string]$PackageRoot = "",
    [switch]$RequireAddin
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($PackageRoot)) {
    $PackageRoot = Join-Path $repoRoot "dist\NavisworksMcp"
}

$requiredFiles = @(
    "app\NavisworksMcpServer.exe",
    "app\NavisworksMcpLauncher.exe"
)

foreach ($relativePath in $requiredFiles) {
    $path = Join-Path $PackageRoot $relativePath
    if (!(Test-Path $path)) {
        throw "Release layout is missing required file: $path"
    }
}

$addinsRoot = Join-Path $PackageRoot "addins"
if (!(Test-Path $addinsRoot)) {
    throw "Release layout is missing addins folder: $addinsRoot"
}

$addinDlls = Get-ChildItem -Path $addinsRoot -Filter "NavisworksMcpAddin.dll" -Recurse -ErrorAction SilentlyContinue
if ($RequireAddin -and $addinDlls.Count -eq 0) {
    throw "Release layout has no packaged Navisworks plugin DLLs under $addinsRoot"
}

$revitArtifacts = Get-ChildItem -Path $PackageRoot -Filter "RevitMcp*" -Recurse -ErrorAction SilentlyContinue
if ($revitArtifacts.Count -gt 0) {
    throw "Release layout contains stale RevitMcp artifacts: $($revitArtifacts[0].FullName)"
}

foreach ($versionDir in Get-ChildItem -Path $addinsRoot -Directory -ErrorAction SilentlyContinue) {
    $packageContents = Join-Path $versionDir.FullName "PackageContents.xml"
    $pluginDll = Join-Path $versionDir.FullName "Contents\NavisworksMcpAddin.dll"
    if (!(Test-Path $packageContents)) {
        throw "Packaged Navisworks plugin is missing PackageContents.xml: $packageContents"
    }
    if (!(Test-Path $pluginDll)) {
        throw "Packaged Navisworks plugin is missing DLL: $pluginDll"
    }
}

Write-Host "Release layout OK:"
Write-Host "  $PackageRoot"
Write-Host "Add-in DLLs found: $($addinDlls.Count)"
