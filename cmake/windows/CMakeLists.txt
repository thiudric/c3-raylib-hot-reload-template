cmake_minimum_required(VERSION 3.25)
project(windows-deps LANGUAGES C)

if(NOT MSVC)
    message(FATAL_ERROR "Windows dependencies require the MSVC toolchain.")
endif()

option(BUILD_SHARED_LIBS "Build shared development libraries" ON)
set(BUILD_EXAMPLES OFF CACHE BOOL "Build raylib examples" FORCE)
# Match the dynamic CRT used by the Windows C3 targets.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")

add_subdirectory(../../vendor/raylib raylib-build)
add_library(raygui raygui.c)
target_include_directories(raygui PRIVATE ../../vendor/raylib/src)

if(BUILD_SHARED_LIBS)
    target_compile_definitions(raygui PRIVATE BUILD_LIBTYPE_SHARED)
    target_link_libraries(raygui PRIVATE raylib)
    set(raylib_archive_dir raylib/raylib)
    set(raygui_archive_dir raygui)
else()
    set(raylib_archive_dir raylib-static/raylib)
    set(raygui_archive_dir raygui-static)
endif()

# Preserve the library search paths in project.json and stage DLLs beside host.exe.
install(TARGETS raylib
    RUNTIME DESTINATION . COMPONENT template
    ARCHIVE DESTINATION ${raylib_archive_dir} COMPONENT template
    PUBLIC_HEADER DESTINATION include COMPONENT headers EXCLUDE_FROM_ALL)
install(TARGETS raygui
    RUNTIME DESTINATION . COMPONENT template
    ARCHIVE DESTINATION ${raygui_archive_dir} COMPONENT template)
