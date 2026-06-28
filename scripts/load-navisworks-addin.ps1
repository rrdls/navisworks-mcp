param(
    [string]$NavisworksInstallDir = "",
    [string]$PluginPath = "",
    [switch]$StartNavisworks,
    [int]$StartupWaitSeconds = 15
)

$ErrorActionPreference = "Stop"

function Find-NavisworksInstallDir {
    $root = "C:\Program Files\Autodesk"
    if (!(Test-Path $root)) {
        throw "Autodesk Program Files folder not found: $root"
    }

    foreach ($filter in @("Navisworks Manage *", "Navisworks Simulate *")) {
        $install = Get-ChildItem -Path $root -Directory -Filter $filter |
            Sort-Object Name -Descending |
            Where-Object { Test-Path (Join-Path $_.FullName "Autodesk.Navisworks.Automation.dll") } |
            Select-Object -First 1

        if ($null -ne $install) {
            return $install.FullName
        }
    }

    throw "No Navisworks Manage/Simulate installation with Autodesk.Navisworks.Automation.dll was found."
}

if ([string]::IsNullOrWhiteSpace($NavisworksInstallDir)) {
    $NavisworksInstallDir = Find-NavisworksInstallDir
}

if ([string]::IsNullOrWhiteSpace($PluginPath)) {
    $PluginPath = Join-Path $NavisworksInstallDir "Plugins\NavisworksMcpAddin.Plugin\NavisworksMcpAddin.Plugin.dll"
}

$automationDll = Join-Path $NavisworksInstallDir "Autodesk.Navisworks.Automation.dll"
$roamerExe = Join-Path $NavisworksInstallDir "Roamer.exe"

if (!(Test-Path $automationDll)) {
    throw "Autodesk.Navisworks.Automation.dll not found: $automationDll"
}
if (!(Test-Path $roamerExe)) {
    throw "Roamer.exe not found: $roamerExe"
}
if (!(Test-Path $PluginPath)) {
    throw "Navisworks MCP plugin not found: $PluginPath"
}

Add-Type -Path $automationDll

$app = [Autodesk.Navisworks.Api.Automation.NavisworksApplication]::TryGetRunningInstance()
if ($null -eq $app -and $StartNavisworks) {
    Write-Host "Starting Navisworks:"
    Write-Host "  $roamerExe"
    Start-Process $roamerExe

    $deadline = (Get-Date).AddSeconds($StartupWaitSeconds)
    do {
        Start-Sleep -Seconds 1
        $app = [Autodesk.Navisworks.Api.Automation.NavisworksApplication]::TryGetRunningInstance()
    } while ($null -eq $app -and (Get-Date) -lt $deadline)
}

if ($null -eq $app) {
    throw "Navisworks is not running. Open Navisworks or pass -StartNavisworks."
}

Write-Host "Loading Navisworks MCP plugin:"
Write-Host "  $PluginPath"
$app.AddPluginAssembly($PluginPath)
Write-Host "Navisworks MCP plugin loaded."
