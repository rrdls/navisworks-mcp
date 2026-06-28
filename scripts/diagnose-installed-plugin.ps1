param(
    [string]$NavisworksVersion = "2024",
    [string]$NavisworksInstallDir = "",
    [switch]$RequireRuntime
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($NavisworksInstallDir)) {
    $NavisworksInstallDir = "C:\Program Files\Autodesk\Navisworks Manage $NavisworksVersion"
}

$roots = @(
    (Join-Path $NavisworksInstallDir "Plugins\NavisworksMcpAddin.Plugin")
)

$obsoleteRoots = @(
    (Join-Path $env:APPDATA "Autodesk\ApplicationPlugins\NavisworksMcp.bundle"),
    (Join-Path $env:ProgramData "Autodesk\ApplicationPlugins\NavisworksMcp.bundle"),
    (Join-Path $NavisworksInstallDir "Plugins\NavisworksMcp")
)

$expectedFiles = @(
    "NavisworksMcpAddin.Plugin.dll",
    "NavisworksMcpProbe.Plugin.dll"
)

$forbiddenFiles = @(
    "NavisworksMcpAddin.dll",
    "NavisworksMcpProbe.dll",
    "NavisworksMcpRibbon.xaml",
    "NavisworksMcp.Plugin.dll",
    "Microsoft.CodeAnalysis.dll",
    "Microsoft.CodeAnalysis.CSharp.dll",
    "System.Collections.Immutable.dll",
    "System.Reflection.Metadata.dll",
    "System.Runtime.CompilerServices.Unsafe.dll",
    "System.Text.Json.dll"
)

Write-Host "Navisworks MCP installation diagnostic"
Write-Host "Navisworks install:"
Write-Host "  $NavisworksInstallDir"
Write-Host ""

$roamer = Get-Process Roamer -ErrorAction SilentlyContinue
if ($roamer) {
    Write-Host "Roamer.exe is running:"
    $roamer | Select-Object Id, ProcessName, Path | Format-Table -AutoSize
}
else {
    Write-Host "Roamer.exe is not running."
}
Write-Host ""

$hasProblem = $false
foreach ($root in $roots) {
    Write-Host "Checking:"
    Write-Host "  $root"
    if (!(Test-Path $root)) {
        Write-Host "  MISSING"
        $hasProblem = $true
        Write-Host ""
        continue
    }

    foreach ($fileName in $expectedFiles) {
        $path = Join-Path $root $fileName
        if (Test-Path $path) {
            $file = Get-Item $path
            Write-Host ("  OK      {0} ({1} bytes, {2})" -f $file.Name, $file.Length, $file.LastWriteTime)
        }
        else {
            Write-Host "  MISSING $fileName"
            $hasProblem = $true
        }
    }

    foreach ($fileName in $forbiddenFiles) {
        $path = Join-Path $root $fileName
        if (Test-Path $path) {
            $file = Get-Item $path
            Write-Host ("  STALE   {0} ({1} bytes, {2})" -f $file.Name, $file.Length, $file.LastWriteTime)
            $hasProblem = $true
        }
    }

    Write-Host ""
}

Write-Host "Checking obsolete install locations:"
foreach ($root in $obsoleteRoots) {
    if (Test-Path $root) {
        Write-Host "  STALE   $root"
        $hasProblem = $true
    }
    else {
        Write-Host "  OK      $root"
    }
}
Write-Host ""

$addinLog = Join-Path $env:LOCALAPPDATA "NavisworksMcp\addin.log"
$autoloaderLog = Join-Path $env:LOCALAPPDATA "NavisworksMcp\autoloader.log"
$hasRuntimeProblem = $false

Write-Host "Add-in log:"
Write-Host "  $addinLog"
if (Test-Path $addinLog) {
    $tail = Get-Content $addinLog -Tail 220
    $tail
    Write-Host ""

    foreach ($requiredPattern in @(
        "Navisworks MCP event watcher OnLoaded reached.",
        "Navisworks MCP Tool add-ins commands registered:",
        "Start MCP",
        "Stop MCP",
        "MCP Status",
        "MCP Settings"
    )) {
        if ($tail -match [regex]::Escape($requiredPattern)) {
            Write-Host "  LOG OK      $requiredPattern"
        }
        else {
            Write-Host "  LOG MISSING $requiredPattern"
            $hasRuntimeProblem = $true
        }
    }
}
else {
    Write-Host "  MISSING (runtime not observed yet; open Navisworks and run this diagnostic again)"
    $hasRuntimeProblem = $true
}
Write-Host ""

Write-Host "Autoloader log:"
Write-Host "  $autoloaderLog"
if (Test-Path $autoloaderLog) {
    Get-Content $autoloaderLog -Tail 120
    Write-Host "  NOTE: autoloader is no longer required by the normal installer flow."
}
else {
    Write-Host "  MISSING (expected unless the manual autoloader script was run)"
}

if ($hasProblem -or ($RequireRuntime -and $hasRuntimeProblem)) {
    Write-Host ""
    throw "Navisworks MCP installation diagnostic found problems."
}

Write-Host ""
if ($hasRuntimeProblem) {
    Write-Host "Navisworks MCP installation files are clean. Runtime diagnostics are incomplete; open Navisworks and run again with -RequireRuntime."
}
else {
    Write-Host "Navisworks MCP installation and runtime diagnostic OK."
}
