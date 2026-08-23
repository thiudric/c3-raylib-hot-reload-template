# C3 Raylib Hot Reload Template

A C3 + Raylib 6 hot-reload template inspired by Karl Zylinski's Odin version.

The host executable stays alive and manages the hot-reload process and persistent game memory using an arena allocator. It loads new versions of the game shared library as needed.  When the size of the game state changes, the arena allocator is reset. 

Tested on Linux and Windows.

## Setup

### Dependencies

All platforms: c3c, cmake, git, gcc

optional for automatic file watching: Deno

On linux, these should be available in your package manager.

On Windows, I installed git-for-windows, cmake, and c3c from their respective websites, and added c3c's directory to my path environment variable

Additionally, on Windows, PowerShell 7:
`winget install --id Microsoft.PowerShell --source winget`

### Cloning the repo

all platforms:
```
git clone --recurse-submodules https://github.com/thiudric/c3-raylib-hot-reload-template
cd c3-raylib-hot-reload-template
```
run `git submodule update --init --recursive` if you forgot --recurse-submobules

## Dev Workflow 

automate with `deno task watch` or run the scripts manually as follows:

### Build Raylib/Raygui as shared library:

Linux: `./build_deps.sh`

Windows: `pwsh ./build_deps.ps1`

### Build the host: 

all platforms: `c3c build host`

### Build and publish the game library:

Linux: `./build_game.sh`

Windows: `pwsh ./build_game.ps1`

### run the host:

all platforms: `./build/host`

### Hot reloading

To update the active game library:
- edit tick/init_window/shutdown functions in `src/game/game.c3` 
- run `./build_game.sh(ps1)` again. 
- If something goes wrong, press F5 to force full reset of game state.

Optionally: `deno task watch`

Checks for Raylib/Raygui shared libraries, and dev host, and asks to
build them if missing. 
Launches the host and rebuilds game lib whenever a
file under `src/game` changes.

The watcher runs the platform-specific PowerShell scripts on Windows and shell
scripts on Linux.
Deno is not required for manual builds or release builds.

## Build for release:

Linux: `./build_release.sh`

Windows: `pwsh ./build_release.ps1`

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
