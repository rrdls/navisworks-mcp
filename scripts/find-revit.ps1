$ErrorActionPreference = "Stop"

$roots = @(
    "C:\Program Files\Autodesk"
)

$found = @()

foreach ($root in $roots) {
    if (!(Test-Path $root)) {
        continue
    }

    Get-ChildItem -Path $root -Directory -Filter "Revit *" | ForEach-Object {
        $apiPath = Join-Path $_.FullName "RevitAPI.dll"
        if (Test-Path $apiPath) {
            $version = $_.Name.Replace("Revit ", "")
            $found += [pscustomobject]@{
                Version = $version
                InstallDir = $_.FullName
                RevitApi = $apiPath
                InstallCommand = ".\scripts\install-addin.ps1 -RevitVersion $version -RevitInstallDir `"$($_.FullName)`""
                VerifyCommand = ".\scripts\verify-windows.ps1 -RevitVersion $version -RevitInstallDir `"$($_.FullName)`""
            }
        }
    }
}

if ($found.Count -eq 0) {
    Write-Host "No Revit installations with RevitAPI.dll were found under C:\Program Files\Autodesk."
    Write-Host "If Revit is installed elsewhere, pass -RevitInstallDir to install-addin.ps1."
    exit 1
}

$found | Sort-Object Version -Descending | Format-List

