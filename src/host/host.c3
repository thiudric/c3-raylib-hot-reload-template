<*
 host.c3 owns application and persistent game memory.
 game logic lives in a shared library loaded at runtime
*>
module host;
import std::io;
import std::time;
import std::io::path;
import libc;
const MEM_BUFFER_SIZE  = 1024;
const MAX_RETIRED_LIBS = 64;
const GAME_BUILD_PATH  = "./build/game_ready.so";
const HOT_LIB_PATH     = "./build/hot/";

extern fn ZString dlerror();

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
	Time last_game_modified = file::last_modified(GAME_BUILD_PATH)!!;
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
	while (game_lib.should_run())
	{
		game_lib.tick();

		Time modified_time     = file::last_modified(GAME_BUILD_PATH)!!;
		bool was_modified      = modified_time != last_game_modified;
		bool force_state_reset = game_lib.reload_requested();
		if (was_modified || force_state_reset)
		{
			last_game_modified = modified_time;
			io::printn("reload required");
			if (!reload_latest_lib(&game_lib, &arena, force_state_reset))
			{
				io::printn("reload failed; keeping current game");
			}
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
