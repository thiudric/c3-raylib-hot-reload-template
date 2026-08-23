#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory, Position = 0)]
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
    Assert-CommandExists gcc
    Assert-CommandExists mingw32-make

    # Make sure vendored dependencies are present.
    Invoke-NativeCommand -Command git -Arguments @(
        'submodule', 'update', '--init', '--recursive'
    )

    # Build Raylib as a shared library using the same MinGW toolchain as Raygui.
    Invoke-NativeCommand -Command cmake -Arguments @(
        '-S', 'vendor/raylib'
        '-B', 'build/raylib'
        '-G', 'MinGW Makefiles'
        '-DBUILD_SHARED_LIBS=ON'
        '-DBUILD_EXAMPLES=OFF'
        '-DCMAKE_C_COMPILER=gcc'
    )

    Invoke-NativeCommand -Command cmake -Arguments @(
        '--build', 'build/raylib', '--parallel'
    )

    # Build Raygui as a DLL and emit the import library required by the linker.
    New-Item -ItemType Directory -Path build/raygui -Force | Out-Null
    Copy-Item vendor/raygui/src/raygui.h build/raygui/raygui.c -Force

    Invoke-NativeCommand -Command gcc -Arguments @(
        '-o', 'build/raygui/raygui.dll'
        'build/raygui/raygui.c'
        '-shared'
        '-DRAYGUI_IMPLEMENTATION'
        '-DBUILD_LIBTYPE_SHARED'
        '-Ivendor/raylib/src'
        '-Lbuild/raylib/raylib'
        '-lraylib'
        '-Wl,--out-implib,build/raygui/libraygui.dll.a'
    )

    # The C3 raylib package asks the Windows linker for these MSVC-style names.
    # LLVM's COFF linker can consume the MinGW import libraries directly.
    Copy-Item build/raylib/raylib/libraylib.dll.a build/raylib/raylib/raylib.lib -Force
    Copy-Item build/raygui/libraygui.dll.a build/raygui/raygui.lib -Force

    # Runtime dependencies must be beside host.exe for Windows DLL resolution.
    Copy-Item build/raylib/raylib/libraylib.dll build/libraylib.dll -Force
    Copy-Item build/raygui/raygui.dll build/raygui.dll -Force

    Write-Host 'Dependencies built successfully.'
}
finally {
    Pop-Location
}
