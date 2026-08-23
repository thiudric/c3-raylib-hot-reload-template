module host;
import std::io;
import std::time;
import std::io::path;

// startup
alias InitMemFn = fn void(ArenaAllocator*);
alias InitWindowFn = fn void();
// main loop
alias ShouldRunFn = fn bool();
alias TickFn = fn void();
alias ReloadRequestedFn = fn bool();
// hot reload
alias MemFn = fn void*();
alias MemSizeFn = fn usz();
alias ReloadMemFn = fn void(void*);
// shutdown
alias ShutdownFn = fn void();

<*
 Functions exported by the reloadable game shared library.
 Only the current active GameLib functions should be called.
*>
struct GameLib
{
	void* handle;

	InitMemFn init_mem;
	InitWindowFn init_window;

	ShouldRunFn should_run;
	TickFn tick;
	ReloadRequestedFn reload_requested;

	MemFn mem;
	MemSizeFn mem_size;
	ReloadMemFn reload_mem;

	ShutdownFn shutdown;
}

<*
 Replaces the active game library with a newly built version.
 Decides whether to preserve the old memory state or reset the arena.
 When old memory state is preserved, old libraries are retired instead of deleting incase they may still be referenced.
*>
fn bool reload_latest_lib(GameLib* active_lib, ArenaAllocator* arena, bool force_state_reset = false)
{
	GameLib new_lib;

	if (!load_game_lib(&new_lib))
	{
		return false;
	}

	// Compare memory sizes to determine if a state reset is needed.
	// currently we only check size for compatibility which can be a limitation
	// a manual reset may be required if the size check isn't sufficient.
	usz old_mem_size = active_lib.mem_size();
	usz new_mem_size = new_lib.mem_size();

	io::printfn("old memory size: %s, new memory size: %s", old_mem_size, new_mem_size);

	bool should_reset_state = force_state_reset || old_mem_size != new_mem_size
		|| retired_lib_count >= MAX_RETIRED_LIBS;

	if (should_reset_state)
	{
		io::printn("reload with fresh state");

		// Old persistent state is no longer valid.
		arena.clear();

		// Initialize fresh state using the new library.
		new_lib.init_mem(arena);

		// Swap the active library.
		GameLib old_lib = *active_lib;
		*active_lib = new_lib;

		// Safe to unload old libraries now that old state is gone.
		unload_game_lib(&old_lib);
		unload_retired_libs();
	}
	else
	{
		io::printn("reload without fresh state");

		// Preserve persistent state.
		void* mem = active_lib.mem();

		// Point the new game library at that state.
		new_lib.reload_mem(mem);

		// Keep the old library mapped in case persistent state
		// still contains pointers into it.
		if (!retire_game_lib(active_lib))
		{
			io::printn("failed to retire old lib");
			unload_game_lib(&new_lib);
			return false;
		}

		// New library becomes active.
		*active_lib = new_lib;
	}

	return true;
}

fn void unload_retired_libs()
{
	for (usz i = 0; i < retired_lib_count; i++)
	{
		unload_game_lib(&retired_libs[i]);
	}
	retired_lib_count = 0;
}

fn void? cleanup_hot_libs() => @pool()
{
	Path hot_dir = path::tnew(HOT_LIB_PATH)!;
	if (!path::exists(hot_dir))
	{
		return;
	}
	io::printfn("cleaning up hot libs in %s", hot_dir);
	PathList libs = path::ls(tmem, hot_dir, no_dirs: true, mask: HOT_LIB_MASK)!;

	foreach (lib : libs)
	{
		io::printfn("deleting stale hot lib: %s", lib);
		Path full_path = hot_dir.tappend((String)lib)!;
		path::delete(full_path)!;
	}
}

<*
 Transfers ownership of a GameLib to the retired list.
 The library is still loaded but no longer the active lib.
*>
fn bool retire_game_lib(GameLib* lib)
{
	if (retired_lib_count < MAX_RETIRED_LIBS)
	{
		retired_libs[retired_lib_count] = *lib;
		*lib = { };
		retired_lib_count += 1;
		return true;
	}
	return false;
}

// preserve type safety with a macro
// pass the same name as the game lib export
macro bool @load_lib_fn(void* handle, #fn_ptr)
{
	ZString fn_name = $stringify(#fn_ptr);
	void* sym = dynamic_library_symbol(handle, fn_name);
	if (sym == null)
	{
		return false;
	}
	#fn_ptr = ($Typeof(#fn_ptr))sym;
	return true;
}

<*
 Copies the game library to a temporary path and loads it.

 a new path is used to avoid conflicts with the existing library.
*>
fn bool load_game_lib(GameLib* lib) => @pool()
{
	String lib_path = get_next_temp_lib_path();

	if (catch err = copy_game_lib(GAME_BUILD_PATH, lib_path))
	{
		io::printfn("failed to copy game library from %s to %s: %s", GAME_BUILD_PATH, lib_path, err);
		return false;
	}

	io::printfn("copied game library to %s", lib_path);

	void* handle = dynamic_library_open(lib_path.zstr_tcopy());
	if (handle == null)
	{
		return false;
	}

	InitMemFn game_init_mem;
	ReloadMemFn game_reload_mem;
	TickFn game_tick;
	MemFn game_mem;
	MemSizeFn game_mem_size;
	ShutdownFn game_shutdown;
	InitWindowFn game_init_window;
	ShouldRunFn game_should_run;
	ReloadRequestedFn game_reload_requested;

	if (!@load_lib_fn(
		handle,
		game_reload_requested
	) || !@load_lib_fn(
		handle,
		game_init_mem
	) || !@load_lib_fn(
		handle,
		game_reload_mem
	) || !@load_lib_fn(
		handle,
		game_tick
	) || !@load_lib_fn(
		handle,
		game_mem
	) || !@load_lib_fn(
		handle,
		game_mem_size
	) || !@load_lib_fn(
		handle,
		game_shutdown
	) || !@load_lib_fn(handle, game_init_window) || !@load_lib_fn(handle, game_should_run))
	{
		dynamic_library_close(handle);
		return false;
	}
	lib.handle = handle;
	lib.init_mem = game_init_mem;
	lib.reload_mem = game_reload_mem;
	lib.tick = game_tick;
	lib.mem = game_mem;
	lib.mem_size = game_mem_size;
	lib.shutdown = game_shutdown;
	lib.init_window = game_init_window;
	lib.should_run = game_should_run;
	lib.reload_requested = game_reload_requested;
	io::printn("game lib loaded");
	return true;
}

fn void unload_game_lib(GameLib* lib)
{
	if (lib.handle != null)
	{
		dynamic_library_close(lib.handle);
		io::printn("game lib unloaded");
	}
	*lib = { };
}

// stores next game lib in temp allocator
fn String get_next_temp_lib_path()
{
	String versioned_path = string::tformat("%sgame_%06d%s", HOT_LIB_PATH, next_lib_id, DYNAMIC_LIB_EXTENSION);
	next_lib_id += 1;
	io::printfn("lib path: %s", versioned_path);
	return versioned_path;
}

fn void? copy_game_lib(String from, String to)
{
	io::printfn("copying %s to %s", from, to);
	if (!file::exists(from))
	{
		io::printfn("source file does not exist: %s", from);
		return io::FILE_NOT_FOUND~;
	}
	if (!file::is_dir("build/hot"))
	{
		path::mkdir("build/hot", recursive: true)!;
	}
	File source = file::open(from, "rb")!;
	defer source.close();
	File dest = file::open(to, "wb")!;
	defer dest.close();
	io::copy_to(&source, &dest)!;
}
