# C3 Raylib Hot Reload Template

A C3 + Raylib 6 hot-reload template inspired by Karl Zylinski's Odin version.

The host executable stays alive and manages the hot-reload process and persistent game memory using an arena allocator. It loads new versions of the game shared library as needed.  When the size of the game state changes, the arena allocator is reset. 

Tested on Linux and Windows.

For the simplest development workflow, there is an optional C3 watcher program included that launches the game and automatically rebuilds the game whenever a file under `src/game` changes. It also detects if dependencies need to be built and offers to do so. The watcher runs the platform-specific PowerShell scripts on Windows and shell scripts on Linux.

```
cd watcher
c3c build watcher
cd ..
```

Linux: `./watcher/build/watcher`

Windows: `.\watcher\build\watcher.exe`

## Dev Workflow

### Dependencies

All platforms: c3c 0.8.3+, cmake 3.24+, git, gcc

Windows: mingw32-make

On linux, these should be available in your package manager.

On Windows, I installed git-for-windows, cmake, and c3c from their respective websites, and added c3c's directory to my path environment variable. The build scripts use Windows PowerShell 5.1, which is included with Windows.

### Cloning the repo

all platforms:
```
git clone --recurse-submodules https://github.com/thiudric/c3-raylib-hot-reload-template
cd c3-raylib-hot-reload-template
```
run `git submodule update --init --recursive` if you forgot --recurse-submodules

### Build Raylib/Raygui as shared library:

Linux: `./build_deps.sh`

Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build_deps.ps1`

(you may be able to just run `./build_deps.ps1` without the extra parameters)

### Build the host: 
all platforms: `c3c build host `

### Build and publish the game library:

Linux: `./build_game.sh`

Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build_game.ps1`

### run the host:

Linux: `./build/host`
Windows: `.\build\host.exe`

### Hot reloading

To update the active game library:
- edit tick/init_window/shutdown functions in `src/game/game.c3` 
- run `./build_game.sh(ps1)` again, depending on platform. 
- If something goes wrong, press F5 to force full reset of game state.

## Build for release:

Linux: `./build_release.sh`

Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build_release.ps1`

outputs `build/release` with dependencies bundled into a single executable

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
