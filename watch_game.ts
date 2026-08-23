const projectRoot = import.meta.dirname;
if (!projectRoot) {
  throw new Error("watch_game.ts must be run from a local file");
}

const gameSourceDirectory = `${projectRoot}/src/game`;
const debounceMilliseconds = 150;

type Command = {
  command: string;
  args: string[];
};

const platform = (() => {
  switch (Deno.build.os) {
    case "windows":
      return {
        dependencyPaths: [
          `${projectRoot}/build/libraylib.dll`,
          `${projectRoot}/build/raygui.dll`,
          `${projectRoot}/build/raylib/raylib/raylib.lib`,
          `${projectRoot}/build/raygui/raygui.lib`,
        ],
        buildDependencies: {
          command: "pwsh",
          args: ["-NoProfile", "-File", "./build_deps.ps1"],
        },
        buildGame: {
          command: "pwsh",
          args: ["-NoProfile", "-File", "./build_game.ps1"],
        },
        hostPath: `${projectRoot}/build/host.exe`,
      };
    case "linux":
      return {
        dependencyPaths: [
          `${projectRoot}/build/raylib/raylib/libraylib.so.600`,
          `${projectRoot}/build/raygui/libraygui.so`,
        ],
        buildDependencies: {
          command: "./build_deps.sh",
          args: [],
        },
        buildGame: {
          command: "./build_game.sh",
          args: [],
        },
        hostPath: `${projectRoot}/build/host`,
      };
    default:
      throw new Error(`Unsupported platform: ${Deno.build.os}`);
  }
})();

async function pathExists(path: string): Promise<boolean> {
  try {
    await Deno.stat(path);
    return true;
  } catch (error) {
    if (error instanceof Deno.errors.NotFound) {
      return false;
    }
    throw error;
  }
}

async function runCommand(label: string, command: Command): Promise<boolean> {
  console.log(`\n[watch] ${label}...`);

  try {
    const child = new Deno.Command(command.command, {
      args: command.args,
      cwd: projectRoot,
      stdin: "inherit",
      stdout: "inherit",
      stderr: "inherit",
    }).spawn();
    const status = await child.status;

    if (!status.success) {
      console.error(`[watch] ${label} failed with exit code ${status.code}.`);
    }
    return status.success;
  } catch (error) {
    console.error(`[watch] Could not run ${command.command}:`, error);
    return false;
  }
}

const missingDependencies = [];
for (const path of platform.dependencyPaths) {
  if (!await pathExists(path)) {
    missingDependencies.push(path);
  }
}

if (missingDependencies.length > 0) {
  console.log("[watch] Missing Raylib/Raygui dependency artifacts:");
  for (const path of missingDependencies) {
    console.log(`  - ${path}`);
  }

  if (!confirm("Build the missing dependencies now?")) {
    console.log("[watch] Cannot continue without the shared dependencies.");
    Deno.exit(0);
  }

  if (!await runCommand("Building dependencies", platform.buildDependencies)) {
    Deno.exit(1);
  }
}

if (!await pathExists(platform.hostPath)) {
  if (!confirm("The development host is missing. Build it now?")) {
    console.log("[watch] Cannot continue without the development host.");
    Deno.exit(0);
  }

  if (
    !await runCommand("Building host", {
      command: "c3c",
      args: ["build", "host"],
    })
  ) {
    Deno.exit(1);
  }
}

let debounceTimer: ReturnType<typeof setTimeout> | undefined;
let buildIsRunning = false;
let rebuildRequested = false;

async function buildGame(): Promise<boolean> {
  if (buildIsRunning) {
    rebuildRequested = true;
    return true;
  }

  buildIsRunning = true;
  let succeeded = true;
  try {
    do {
      rebuildRequested = false;
      succeeded = await runCommand(
        `Building game at ${new Date().toLocaleTimeString()}`,
        platform.buildGame,
      );

      if (succeeded) {
        console.log("[watch] Build succeeded. Waiting for changes...");
      }
    } while (rebuildRequested);
  } finally {
    buildIsRunning = false;
  }
  return succeeded;
}

function scheduleBuild(): void {
  if (debounceTimer !== undefined) {
    clearTimeout(debounceTimer);
  }

  debounceTimer = setTimeout(() => {
    debounceTimer = undefined;
    void buildGame();
  }, debounceMilliseconds);
}

function isTransientApplicationControlError(error: unknown): boolean {
  if (Deno.build.os !== "windows" || !(error instanceof Error)) {
    return false;
  }

  return error.message.includes("os error 4551") ||
    error.message.includes("Application Control policy has blocked this file");
}

async function launchHost(): Promise<Deno.ChildProcess> {
  const retryDelays = [250, 500, 1_000, 2_000];

  for (let attempt = 0;; attempt += 1) {
    try {
      return new Deno.Command(platform.hostPath, {
        cwd: projectRoot,
        stdin: "inherit",
        stdout: "inherit",
        stderr: "inherit",
      }).spawn();
    } catch (error) {
      if (
        !isTransientApplicationControlError(error) ||
        attempt >= retryDelays.length
      ) {
        throw error;
      }

      const delay = retryDelays[attempt];
      console.log(
        `[watch] Windows is still evaluating the new host; retrying in ${delay} ms...`,
      );
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }
}

if (!await buildGame()) {
  Deno.exit(1);
}

const watcher = Deno.watchFs(gameSourceDirectory, { recursive: true });
console.log(`[watch] Watching ${gameSourceDirectory}`);
console.log(`[watch] Launching ${platform.hostPath}`);
console.log("[watch] Press Ctrl+C to stop.");

const host = await launchHost();

let stopping = false;
const stop = () => {
  if (stopping) return;
  stopping = true;
  if (debounceTimer !== undefined) {
    clearTimeout(debounceTimer);
    debounceTimer = undefined;
  }
  watcher.close();
  try {
    host.kill();
  } catch {
    // The host may have already exited.
  }
};

Deno.addSignalListener("SIGINT", stop);

const watchTask = (async () => {
  try {
    for await (const event of watcher) {
      if (event.kind !== "access" && event.kind !== "other") {
        scheduleBuild();
      }
    }
  } catch (error) {
    if (!stopping) throw error;
  }
})();

const hostStatus = await host.status;
if (!stopping) {
  stopping = true;
  watcher.close();
}
if (debounceTimer !== undefined) {
  clearTimeout(debounceTimer);
  debounceTimer = undefined;
}
await watchTask;
Deno.removeSignalListener("SIGINT", stop);

if (!hostStatus.success) {
  console.error(`[watch] Host exited with code ${hostStatus.code}.`);
}
Deno.exit(hostStatus.code);
