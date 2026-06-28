param(
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pythonDir = Join-Path $repoRoot "python"
$venvDir = Join-Path $repoRoot ".venv-build"
$distDir = Join-Path $repoRoot "dist\NavisworksMcp\app"
$workDir = Join-Path $repoRoot "dist\pyinstaller-work"

if (!(Test-Path $venvDir)) {
    python -m venv $venvDir
}

$pythonExe = Join-Path $venvDir "Scripts\python.exe"
& $pythonExe -m pip install --upgrade pip
& $pythonExe -m pip install -e "${pythonDir}[build]"
Get-ChildItem -Path $venvDir -Recurse -Force -Filter "*:Zone.Identifier" -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue
& $pythonExe -c "import jsonschema_specifications; list(jsonschema_specifications.REGISTRY)"

New-Item -ItemType Directory -Force -Path $distDir | Out-Null
Remove-Item -Force -ErrorAction SilentlyContinue `
    (Join-Path $distDir "NavisworksMcpServer.exe"),
    (Join-Path $distDir "NavisworksMcpLauncher.exe")

Copy-Item -Path (Join-Path $PSScriptRoot "load-navisworks-addin.ps1") -Destination $distDir -Force
Copy-Item -Path (Join-Path $PSScriptRoot "watch-navisworks-addin.ps1") -Destination $distDir -Force

& $pythonExe -m PyInstaller `
    --noconfirm `
    --clean `
    --onefile `
    --additional-hooks-dir (Join-Path $repoRoot "packaging\pyinstaller\hooks") `
    --name NavisworksMcpServer `
    --distpath $distDir `
    --workpath $workDir `
    --specpath (Join-Path $repoRoot "dist") `
    (Join-Path $repoRoot "packaging\pyinstaller\server_entry.py")

& $pythonExe -m PyInstaller `
    --noconfirm `
    --clean `
    --onefile `
    --windowed `
    --additional-hooks-dir (Join-Path $repoRoot "packaging\pyinstaller\hooks") `
    --name NavisworksMcpLauncher `
    --distpath $distDir `
    --workpath $workDir `
    --specpath (Join-Path $repoRoot "dist") `
    (Join-Path $repoRoot "packaging\pyinstaller\launcher_entry.py")

Write-Host "Built:"
Write-Host "  $(Join-Path $distDir 'NavisworksMcpServer.exe')"
Write-Host "  $(Join-Path $distDir 'NavisworksMcpLauncher.exe')"
