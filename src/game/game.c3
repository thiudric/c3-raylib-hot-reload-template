<*
 game.c3 owns game logic and is compiled into a reloadable shared library.
 each new library version points at the same memory.
*>
module game;
import std::io;
import std::core::mem::alloc;
import raylib6::rl;
import raygui::rg;

// state that persists between hot reloads
struct GameMem
{
	Allocator allocator;
	int counter;
}

GameMem* game_mem;

// game tick called every frame. edit this for your game logic
fn void tick() @export("game_tick")
{
	rl::begin_drawing();
	rl::clear_background(rl::GREEN);
	rl::draw_text("Hello C3 Raylib Hot Reload Template!", 10, 10, 20, rl::BLACK);

	if (rg::button({ 400 - 90, 300 - 20, 180, 40 }, "Click me!") != 0)
	{
		io::printn("raygui works!");
	}
	rl::end_drawing();
}

// called when game starts. edit this for set up logic.
fn void init_window() @export("game_init_window")
{
	rl::init_window(800, 600, "Game Window");
	rl::set_target_fps(60);
}

// called when game shuts down. edit this for clean up logic.
fn void shutdown() @export("game_shutdown")
{
	rl::close_window();
}

<*
 using the memory supplied by the host, allocate initial game state
 the game only uses allocation interface and doesn't actually care if its an arena or not
*>
fn void init_mem(ArenaAllocator* arena) @export("game_init_mem")
{
	// Construct the Allocator interface inside this DLL. Passing an interface
	// across the DLL boundary breaks C3's runtime method dispatch on Windows.
	game_mem = alloc::new(arena, GameMem);
	game_mem.allocator = arena;
}

fn bool should_run() @export("game_should_run")
{
	return !rl::window_should_close();
}

// return current state pointer.  The host owns the backing memory.
fn void* mem() @export("game_mem")
{
	return game_mem;
}

// return memory size
fn usz mem_size() @export("game_mem_size")
{
	return GameMem::size;
}

fn bool reload_requested() @export("game_reload_requested")
{
	return rl::is_key_pressed(F5);
}

<* point this library version at state created in a prior version. *>
fn void reload_mem(void* new_mem) @export("game_reload_mem")
{
	game_mem = (GameMem*)new_mem;
}
