param(
    [string[]]$NavisworksVersions = @("2021", "2022", "2023", "2024", "2025", "2026"),
    [string]$Configuration = "Release",
    [string]$OutputRoot = "",
    [string]$TargetFramework = "net48"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $repoRoot "addin\NavisworksMcpAddin\NavisworksMcpAddin.csproj"
$probeProjectPath = Join-Path $repoRoot "addin\NavisworksMcpProbe\NavisworksMcpProbe.csproj"
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $repoRoot "dist\NavisworksMcp\addins"
}

foreach ($version in $NavisworksVersions) {
    $navisworksInstallDir = "C:\Program Files\Autodesk\Navisworks Manage $version"
    if (!(Test-Path (Join-Path $navisworksInstallDir "Autodesk.Navisworks.Api.dll"))) {
        $simulateInstallDir = "C:\Program Files\Autodesk\Navisworks Simulate $version"
        if (Test-Path (Join-Path $simulateInstallDir "Autodesk.Navisworks.Api.dll")) {
            $navisworksInstallDir = $simulateInstallDir
        }
    }
    if (!(Test-Path (Join-Path $navisworksInstallDir "Autodesk.Navisworks.Api.dll"))) {
        Write-Warning "Skipping Navisworks $version because Autodesk.Navisworks.Api.dll was not found under the default Manage/Simulate install paths"
        continue
    }

    $sourceDir = Join-Path $repoRoot "addin\NavisworksMcpAddin\bin\$Configuration\$TargetFramework"
    $probeSourceDir = Join-Path $repoRoot "addin\NavisworksMcpProbe\bin\$Configuration\$TargetFramework"
    if (Test-Path $sourceDir) {
        Remove-Item -Recurse -Force $sourceDir
    }
    if (Test-Path $probeSourceDir) {
        Remove-Item -Recurse -Force $probeSourceDir
    }

    dotnet restore $projectPath -p:NavisworksVersion=$version -p:NavisworksInstallDir="$navisworksInstallDir" -p:TargetFramework=$TargetFramework
    dotnet build $projectPath -c $Configuration -f $TargetFramework -p:NavisworksVersion=$version -p:NavisworksInstallDir="$navisworksInstallDir" --no-restore
    dotnet restore $probeProjectPath -p:NavisworksVersion=$version -p:NavisworksInstallDir="$navisworksInstallDir" -p:TargetFramework=$TargetFramework
    dotnet build $probeProjectPath -c $Configuration -f $TargetFramework -p:NavisworksVersion=$version -p:NavisworksInstallDir="$navisworksInstallDir" --no-restore

    if (!(Test-Path (Join-Path $sourceDir "NavisworksMcpAddin.dll"))) {
        throw "Build output is missing NavisworksMcpAddin.dll: $sourceDir"
    }
    if (!(Test-Path (Join-Path $probeSourceDir "NavisworksMcpProbe.dll"))) {
        throw "Build output is missing NavisworksMcpProbe.dll: $probeSourceDir"
    }
    if (Get-ChildItem -Path $sourceDir -Filter "RevitMcp*" -Recurse -ErrorAction SilentlyContinue) {
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
        $artifact = Get-ChildItem -Path $sourceDir -Filter $fileName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $artifact) {
            throw "Build output contains forbidden Navisworks addin dependency '$fileName': $($artifact.FullName)"
        }
    }

    $targetDir = Join-Path $OutputRoot $version
    $contentsDir = Join-Path $targetDir "Contents"
    if (Test-Path $targetDir) {
        Remove-Item -Recurse -Force $targetDir
    }
    New-Item -ItemType Directory -Force -Path $contentsDir | Out-Null
    Copy-Item -Path (Join-Path $sourceDir "*") -Destination $contentsDir -Recurse -Force
    Copy-Item -Path (Join-Path $probeSourceDir "NavisworksMcpProbe.dll") -Destination $contentsDir -Force
    Copy-Item -Path (Join-Path $probeSourceDir "NavisworksMcpProbe.pdb") -Destination $contentsDir -Force -ErrorAction SilentlyContinue
    (Get-Content (Join-Path $repoRoot "addin\NavisworksMcpAddin\PackageContents.xml.template") -Raw).
        Replace("{NAVISWORKS_VERSION}", $version) |
        Set-Content -Encoding UTF8 (Join-Path $targetDir "PackageContents.xml")

    Write-Host "Packaged Navisworks $version plugin:"
    Write-Host "  $targetDir"
}
