const std = @import("std");
const glfw = @import("zglfw");

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();
    
    glfw.windowHintTyped(.client_api, .no_api);

    const window = try glfw.Window.create(800, 600, "Hello lads", null);
    defer window.destroy();
    // TODO: window.setSizeLimits()

    while(!window.shouldClose()) {
        glfw.pollEvents();
        window.swapBuffers();
    }

}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
