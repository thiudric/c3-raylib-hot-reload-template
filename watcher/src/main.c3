module watcher;

import libc;
import dmon;
import std::atomic;
import std::io;
import std::os;
import std::thread;

bool dirty = false;
bool running = true;

fn void on_change(
    dmon::WatchId watch_id,
    dmon::Action action,
    ZString rootdir,
    ZString filepath,
    ZString oldfilepath,
    void* user
)
{
    atomic::flag_set(&dirty);
}

fn void on_signal(CInt signal @unused)
{
    @atomic_store(running, false);
}

fn int main(String[] args)
{
    // Validate the expected project layout.
    if (!validate_project_root())
    {
        return 1;
    }

    // Prepare external dependencies and the host executable.
    io::printn("Checking dependencies...");
    if (!deps_exist())
    {
        bool prompt_result = prompt_yesno("Raylib shared libs not found. Build raylib?");
        if (prompt_result)
        {
            bool build_deps_res = run_command("Build dependencies", BUILD_DEPS_CMD);
            if (!build_deps_res || !deps_exist())
            {
                io::printn("Failed to prepare dependencies. Exiting.");
                return 1;
            }
        }
        else
        {
            io::printn("Exiting.");
            return 0;
        }
    }
    else
    {
        io::printn("Dependencies found.");
    }

    if (!file::exists(HOST_PATH))
    {
        bool prompt_result = prompt_yesno("Host executable not found. Build host?");
        if (prompt_result)
        {
            bool build_host_res = run_command("Build host", BUILD_HOST_CMD);
            if (!build_host_res || !file::exists(HOST_PATH))
            {
                io::printn("Failed to prepare host. Exiting.");
                return 1;
            }
        }
        else
        {
            io::printn("Exiting.");
            return 0;
        }
    }
    else
    {
        io::printn("Host executable found.");
    }

    // Build the initial game library before starting the host.
    bool build_game_res = run_command("Build game", BUILD_GAME_CMD);
    if (!build_game_res)
    {
        io::printn("Failed to build game. Exiting.");
        return 1;
    }

    // Start watching game sources and register shutdown handling.
    dmon::init();
    defer dmon::deinit();

    dmon::WatchId watch_id = dmon::watch(
        GAME_SRC_DIR,
        &on_change,
        dmon::WatchFlags.RECURSIVE,
        null
    );
    if (watch_id.id == 0)
    {
        io::printn("Failed to watch game sources. Exiting.");
        return 1;
    }
    defer dmon::unwatch(watch_id);
    io::printn("Watching... press Ctrl+C to quit.");

    (void)libc::signal(libc::SIGINT, &on_signal);
    (void)libc::signal(libc::SIGTERM, &on_signal);

    // Launch the host and ensure it is cleaned up on exit.
    io::printn("Launching host...");
    os::process::Process host;
    if (!run_host(&host))
    {
        if (!@atomic_load(running))
        {
            io::printn("Host launch cancelled.");
            return 0;
        }

        return 1;
    }
    defer cleanup_host(&host);

    // Monitor the host and rebuild when source changes are reported.
    while (@atomic_load(running))
    {
        bool dirty_flag = atomic::flag_clear(&dirty);
        bool? host_running = host.is_running();

        if (catch err = host_running)
        {
            io::printfn("Failed to check host status: %s", err);
            return 1;
        }

        if (!host_running)
        {
            int? host_exit = host.join();
            if (catch err = host_exit)
            {
                io::printfn("Failed to read host exit status: %s", err);
                return 1;
            }

            if (host_exit != 0)
            {
                io::printfn("Host exited with code %d.", host_exit);
            }
            else
            {
                io::printn("Host exited.");
            }
            return host_exit;
        }

        if (!dirty_flag)
        {
            thread::sleep_ms(20);
            continue;
        }

        io::printn("Rebuilding...");
        build_game_res = run_command("Build game", BUILD_GAME_CMD);
        if (!build_game_res)
        {
            io::printn("Build failed. Continuing.");
            continue;
        }

        io::printn("Build succeeded. Waiting for changes...");
    }

    return 0;
}
