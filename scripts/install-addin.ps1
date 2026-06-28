param(
    [string]$NavisworksVersion = "2026",
    [string]$Configuration = "Debug",
    [string]$ProjectPath = "",
    [string]$NavisworksInstallDir = "",
    [string]$TargetFramework = "net48"
)

$ErrorActionPreference = "Stop"

if (Get-Process Roamer -ErrorAction SilentlyContinue) {
    throw "Close Navisworks before installing the Navisworks MCP add-in. The plugin DLLs cannot be replaced while Roamer.exe is running."
}

$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
    $ProjectPath = Join-Path $repoRoot "addin\NavisworksMcpAddin\NavisworksMcpAddin.csproj"
}
$probeProjectPath = Join-Path $repoRoot "addin\NavisworksMcpProbe\NavisworksMcpProbe.csproj"

if ([string]::IsNullOrWhiteSpace($NavisworksInstallDir)) {
    $NavisworksInstallDir = "C:\Program Files\Autodesk\Navisworks Manage $NavisworksVersion"
}

if (!(Test-Path $ProjectPath)) {
    throw "Project not found: $ProjectPath"
}

if (!(Test-Path (Join-Path $NavisworksInstallDir "Autodesk.Navisworks.Api.dll"))) {
    throw "Autodesk.Navisworks.Api.dll not found in '$NavisworksInstallDir'. Pass -NavisworksInstallDir if Navisworks is installed elsewhere."
}

$projectDir = Split-Path -Parent $ProjectPath
$buildDir = Join-Path $projectDir "bin\$Configuration\$TargetFramework"
$probeBuildDir = Join-Path $repoRoot "addin\NavisworksMcpProbe\bin\$Configuration\$TargetFramework"
if (Test-Path $buildDir) {
    Remove-Item -Recurse -Force $buildDir
}
if (Test-Path $probeBuildDir) {
    Remove-Item -Recurse -Force $probeBuildDir
}

dotnet restore $ProjectPath -p:NavisworksVersion=$NavisworksVersion -p:NavisworksInstallDir="$NavisworksInstallDir" -p:TargetFramework=$TargetFramework
dotnet build $ProjectPath -c $Configuration -f $TargetFramework -p:NavisworksVersion=$NavisworksVersion -p:NavisworksInstallDir="$NavisworksInstallDir" --no-restore
dotnet restore $probeProjectPath -p:NavisworksVersion=$NavisworksVersion -p:NavisworksInstallDir="$NavisworksInstallDir" -p:TargetFramework=$TargetFramework
dotnet build $probeProjectPath -c $Configuration -f $TargetFramework -p:NavisworksVersion=$NavisworksVersion -p:NavisworksInstallDir="$NavisworksInstallDir" --no-restore

$assemblyPath = Join-Path $buildDir "NavisworksMcpAddin.Plugin.dll"
if (!(Test-Path $assemblyPath)) {
    throw "Built assembly not found: $assemblyPath"
}
$probeAssemblyPath = Join-Path $probeBuildDir "NavisworksMcpProbe.Plugin.dll"
if (!(Test-Path $probeAssemblyPath)) {
    throw "Built probe assembly not found: $probeAssemblyPath"
}
if (Get-ChildItem -Path $buildDir -Filter "RevitMcp*" -Recurse -ErrorAction SilentlyContinue) {
    throw "Build output contains stale RevitMcp artifacts. Remove bin/obj and rebuild."
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
    $artifact = Get-ChildItem -Path $buildDir -Filter $fileName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $artifact) {
        throw "Build output contains forbidden Navisworks addin dependency '$fileName': $($artifact.FullName)"
    }
}

function Remove-StalePluginFiles {
    param([string]$Dir)

    @(
        "NavisworksMcpAddin.dll",
        "NavisworksMcpAddin.pdb",
        "NavisworksMcpProbe.dll",
        "NavisworksMcpProbe.pdb",
        "NavisworksMcpRibbon.xaml",
        "NavisworksMcp.Plugin.dll",
        "Microsoft.CodeAnalysis.dll",
        "Microsoft.CodeAnalysis.CSharp.dll",
        "System.Collections.Immutable.dll",
        "System.Reflection.Metadata.dll",
        "System.Runtime.CompilerServices.Unsafe.dll",
        "System.Text.Json.dll"
    ) | ForEach-Object {
        Remove-Item (Join-Path $Dir $_) -Force -ErrorAction SilentlyContinue
    }
}

function Remove-StaleFlatPluginFiles {
    param([string]$Dir)

    Remove-StalePluginFiles $Dir
    @(
        "NavisworksMcpAddin.Plugin.dll",
        "NavisworksMcpAddin.Plugin.pdb",
        "NavisworksMcpProbe.Plugin.dll",
        "NavisworksMcpProbe.Plugin.pdb",
        "Microsoft.Bcl.AsyncInterfaces.dll",
        "System.Buffers.dll",
        "System.Memory.dll",
        "System.Numerics.Vectors.dll",
        "System.Text.Encoding.CodePages.dll",
        "System.Text.Encodings.Web.dll",
        "System.Threading.Tasks.Extensions.dll",
        "System.ValueTuple.dll"
    ) | ForEach-Object {
        Remove-Item (Join-Path $Dir $_) -Force -ErrorAction SilentlyContinue
    }
}

function Assert-CleanPluginDir {
    param([string]$Dir)

    @(
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
    ) | ForEach-Object {
        $staleFile = Join-Path $Dir $_
        if (Test-Path $staleFile) {
            throw "Installed plugin folder contains stale or forbidden file: $staleFile"
        }
    }
}

$bundleRoot = Join-Path $env:APPDATA "Autodesk\ApplicationPlugins\NavisworksMcp.bundle"
$programDataBundleRoot = Join-Path $env:ProgramData "Autodesk\ApplicationPlugins\NavisworksMcp.bundle"
Remove-Item -Recurse -Force $bundleRoot, $programDataBundleRoot -ErrorAction SilentlyContinue

$oldProductPluginDir = Join-Path $NavisworksInstallDir "Plugins\NavisworksMcp"
$productPluginDir = Join-Path $NavisworksInstallDir "Plugins\NavisworksMcpAddin.Plugin"
try {
    Remove-Item -Recurse -Force $oldProductPluginDir -ErrorAction SilentlyContinue
    if (Test-Path $productPluginDir) {
        Remove-Item -Recurse -Force $productPluginDir
    }
    New-Item -ItemType Directory -Force -Path $productPluginDir | Out-Null
    Copy-Item -Path (Join-Path $buildDir "*") -Destination $productPluginDir -Recurse -Force
    Copy-Item -Path $probeAssemblyPath -Destination $productPluginDir -Force
    Copy-Item -Path (Join-Path $probeBuildDir "NavisworksMcpProbe.Plugin.pdb") -Destination $productPluginDir -Force -ErrorAction SilentlyContinue
    Remove-StalePluginFiles $productPluginDir
    Assert-CleanPluginDir $productPluginDir

    $productPluginsRoot = Join-Path $NavisworksInstallDir "Plugins"
    Remove-StaleFlatPluginFiles $productPluginsRoot

    Remove-Item (Join-Path $NavisworksInstallDir "NavisworksMcp.Plugin.dll") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $NavisworksInstallDir "NavisworksMcpAddin.Plugin.dll") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $NavisworksInstallDir "NavisworksMcpProbe.Plugin.dll") -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Warning "Could not install to the Navisworks product Plugins folder. Run PowerShell as Administrator if needed. $($_.Exception.Message)"
}

Write-Host "Product plugin folder:"
Write-Host "  $productPluginDir"
Write-Host "Assembly:"
Write-Host "  $(Join-Path $productPluginDir 'NavisworksMcpAddin.Plugin.dll')"
Write-Host "Target framework:"
Write-Host "  $TargetFramework"
Write-Host ""
Write-Host "Next:"
Write-Host "  1. Open or restart Navisworks $NavisworksVersion."
Write-Host "  2. Open the native Tool add-ins tab."
Write-Host "  3. Click Start MCP."
Write-Host "  4. Verify with:"
Write-Host "     .\scripts\test-navisworks-context.ps1"
