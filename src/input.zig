const std = @import("std");
const glfw = @import("zglfw");

pub const Key = glfw.Key;
pub var keys: std.EnumArray(glfw.Key, bool) = std.EnumArray(glfw.Key, bool).initFill(false);
pub fn keyCallback(window: *glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) callconv(.C) void {
    _ = window;
    _ = mods;
    _ = scancode;
    switch (action) {
        .press => {
            @atomicStore(bool, keys.getPtr(key), true, .monotonic);
        },
        .release => {
            @atomicStore(bool, keys.getPtr(key), false, .monotonic);
        },
        .repeat => {},
    }
}
