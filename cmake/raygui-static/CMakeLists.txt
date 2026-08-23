cmake_minimum_required(VERSION 3.15)
project(raygui-static LANGUAGES C)

add_library(raygui STATIC raygui.c)
target_include_directories(raygui PRIVATE ../../vendor/raylib/src)
