#!/usr/bin/env bash
set -euo pipefail

# Make sure vendored dependencies are present.
git submodule update --init --recursive

# Build Raylib as a shared library.
cmake \
    -S vendor/raylib \
    -B build/raylib \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_EXAMPLES=OFF

cmake --build build/raylib

# Build Raygui as a shared library.
mkdir -p build/raygui

cp vendor/raygui/src/raygui.h build/raygui/raygui.c

gcc \
    -o build/raygui/libraygui.so \
    build/raygui/raygui.c \
    -shared \
    -fPIC \
    -DRAYGUI_IMPLEMENTATION \
    -DBUILD_LIBTYPE_SHARED \
    -Ivendor/raylib/src \
    -Lbuild/raylib/raylib \
    -l:libraylib.so.600 \
    -Wl,-rpath,'$ORIGIN/../raylib/raylib'

echo "Dependencies built successfully."
