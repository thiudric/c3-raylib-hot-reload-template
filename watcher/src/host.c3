module watcher;

import std::atomic;
import std::io;
import std::os;
import std::thread;

fn bool run_host(os::process::Process* host_out)
{
    if (!@atomic_load(running))
    {
        return false;
    }

    os::process::Process? host = os::process::spawn(
        { HOST_PATH },
        INHERIT_STDIO | INHERIT_ENV
    );

    if (catch err = host)
    {
        io::printfn("Failed to launch host: %s", err);
        return false;
    }

    *host_out = host;
    return true;
}

fn void cleanup_host(os::process::Process* host)
{
    defer (void)host.destroy();

    bool? host_running = host.is_running();
    if (catch status_err = host_running)
    {
        io::printfn("Failed to check host during shutdown: %s", status_err);
        io::printn("Host status is unknown; attempting defensive termination.");
    }
    else if (!host_running)
    {
        return;
    }

    if (catch terminate_err = host.terminate())
    {
        io::printfn("Failed to terminate host: %s", terminate_err);

        // The host may have exited between the status check and termination.
        thread::sleep_ms(20);
        bool? still_running = host.is_running();
        if (catch verify_err = still_running)
        {
            io::printfn("WARNING: Could not verify whether the host stopped: %s", verify_err);
            io::printn("WARNING: Check for a remaining host process manually.");
        }
        else if (still_running)
        {
            io::printn("WARNING: The host is still running and must be closed manually.");
        }
        return;
    }

    int? host_exit = host.join();
    if (catch exit_err = host_exit)
    {
        io::printfn("Failed to wait for host termination: %s", exit_err);
    }
}
