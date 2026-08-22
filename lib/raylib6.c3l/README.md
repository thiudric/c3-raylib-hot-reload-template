# C3 Raylib Bindings

These bindings are vendored from the C3 vendor repository:

`c3lang/vendor/libraries/raylib6.c3l`

The binding source files are used essentially unchanged.

The local `manifest.json` has been modified to remove the bundled/native
Raylib and Raygui link dependencies. This template builds and links Raylib
and Raygui as shared libraries instead, which is required for hot reloading.

The original bindings are licensed under the MIT License.
See `LICENSE`.
