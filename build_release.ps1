#Requires -Version 7.0

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

function Assert-CommandExists {
    param(
        [Parameter(Mandatory)]
        [string] $Command
    )

    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        throw "Required command '$Command' was not found on PATH."
    }
}

Push-Location $PSScriptRoot
try {
    Assert-CommandExists git
    Assert-CommandExists cmake
    Assert-CommandExists c3c

    Write-Host '==> Updating submodules'
    Invoke-NativeCommand -Command git -Arguments @(
        'submodule', 'update', '--init', '--recursive'
    )

    Write-Host '==> Building static Raylib'
    Invoke-NativeCommand -Command cmake -Arguments @(
        '--fresh'
        '-S', 'vendor/raylib'
        '-B', 'build/raylib-static'
        '-G', 'Visual Studio 17 2022'
        '-A', 'x64'
        '-DBUILD_SHARED_LIBS=OFF'
        '-DBUILD_EXAMPLES=OFF'
    )

    Invoke-NativeCommand -Command cmake -Arguments @(
        '--build', 'build/raylib-static'
        '--config', 'Release'
        '--parallel'
    )

    Write-Host '==> Building static Raygui'
    Invoke-NativeCommand -Command cmake -Arguments @(
        '--fresh'
        '-S', 'cmake/raygui-static'
        '-B', 'build/raygui-static'
        '-G', 'Visual Studio 17 2022'
        '-A', 'x64'
    )

    Invoke-NativeCommand -Command cmake -Arguments @(
        '--build', 'build/raygui-static'
        '--config', 'Release'
        '--parallel'
    )

    # Multi-config Visual Studio builds place libraries in a Release subfolder;
    # stage them where project.json tells C3 to search.
    Copy-Item build/raylib-static/raylib/Release/raylib.lib build/raylib-static/raylib/raylib.lib -Force
    Copy-Item build/raygui-static/Release/raygui.lib build/raygui-static/raygui.lib -Force

    Write-Host '==> Building release executable'
    Invoke-NativeCommand -Command c3c -Arguments @(
        'build', 'release', '--wincrt=dynamic'
    )

    Write-Host ''
    Write-Host 'Release build complete:'
    Write-Host '  build/release.exe'
}
finally {
    Pop-Location
}
