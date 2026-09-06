module watcher;

const String[] BUILD_DEPS_CMD @feat(WIN32) = {
    "powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "./build_deps.ps1"
};

const String[] BUILD_DEPS_CMD @feat(LINUX) = {
    "./build_deps.sh"
};

const String[] BUILD_HOST_CMD = {
    "c3c", "build", "host"
};

const String[] BUILD_GAME_CMD @feat(WIN32) = {
    "powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "./build_game.ps1"
};

const String[] BUILD_GAME_CMD @feat(LINUX) = {
    "./build_game.sh"
};

const String[] DEP_PATHS @feat(WIN32) = {
    "./build/libraylib.dll",
    "./build/raygui.dll",
    "./build/raylib/raylib/raylib.lib",
    "./build/raygui/raygui.lib"
};

const String[] DEP_PATHS @feat(LINUX) = {
    "./build/raylib/raylib/libraylib.so.600",
    "./build/raygui/libraygui.so"
};

const String HOST_PATH @feat(WIN32) = "./build/host.exe";
const String HOST_PATH @feat(LINUX) = "./build/host";
const String GAME_SRC_DIR = "./src/game";
const String HOST_SRC_DIR = "./src/host";
const String PROJECT_FILE = "./project.json";

