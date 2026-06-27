$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pythonDir = Join-Path $repoRoot "python"
$venvDir = Join-Path $repoRoot ".venv"

if (!(Test-Path $venvDir)) {
    python -m venv $venvDir
}

$pythonExe = Join-Path $venvDir "Scripts\python.exe"
& $pythonExe -m pip install --upgrade pip
& $pythonExe -m pip install -e $pythonDir
& $pythonExe -m pip install pytest

Push-Location $repoRoot
try {
    & $pythonExe -m pytest -q
}
finally {
    Pop-Location
}

