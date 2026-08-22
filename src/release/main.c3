<*
 Non-hot-reload entry point used for release builds.

 This file uses the game module so it can call the same functions that are
 exported to the development host.
*>
module game;

const RELEASE_MEMORY_SIZE = 1024;

fn void main()
{
	char[RELEASE_MEMORY_SIZE] buffer;
	ArenaAllocator arena;
	arena.init(&buffer);

	init_window();
	init_mem(&arena);

	while (should_run())
	{
		tick();
	}

	shutdown();
}
