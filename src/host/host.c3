<*
 host.c3 owns application and persistent game memory.
 game logic lives in a shared library loaded at runtime
*>
module host;
import std::io;
import std::time;
import std::io::path;
const MEM_BUFFER_SIZE       = 1024;
const MAX_RETIRED_LIBS      = 64;
const DYNAMIC_LIB_EXTENSION = env::WIN32 ? ".dll" : ".so";
const GAME_BUILD_PATH       = env::WIN32 ? "./build/game.dll" : "./build/game.so";
const HOT_LIB_MASK          = env::WIN32 ? "game*.dll" : "game*.so";
const HOT_LIB_PATH          = "./build/hot/";

uint next_lib_id;
GameLib[MAX_RETIRED_LIBS] retired_libs;
usz retired_lib_count;

fn void main()
{
	if (!file::exists(GAME_BUILD_PATH))
	{
		io::printfn("%s does not exist; build the game first", GAME_BUILD_PATH);
		return;
	}
	Time? initial_modified = file::last_modified(GAME_BUILD_PATH);
	if (catch err = initial_modified)
	{
		io::printfn("error reading game library timestamp: %s", err);
		return;
	}
	Time last_game_modified = initial_modified;
	if (catch err = cleanup_hot_libs())
	{
		io::printfn("error cleaning up hot libs: %s", err);
		return;
	}
	next_lib_id = 0;

	// initialize arena memory
	char[MEM_BUFFER_SIZE] buffer;
	ArenaAllocator arena;
	arena.init(&buffer);

	GameLib game_lib;
	if (!load_game_lib(&game_lib))
	{
		return;
	}

	// initialize game memory after window
	game_lib.init_window();
	game_lib.init_mem(&arena);
	bool force_state_reset = false;
	while (game_lib.should_run())
	{
		game_lib.tick();

		// Preserve a reset request if publishing temporarily prevents a reload.
		bool reset_requested = game_lib.reload_requested();
		force_state_reset = force_state_reset || reset_requested;
		Time? modified_result = file::last_modified(GAME_BUILD_PATH);
		if (catch err = modified_result)
		{
			// Keep the loaded game running while the published file is unavailable.
			continue;
		}
		Time modified_time = modified_result;
		bool was_modified  = modified_time != last_game_modified;
		if (was_modified || force_state_reset)
		{
			io::printn("reload required");
			if (!reload_latest_lib(&game_lib, &arena, force_state_reset))
			{
				io::printn("reload failed; keeping current game");
				continue;
			}
			last_game_modified = modified_time;
			force_state_reset = false;
		}
	}
	game_lib.shutdown();
	unload_retired_libs();
	unload_game_lib(&game_lib);

	if (catch err = cleanup_hot_libs())
	{
		io::printfn("error cleaning up hot libs: %s", err);
		return;
	}
}
