$ErrorActionPreference = "Stop"

$roots = @(
    "C:\Program Files\Autodesk"
)

$found = @()

foreach ($root in $roots) {
    if (!(Test-Path $root)) {
        continue
    }

    Get-ChildItem -Path $root -Directory -Filter "Navisworks *" | ForEach-Object {
        $apiPath = Join-Path $_.FullName "Autodesk.Navisworks.Api.dll"
        if (Test-Path $apiPath) {
            $version = $_.Name -replace '^Navisworks (Manage|Simulate) ', ''
            $edition = if ($_.Name -match '^Navisworks (Manage|Simulate) ') { $Matches[1] } else { "" }
            $found += [pscustomobject]@{
                Version = $version
                Edition = $edition
                InstallDir = $_.FullName
                NavisworksApi = $apiPath
                InstallCommand = ".\scripts\install-addin.ps1 -NavisworksVersion $version -NavisworksInstallDir `"$($_.FullName)`""
                VerifyCommand = ".\scripts\verify-windows.ps1 -NavisworksVersion $version -NavisworksInstallDir `"$($_.FullName)`""
            }
        }
    }
}

if ($found.Count -eq 0) {
    Write-Host "No Navisworks installations with Autodesk.Navisworks.Api.dll were found under C:\Program Files\Autodesk."
    Write-Host "If Navisworks is installed elsewhere, pass -NavisworksInstallDir to install-addin.ps1."
    exit 1
}

$found | Sort-Object Version -Descending | Format-List
