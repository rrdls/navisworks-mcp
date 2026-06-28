param(
    [int]$IntervalSeconds = 2,
    [string]$PluginPath = ""
)

$ErrorActionPreference = "Continue"

$appDataDir = Join-Path $env:LOCALAPPDATA "NavisworksMcp"
$logPath = Join-Path $appDataDir "autoloader.log"
$loadedProcessIds = @{}
$loadedAutomationDirs = @{}

function Find-PluginPath {
    $root = "C:\Program Files\Autodesk"
    foreach ($filter in @("Navisworks Manage *", "Navisworks Simulate *")) {
        $install = Get-ChildItem -Path $root -Directory -Filter $filter -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            Select-Object -First 1

        if ($null -ne $install) {
            $candidate = Join-Path $install.FullName "Plugins\NavisworksMcpAddin.Plugin\NavisworksMcpAddin.Plugin.dll"
            if (Test-Path $candidate) {
                return $candidate
            }
        }
    }

    return ""
}

function Write-AutoloaderLog {
    param([string]$Message)
    try {
        New-Item -ItemType Directory -Force -Path $appDataDir | Out-Null
        Add-Content -Path $logPath -Value ("{0:o} [AUTOLOADER] {1}" -f [DateTimeOffset]::Now, $Message)
    }
    catch {
    }
}

if ([string]::IsNullOrWhiteSpace($PluginPath)) {
    $PluginPath = Find-PluginPath
}

Write-AutoloaderLog "Navisworks MCP autoloader started."

while ($true) {
    try {
        if (!(Test-Path $PluginPath)) {
            Write-AutoloaderLog "Plugin DLL is missing: $PluginPath"
            Start-Sleep -Seconds $IntervalSeconds
            continue
        }

        $runningIds = @{}
        Get-Process Roamer -ErrorAction SilentlyContinue | ForEach-Object {
            $runningIds[$_.Id] = $true
            if ($loadedProcessIds.ContainsKey($_.Id)) {
                return
            }

            $installDir = Split-Path -Parent $_.Path
            $automationDll = Join-Path $installDir "Autodesk.Navisworks.Automation.dll"
            if (!(Test-Path $automationDll)) {
                Write-AutoloaderLog "Automation DLL not found for PID $($_.Id): $automationDll"
                return
            }

            if (!$loadedAutomationDirs.ContainsKey($installDir)) {
                Add-Type -Path $automationDll
                $loadedAutomationDirs[$installDir] = $true
            }

            $app = $null
            $deadline = (Get-Date).AddSeconds(30)
            do {
                Start-Sleep -Seconds 2
                $app = [Autodesk.Navisworks.Api.Automation.NavisworksApplication]::TryGetRunningInstance()
            } while ($null -eq $app -and (Get-Date) -lt $deadline)

            if ($null -eq $app) {
                Write-AutoloaderLog "TryGetRunningInstance failed for PID $($_.Id). Trying Automation constructor."
                $app = New-Object Autodesk.Navisworks.Api.Automation.NavisworksApplication
            }

            if ($null -eq $app) {
                Write-AutoloaderLog "Could not attach to running Navisworks PID $($_.Id)."
                return
            }

            $app.AddPluginAssembly($PluginPath)
            $loadedProcessIds[$_.Id] = $true
            Write-AutoloaderLog "Loaded plugin into Navisworks PID $($_.Id): $PluginPath"
        }

        @($loadedProcessIds.Keys) | ForEach-Object {
            if (!$runningIds.ContainsKey($_)) {
                $loadedProcessIds.Remove($_)
            }
        }
    }
    catch {
        Write-AutoloaderLog "Error: $($_.Exception.ToString())"
    }

    Start-Sleep -Seconds $IntervalSeconds
}
