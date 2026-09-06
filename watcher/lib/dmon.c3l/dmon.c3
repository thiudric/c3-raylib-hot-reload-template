module dmon;

struct WatchId {
    uint id;
}

constdef Action: int {
    CREATE = 1,
    DELETE = 2,
    MODIFY = 3,
    MOVE = 4,
}

constdef WatchFlags : uint {
    RECURSIVE = 0x1,
    FOLLOW_SYMLINKS = 0x2,
    OUTOFSCOPE_LINKS = 0x4,
}

alias WatchCallback = fn void(
    WatchId watch_id,
    Action action,
    ZString rootdir,
    ZString filepath,
    ZString oldfilepath,
    void* user
);

extern fn void init() @cname("dmon_init");
extern fn void deinit() @cname("dmon_deinit");
extern fn WatchId watch(ZString rootdir, WatchCallback callback, WatchFlags flags, void* user_data) @cname("dmon_watch");
extern fn void unwatch(WatchId watch_id) @cname("dmon_unwatch");
