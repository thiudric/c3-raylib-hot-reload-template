# C3 Raylib Hot Reload Template

A C3 + Raylib 6 hot-reload template inspired by Karl Zylinski's Odin version.

The host executable stays alive and manages the hot-reload process and persistent game memory using an arena allocator. It loads new versions of the game shared library as needed.  When the size of the game state changes, the arena allocator is reset. 

Linux only. (for now)

## Workflow

Dependencies: c3c, cmake, git, gcc

clone the repo and raylib submodule:

```
git clone --recurse-submodules https://github.com/galarus/c3-raylib-hot-reload-template
cd c3-raylib-hot-reload-template
```

build raylib/raygui as shared library:

```
./build_deps.sh
```

build the host: 

```
c3c build host 
```

build and publish the game library:
```
./build_game.sh
```

run the host:
```
./build/host
```

To update the game library, edit tick/init_window/shutdown functions in `src/game/game.c3` and run `./build_game.sh` again. If something goes wrong, press F5 to force full reset of game state.

release build:
```
./build_release.sh
```
outputs `build/release` with dependencies bundled into a single executable

## TODO

- [ ] More accurate C3 struct-state/layout checking to determine when a full reload is required
- [ ] Optional source code watching / automatic rebuilds
- [ ] Windows support
- [ ] macOS support 

## Inspiration

* [C3](https://c3-lang.org/)
* [Raylib](https://www.raylib.com/)
* [Karl Zylinski's Odin Raylib Hot Reload Template](https://github.com/karl-zylinski/odin-raylib-hot-reload)

## License

MIT-0. Third-party dependencies retain their respective licenses.
