#!/usr/bin/env bash
set -euo pipefail

echo "==> Updating submodules"
git submodule update --init --recursive


echo "==> Building static Raylib"

cmake \
    -S vendor/raylib \
    -B build/raylib-static \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON

cmake --build build/raylib-static


echo "==> Building static Raygui"

mkdir -p build/raygui-static

cp \
    vendor/raygui/src/raygui.h \
    build/raygui-static/raygui.c

cc \
    -O3 \
    -fPIC \
    -DRAYGUI_IMPLEMENTATION \
    -Ivendor/raylib/src \
    -c build/raygui-static/raygui.c \
    -o build/raygui-static/raygui.o

ar rcs \
    build/raygui-static/libraygui.a \
    build/raygui-static/raygui.o


echo "==> Building release executable"

c3c build release-linux


echo
echo "Release build complete:"
echo "  build/release"
