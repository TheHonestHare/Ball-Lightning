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