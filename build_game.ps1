#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Push-Location $PSScriptRoot
try {
    if (-not (Get-Command c3c -ErrorAction SilentlyContinue)) {
        throw "Required command 'c3c' was not found on PATH."
    }

    & c3c build game --wincrt=dynamic
    if ($LASTEXITCODE -ne 0) {
        throw "c3c failed with exit code $LASTEXITCODE."
    }

    Move-Item -LiteralPath build/game.dll -Destination build/game_ready.dll -Force
    Write-Host 'Game library built successfully.'
}
finally {
    Pop-Location
}
