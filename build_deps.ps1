#Requires -Version 5.1

param([switch] $Static)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory)]
        [string] $Command,

        [Parameter(Mandatory)]
        [string[]] $Arguments
    )

    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $Command $($Arguments -join ' ')"
    }
}

Push-Location $PSScriptRoot
try {
    foreach ($command in @('git', 'cmake')) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
            throw "Required command '$command' was not found on PATH."
        }
    }

    Write-Host '==> Updating submodules'
    Invoke-NativeCommand -Command git -Arguments @(
        'submodule', 'update', '--init', '--recursive'
    )

    $shared = 'ON'
    $buildDir = 'build/native-windows-shared'
    if ($Static) {
        $shared = 'OFF'
        $buildDir = 'build/native-windows-static'
    }

    Write-Host '==> Building Raylib and Raygui (MSVC x64, Release)'
    Write-Host 'Requires Visual Studio 2022 C++ Build Tools and a Windows SDK.'
    Invoke-NativeCommand -Command cmake -Arguments @(
        '-S', 'cmake/windows'
        '-B', $buildDir
        '-G', 'Visual Studio 17 2022'
        '-A', 'x64'
        "-DBUILD_SHARED_LIBS=$shared"
    )

    Invoke-NativeCommand -Command cmake -Arguments @(
        '--build', $buildDir
        '--config', 'Release'
        '--parallel'
    )

    Invoke-NativeCommand -Command cmake -Arguments @(
        '--install', $buildDir
        '--config', 'Release'
        '--prefix', (Join-Path $PSScriptRoot 'build')
        '--component', 'template'
    )

    Write-Host 'Dependencies built successfully.'
}
finally {
    Pop-Location
}
