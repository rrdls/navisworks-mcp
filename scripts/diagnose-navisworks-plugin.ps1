param(
    [string]$NavisworksInstallDir = "C:\Program Files\Autodesk\Navisworks Manage 2024",
    [string]$PluginPath = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($PluginPath)) {
    $userBundleProbePath = Join-Path $env:APPDATA "Autodesk\ApplicationPlugins\NavisworksMcp.bundle\Contents\NavisworksMcpProbe.Plugin.dll"
    if (Test-Path $userBundleProbePath) {
        $PluginPath = $userBundleProbePath
    }
    else {
        $PluginPath = Join-Path $NavisworksInstallDir "Plugins\NavisworksMcpProbe.Plugin.dll"
    }
}

$automationDll = Join-Path $NavisworksInstallDir "Autodesk.Navisworks.Automation.dll"
if (!(Test-Path $automationDll)) {
    throw "Autodesk.Navisworks.Automation.dll not found: $automationDll"
}
if (!(Test-Path $PluginPath)) {
    throw "Plugin DLL not found: $PluginPath"
}

Write-Host "Navisworks install:"
Write-Host "  $NavisworksInstallDir"
Write-Host "Probe DLL:"
Write-Host "  $PluginPath"

Add-Type -Path $automationDll

$app = [Autodesk.Navisworks.Api.Automation.NavisworksApplication]::TryGetRunningInstance()
if ($null -eq $app) {
    Write-Host "No running Navisworks instance found. Starting Roamer.exe..."
    $roamer = Join-Path $NavisworksInstallDir "Roamer.exe"
    Start-Process $roamer
    Start-Sleep -Seconds 10
    $app = [Autodesk.Navisworks.Api.Automation.NavisworksApplication]::TryGetRunningInstance()
}

if ($null -eq $app) {
    throw "Could not attach to a running Navisworks instance."
}

$pluginId = "NavisworksMcpProbe.Plugin.RRDL"

Write-Host ""
Write-Host "Executing probe before AddPluginAssembly..."
try {
    $app.ExecuteAddInPlugin($pluginId, @())
    Write-Host "  ExecuteAddInPlugin before AddPluginAssembly OK"
}
catch {
    Write-Host "  ExecuteAddInPlugin before AddPluginAssembly ERROR"
    Write-Host "  $($_.Exception.Message)"
}

Write-Host ""
Write-Host "Calling AddPluginAssembly for probe DLL..."
try {
    $app.AddPluginAssembly($PluginPath)
    Write-Host "  AddPluginAssembly OK"
}
catch {
    Write-Host "  AddPluginAssembly ERROR"
    Write-Host "  $($_.Exception.ToString())"
}

Write-Host ""
Write-Host "Executing probe AddInPlugin..."
try {
    $app.ExecuteAddInPlugin($pluginId, @())
    Write-Host "  ExecuteAddInPlugin OK"
}
catch {
    Write-Host "  ExecuteAddInPlugin ERROR"
    Write-Host "  $($_.Exception.ToString())"
}

Write-Host ""
Write-Host "Probe log:"
$probeLog = Join-Path $env:LOCALAPPDATA "NavisworksMcp\probe.log"
if (Test-Path $probeLog) {
    Get-Content $probeLog
}
else {
    Write-Host "  Missing: $probeLog"
}
