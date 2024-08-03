const std = @import("std");
const glfw = @import("zglfw");
const zgpu = @import("zgpu");
const wgpu = zgpu.wgpu;
const zm = @import("zmath");
const render = @import("render.zig");
const input = @import("input.zig");

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    glfw.windowHintTyped(.client_api, .no_api);

    const window = try glfw.Window.create(800, 600, "Hello lads", null);
    defer window.destroy();
    // TODO: window.setSizeLimits()
    _ = window.setKeyCallback(input.keyCallback);
    var waitForWindow: std.Thread.ResetEvent = .{};
    waitForWindow.reset();
    const render_thread = try std.Thread.spawn(.{}, renderLoop, .{ window, &waitForWindow });
    render_thread.detach();

    waitForWindow.wait();
    var timer = try std.time.Timer.start();
    var title_buf: [64]u8 = undefined;
    while (!window.shouldClose()) {
        glfw.pollEvents();
        if (timer.read() > std.time.ns_per_s) {
            timer.reset();
            window.setTitle(std.fmt.bufPrintZ(&title_buf, "{d}", .{FPS.swap(0, .acq_rel)}) catch unreachable);
        }
    }
}

var FPS: std.atomic.Value(u64) = .{ .raw = 0 };

fn renderLoop(window: *glfw.Window, window_reset: *std.Thread.ResetEvent) !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var state = try render.init(allocator, window);
    defer state.deinit(allocator);
    const scene_state = try render.SceneState.init(state, allocator);
    window_reset.set();
    while (true) {
        render.draw(state, scene_state);
        _ = FPS.rmw(.Add, 1, .monotonic);
    }
}
