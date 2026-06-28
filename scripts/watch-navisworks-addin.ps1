param(
    [int]$IntervalSeconds = 2
)

$ErrorActionPreference = "Continue"

$appDataDir = Join-Path $env:LOCALAPPDATA "NavisworksMcp"
$logPath = Join-Path $appDataDir "autoloader.log"
$pluginPath = Join-Path $env:APPDATA "Autodesk\ApplicationPlugins\NavisworksMcp.bundle\Contents\NavisworksMcpAddin.Plugin.dll"
$loadedProcessIds = @{}
$loadedAutomationDirs = @{}

function Write-AutoloaderLog {
    param([string]$Message)
    try {
        New-Item -ItemType Directory -Force -Path $appDataDir | Out-Null
        Add-Content -Path $logPath -Value ("{0:o} [AUTOLOADER] {1}" -f [DateTimeOffset]::Now, $Message)
    }
    catch {
    }
}

Write-AutoloaderLog "Navisworks MCP autoloader started."

while ($true) {
    try {
        if (!(Test-Path $pluginPath)) {
            Write-AutoloaderLog "Plugin DLL is missing: $pluginPath"
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
                Write-AutoloaderLog "Could not attach to running Navisworks PID $($_.Id)."
                return
            }

            $app.AddPluginAssembly($pluginPath)
            $loadedProcessIds[$_.Id] = $true
            Write-AutoloaderLog "Loaded plugin into Navisworks PID $($_.Id): $pluginPath"
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
