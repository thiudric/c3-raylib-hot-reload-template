#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Push-Location $PSScriptRoot
try {
    if (-not (Get-Command c3c -ErrorAction SilentlyContinue)) {
        throw "Required command 'c3c' was not found on PATH."
    }

    & (Join-Path $PSScriptRoot 'build_deps.ps1') -Static

    Write-Host '==> Building release executable'
    & c3c build release-windows
    if ($LASTEXITCODE -ne 0) {
        throw "C3 release build failed with exit code ${LASTEXITCODE}."
    }

    Write-Host ''
    Write-Host 'Release build complete:'
    Write-Host '  build/release.exe'
}
finally {
    Pop-Location
}
