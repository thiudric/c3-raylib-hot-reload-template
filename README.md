# C3 Raylib Hot Reload Template

A C3 + Raylib 6 hot-reload template inspired by Karl Zylinski's Odin version.

The host executable stays alive and manages the hot-reload process and persistent game memory using an arena allocator. It loads new versions of the game shared library as needed.  When the size of the game state changes, the arena allocator is reset. 

Tested on Linux and Windows.

For the simplest development workflow, there is an optional C3 watcher program included that launches the game and automatically rebuilds the game whenever a file under `src/game` changes. It also detects if dependencies need to be built and offers to do so. The watcher runs the platform-specific PowerShell scripts on Windows and shell scripts on Linux.



## Setup

### Dependencies

All platforms: c3c 0.8.3+, CMake 3.25+, Git. Add `c3c`, `cmake`, and `git` to your `PATH`.

Linux: GCC/G++, Make, binutils, and development headers/libraries for libc, OpenGL, and X11.

On Debian/Ubuntu:

```sh
sudo apt update
sudo apt install build-essential binutils cmake git \
    libgl1-mesa-dev libx11-dev libxrandr-dev libxinerama-dev \
    libxcursor-dev libxi-dev libxext-dev
```

Windows (x64): install **Visual Studio 2022 Build Tools** with the **Desktop development with C++** workload, including the MSVC v143 x64/x86 build tools and a Windows 10 or 11 SDK. 

### Cloning the repo

all platforms:
```
git clone --recurse-submodules https://github.com/thiudric/c3-raylib-hot-reload-template
cd c3-raylib-hot-reload-template
```
run `git submodule update --init --recursive` if you forgot --recurse-submodules

## Dev Workflow 

### Recommended - Watcher Executable

```
cd watcher
c3c build watcher
cd ..
```

Linux: `./watcher/build/watcher`

Windows: `.\watcher\build\watcher.exe`

### Alternatively follow the manual steps below 

#### Build Raylib/Raygui as shared library:

Linux: `./build_deps.sh`

Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build_deps.ps1`

You can also run `.\build_deps.ps1` directly if your PowerShell execution policy permits it.

#### Build the host: 
all platforms: `c3c build host`

#### Build and publish the game library:

Linux: `c3c build game-linux`

Windows: `c3c build game-windows`

#### run the host:

Linux: `./build/host`

Windows: `.\build\host.exe`

#### Hot reloading

To update the active game library:
- edit tick/init_window/shutdown functions in `src/game/game.c3` 
- run `c3c build game-linux` or `c3c build game-windows` again, depending on platform. 
- If something goes wrong, press F5 to force full reset of game state.

## Build for release:

Linux: `./build_release.sh`

Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build_release.ps1`

Produces `build/release` on Linux or `build/release.exe` on Windows, with Raylib and Raygui statically linked. The Windows release script builds its static dependencies automatically using the same CMake/MSVC setup as development; no prior shared-library build is required. The Windows executable still uses the dynamic C runtime, including `VCRUNTIME140.dll`; deployment machines need the Microsoft Visual C++ 2015–2022 Redistributable (x64). Static Raylib/Raygui linkage does not mean a fully static executable.

## TODO

- [ ] More accurate C3 struct-state/layout checking to determine when a full reload is required
- [x] Optional source code watching / automatic rebuilds
- [x] Windows support
- [ ] macOS support 
- [ ] wasm release builds

## Inspiration

* [C3](https://c3-lang.org/)
* [Raylib](https://www.raylib.com/)
* [Karl Zylinski's Odin Raylib Hot Reload Template](https://github.com/karl-zylinski/odin-raylib-hot-reload)

## License

MIT-0. Third-party dependencies retain their respective licenses.
