#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Push-Location $PSScriptRoot
try {
    if (-not (Get-Command c3c -ErrorAction SilentlyContinue)) {
        throw "Required command 'c3c' was not found on PATH."
    }

    & c3c build game-windows
    if ($LASTEXITCODE -ne 0) {
        throw "c3c failed with exit code $LASTEXITCODE."
    }

    $source = Join-Path $PSScriptRoot 'build/game.dll'
    $destination = Join-Path $PSScriptRoot 'build/game_ready.dll'

    # Replace an existing publication without deleting it first.
    if ([System.IO.File]::Exists($destination)) {
        [System.IO.File]::Replace($source, $destination, [NullString]::Value)
    }
    else {
        [System.IO.File]::Move($source, $destination)
    }
    Write-Host 'Game library built successfully.'
}
finally {
    Remove-Item -LiteralPath game.lib -ErrorAction SilentlyContinue
    Pop-Location
}
