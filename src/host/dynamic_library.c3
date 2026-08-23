module host;

import std::io;
import std::os::win32;
import libc;

extern fn ZString dlerror() @link("dl") @feat(!WIN32);

fn void* dynamic_library_open(ZString path) @feat(WIN32)
{
	void* handle = win32::loadLibraryA((Win32_LPCSTR)path);
	if (handle == null)
	{
		io::printfn("LoadLibrary failed for %s (Windows error %s)", path, win32::getLastError());
	}
	return handle;
}

fn void* dynamic_library_open(ZString path) @feat(!WIN32)
{
	void* handle = libc::dlopen(path, libc::RTLD_NOW);
	if (handle == null)
	{
		io::printfn("dlopen failed for %s: %s", path, dlerror());
	}
	return handle;
}

fn void* dynamic_library_symbol(void* handle, ZString name) @feat(WIN32)
{
	void* symbol = win32::getProcAddress(handle, (Win32_LPCSTR)name);
	if (symbol == null)
	{
		io::printfn("GetProcAddress failed for %s (Windows error %s)", name, win32::getLastError());
	}
	return symbol;
}

fn void* dynamic_library_symbol(void* handle, ZString name) @feat(!WIN32)
{
	// POSIX requires clearing the previous error before checking dlsym.
	dlerror();
	void* symbol = libc::dlsym(handle, name);
	ZString error = dlerror();
	if (error != null)
	{
		io::printfn("dlsym failed for %s: %s", name, error);
		return null;
	}
	return symbol;
}

fn void dynamic_library_close(void* handle) @feat(WIN32)
{
	if (!win32::freeLibrary(handle))
	{
		io::printfn("FreeLibrary failed (Windows error %s)", win32::getLastError());
	}
}

fn void dynamic_library_close(void* handle) @feat(!WIN32)
{
	if (libc::dlclose(handle) != 0)
	{
		io::printfn("dlclose failed: %s", dlerror());
	}
}
