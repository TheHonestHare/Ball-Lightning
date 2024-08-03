const std = @import("std");
const glfw = @import("zglfw");
const zgpu = @import("zgpu");
const sprite = @import("sprite/main.zig");
const camera = @import("camera.zig");
const object = @import("object.zig");
const mat = @import("sprite/material.zig");
const wgpu = zgpu.wgpu;

pub const Bind = struct {
    bindnum: u32,
    entry_layout: zgpu.wgpu.BindGroupLayoutEntry,
    entry: zgpu.BindGroupEntryInfo,
};

pub const Group = struct {
    layout: zgpu.BindGroupLayoutHandle,
    bindgroup: zgpu.BindGroupHandle,

    pub fn deinit(self: @This(), gctx: *zgpu.GraphicsContext) void {
        gctx.releaseResource(self.layout);
        gctx.releaseResource(self.bindgroup);
    }
};

pub const RenderGlobals = struct {
    gctx: *zgpu.GraphicsContext,
    sprite_state: sprite.RenderState,
    camera_group: Group,
    pub fn deinit(state: RenderGlobals, ally: std.mem.Allocator) void {
        // TODO: is this neccesary except last
        state.camera_group.deinit(state.gctx);
        state.sprite_state.deinit(state.gctx);
        state.gctx.destroy(ally);
    }
};

pub const SceneState = struct {
    object: object.State,
    sprite: sprite.SceneState,
    // TODO: how important is actually keeping this around vs just free
    all_mats: std.ArrayListUnmanaged(mat.Material),

    pub fn init(globals: RenderGlobals, ally: std.mem.Allocator) !SceneState {
        // TODO: extract creating the levels into somewher else
        const init_lvl = @import("level1.zig").init(ally) catch @panic("TODO");
        const obj_state = try object.init(init_lvl.solids, init_lvl.player, ally);
        const sprite_state = try sprite.SceneState.init(globals.gctx, obj_state, ally, init_lvl.all_mats, globals.sprite_state.bindgroup_layout);
        return .{
            .object = obj_state,
            .sprite = sprite_state,
            .all_mats = init_lvl.all_mats,
        };
    }
    pub fn deinit(self: @This()) void {
        _ = self;
        @compileError("TODO");
    }
};

pub fn init(ally: std.mem.Allocator, window: *glfw.Window) !RenderGlobals {
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

    const camera_group = camera.init(gctx);
    const sprite_state = try sprite.initRender(gctx, ally, camera_group.layout);

    return .{
        .gctx = gctx,
        .sprite_state = sprite_state,
        .camera_group = camera_group,
    };
}

pub fn draw(state: RenderGlobals, scene: SceneState) void {
    const back_buffer_view = state.gctx.swapchain.getCurrentTextureView();
    defer back_buffer_view.release();

    const camera_offs = camera.gpuUpdate(state.gctx, camera.positionCamera(sprite.height_in_units, 0, 0));
    const commands = commands: {
        const encoder = state.gctx.device.createCommandEncoder(null);
        defer encoder.release();
        scene.sprite.draw(state.gctx, state, encoder, back_buffer_view, camera_offs);
        break :commands encoder.finish(null);
    };
    defer commands.release();
    state.gctx.submit(&.{commands});
    _ = state.gctx.present();
}
