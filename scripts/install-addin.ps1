param(
    [string]$NavisworksVersion = "2026",
    [string]$Configuration = "Debug",
    [string]$ProjectPath = "",
    [string]$NavisworksInstallDir = "",
    [string]$TargetFramework = "net48"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
    $ProjectPath = Join-Path $repoRoot "addin\NavisworksMcpAddin\NavisworksMcpAddin.csproj"
}

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
if (Test-Path $buildDir) {
    Remove-Item -Recurse -Force $buildDir
}

dotnet restore $ProjectPath -p:NavisworksVersion=$NavisworksVersion -p:NavisworksInstallDir="$NavisworksInstallDir" -p:TargetFramework=$TargetFramework
dotnet build $ProjectPath -c $Configuration -f $TargetFramework -p:NavisworksVersion=$NavisworksVersion -p:NavisworksInstallDir="$NavisworksInstallDir" --no-restore

$assemblyPath = Join-Path $buildDir "NavisworksMcpAddin.dll"
if (!(Test-Path $assemblyPath)) {
    throw "Built assembly not found: $assemblyPath"
}
if (Get-ChildItem -Path $buildDir -Filter "RevitMcp*" -Recurse -ErrorAction SilentlyContinue) {
    throw "Build output contains stale RevitMcp artifacts. Remove bin/obj and rebuild."
}

$bundleRoot = Join-Path $env:APPDATA "Autodesk\ApplicationPlugins\NavisworksMcp.bundle"
$contentsDir = Join-Path $bundleRoot "Contents"
if (Test-Path $bundleRoot) {
    Remove-Item -Recurse -Force $bundleRoot
}
New-Item -ItemType Directory -Force -Path $contentsDir | Out-Null

Copy-Item -Path (Join-Path $buildDir "*") -Destination $contentsDir -Recurse -Force
$templatePath = Join-Path $projectDir "PackageContents.xml.template"
$packageContentsPath = Join-Path $bundleRoot "PackageContents.xml"
(Get-Content $templatePath -Raw).Replace("{NAVISWORKS_VERSION}", $NavisworksVersion) | Set-Content -Encoding UTF8 $packageContentsPath

if (!(Test-Path (Join-Path $contentsDir "NavisworksMcpAddin.dll"))) {
    throw "Installed bundle is missing NavisworksMcpAddin.dll."
}
if (Get-ChildItem -Path $contentsDir -Filter "RevitMcp*" -Recurse -ErrorAction SilentlyContinue) {
    throw "Installed bundle contains stale RevitMcp artifacts."
}

$programDataBundleRoot = Join-Path $env:ProgramData "Autodesk\ApplicationPlugins\NavisworksMcp.bundle"
$programDataContentsDir = Join-Path $programDataBundleRoot "Contents"
try {
    if (Test-Path $programDataBundleRoot) {
        Remove-Item -Recurse -Force $programDataBundleRoot
    }
    New-Item -ItemType Directory -Force -Path $programDataContentsDir | Out-Null
    Copy-Item -Path (Join-Path $buildDir "*") -Destination $programDataContentsDir -Recurse -Force
    (Get-Content $templatePath -Raw).Replace("{NAVISWORKS_VERSION}", $NavisworksVersion) | Set-Content -Encoding UTF8 (Join-Path $programDataBundleRoot "PackageContents.xml")
}
catch {
    Write-Warning "Could not install machine-wide ApplicationPlugins bundle. Run PowerShell as Administrator if needed. $($_.Exception.Message)"
}

$productPluginDir = Join-Path $NavisworksInstallDir "Plugins\NavisworksMcp"
try {
    if (Test-Path $productPluginDir) {
        Remove-Item -Recurse -Force $productPluginDir
    }
    New-Item -ItemType Directory -Force -Path $productPluginDir | Out-Null
    Copy-Item -Path (Join-Path $buildDir "*") -Destination $productPluginDir -Recurse -Force
}
catch {
    Write-Warning "Could not install to the Navisworks product Plugins folder. Run PowerShell as Administrator if needed. $($_.Exception.Message)"
}

Write-Host "Installed Navisworks MCP plugin bundle:"
Write-Host "  $bundleRoot"
Write-Host "Machine-wide bundle:"
Write-Host "  $programDataBundleRoot"
Write-Host "Product plugin folder:"
Write-Host "  $productPluginDir"
Write-Host "Assembly:"
Write-Host "  $(Join-Path $contentsDir 'NavisworksMcpAddin.dll')"
Write-Host "Target framework:"
Write-Host "  $TargetFramework"
Write-Host ""
Write-Host "Next:"
Write-Host "  1. Start the MCP server."
Write-Host "  2. Open or restart Navisworks $NavisworksVersion."
Write-Host "  3. The Navisworks MCP plugin connects automatically."
