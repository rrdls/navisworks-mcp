param(
    [string]$PackageRoot = "",
    [switch]$RequireAddin,
    [switch]$RequireNgrok
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

if ($RequireNgrok) {
    $requiredFiles += "app\ngrok.exe"
}

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
$probeDlls = Get-ChildItem -Path $addinsRoot -Filter "NavisworksMcpProbe.dll" -Recurse -ErrorAction SilentlyContinue
if ($RequireAddin -and $addinDlls.Count -eq 0) {
    throw "Release layout has no packaged Navisworks plugin DLLs under $addinsRoot"
}
if ($RequireAddin -and $probeDlls.Count -eq 0) {
    throw "Release layout has no packaged Navisworks probe DLLs under $addinsRoot"
}

$revitArtifacts = Get-ChildItem -Path $PackageRoot -Filter "RevitMcp*" -Recurse -ErrorAction SilentlyContinue
if ($revitArtifacts.Count -gt 0) {
    throw "Release layout contains stale RevitMcp artifacts: $($revitArtifacts[0].FullName)"
}

$forbiddenAddinDependencies = @(
    "Microsoft.CodeAnalysis.dll",
    "Microsoft.CodeAnalysis.CSharp.dll",
    "System.Collections.Immutable.dll",
    "System.Reflection.Metadata.dll",
    "System.Runtime.CompilerServices.Unsafe.dll",
    "System.Text.Json.dll"
)
foreach ($fileName in $forbiddenAddinDependencies) {
    $artifact = Get-ChildItem -Path $addinsRoot -Filter $fileName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $artifact) {
        throw "Release layout contains forbidden Navisworks addin dependency '$fileName': $($artifact.FullName)"
    }
}

foreach ($versionDir in Get-ChildItem -Path $addinsRoot -Directory -ErrorAction SilentlyContinue) {
    $packageContents = Join-Path $versionDir.FullName "PackageContents.xml"
    $pluginDll = Join-Path $versionDir.FullName "Contents\NavisworksMcpAddin.dll"
    $probeDll = Join-Path $versionDir.FullName "Contents\NavisworksMcpProbe.dll"
    if (!(Test-Path $packageContents)) {
        throw "Packaged Navisworks plugin is missing PackageContents.xml: $packageContents"
    }
    if (!(Test-Path $pluginDll)) {
        throw "Packaged Navisworks plugin is missing DLL: $pluginDll"
    }
    if (!(Test-Path $probeDll)) {
        throw "Packaged Navisworks probe is missing DLL: $probeDll"
    }
}

Write-Host "Release layout OK:"
Write-Host "  $PackageRoot"
Write-Host "Add-in DLLs found: $($addinDlls.Count)"
Write-Host "Probe DLLs found: $($probeDlls.Count)"
