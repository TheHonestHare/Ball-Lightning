const std = @import("std");
const glfw = @import("zglfw");
const zgpu = @import("zgpu");
const sprite = @import("sprite/main.zig");
const camera = @import("camera.zig");
const wgpu = zgpu.wgpu;

pub const Bind = struct {
    bindnum: u32,
    entry_layout: zgpu.wgpu.BindGroupLayoutEntry,
    entry: zgpu.BindGroupEntryInfo,
};

pub const Group = struct {
    layout: zgpu.BindGroupLayoutHandle,
    bindgroup: zgpu.BindGroupHandle,
};

pub const RenderState = struct {
    gctx: *zgpu.GraphicsContext,
    sprite_state: sprite.State,
    camera_group: Group,
};

pub fn init(ally: std.mem.Allocator, window: *glfw.Window) !RenderState {
    const gctx = try zgpu.GraphicsContext.create(ally, .{
        .window = window,
        .fn_getTime = @ptrCast(&glfw.getTime),
        .fn_getFramebufferSize = @ptrCast(&glfw.Window.getFramebufferSize),
        .fn_getWin32Window = @ptrCast(&glfw.getWin32Window),
        .fn_getX11Display = @ptrCast(&glfw.getX11Display),
        .fn_getX11Window = @ptrCast(&glfw.getX11Window),
        .fn_getWaylandDisplay = @ptrCast(&glfw.getWaylandDisplay),
        .fn_getWaylandSurface = @ptrCast(&glfw.getWaylandWindow),
        .fn_getCocoaWindow = @ptrCast(&glfw.getCocoaWindow),
    }, .{ .present_mode = .mailbox });
    errdefer gctx.destroy(ally);

    const level1mats = try @import("level1.zig").init(ally);
    const camera_group = camera.init(gctx);
    const sprite_state = try sprite.initRender(gctx, ally, camera_group.layout, 100, level1mats);

    return .{
        .gctx = gctx,
        .sprite_state = sprite_state,
        .camera_group = camera_group,
    };
}

pub fn deinit(ally: std.mem.Allocator, state: *RenderState) void {
    state.gctx.destroy(ally);
}

pub fn draw(state: RenderState) void {
    const back_buffer_view = state.gctx.swapchain.getCurrentTextureView();
    defer back_buffer_view.release();

    const camera_offs = camera.gpuUpdate(state.gctx, camera.positionCamera(sprite.height_in_units, 0, 0));
    const commands = commands: {
        const encoder = state.gctx.device.createCommandEncoder(null);
        defer encoder.release();
        sprite.draw(state.gctx, state, encoder, back_buffer_view, camera_offs);
        break :commands encoder.finish(null);
    };
    defer commands.release();
    state.gctx.submit(&.{commands});
    _ = state.gctx.present();
}
