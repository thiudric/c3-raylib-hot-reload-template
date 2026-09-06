module watcher;

import std::io;
import std::os;

fn bool deps_exist()
{
    bool found_all = true;

    foreach (path : DEP_PATHS)
    {
        if (!file::exists(path))
        {
            io::printfn("Missing dependency: %s", path);
            found_all = false;
        }
    }

    return found_all;
}

fn bool run_command(String label, String[] cmd)
{
    io::printfn("%s...", label);

    int? result = os::process::run(cmd, INHERIT_STDIO | INHERIT_ENV);
    if (catch err = result)
    {
        io::printfn("Failed to %s: %s", label, err);
        return false;
    }

    if (result != 0)
    {
        io::printfn("%s failed with exit code %d", label, result);
        return false;
    }

    return true;
}

fn bool prompt_yesno(String prompt)
{
    io::printf("%s [Y/n] ", prompt);

    String? response = io::treadline();
    if (catch err = response)
    {
        io::printfn("Error reading stdin: %s", err);
        return false;
    }

    String input = response.trim();
    if (input.len == 0)
    {
        return true;
    }

    char first = input[0];
    return first == 'Y' || first == 'y';
}

fn bool validate_project_root()
{
    bool valid = true;

    if (!file::exists(PROJECT_FILE))
    {
        io::printfn("No %s found in the current directory.", PROJECT_FILE);
        valid = false;
    }

    if (!file::exists(GAME_SRC_DIR))
    {
        io::printfn("No %s directory found in the current directory.", GAME_SRC_DIR);
        valid = false;
    }

    if (!file::exists(HOST_SRC_DIR))
    {
        io::printfn("No %s directory found in the current directory.", HOST_SRC_DIR);
        valid = false;
    }

    if (!valid)
    {
        io::printn("Are you running this from the project root?");
    }
    else
    {
        io::printn("Project root validated.");
    }

    return valid;
}
