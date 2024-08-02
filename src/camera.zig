const std = @import("std");
const zgpu = @import("zgpu");
const wgpu = zgpu.wgpu;
const zm = @import("zmath");
const Group = @import("render.zig").Group;

pub fn init(gctx: *zgpu.GraphicsContext) Group {
    const bindgroup_layout = gctx.createBindGroupLayout(&.{
        zgpu.bufferEntry(0, .{ .vertex = true }, .uniform, true, 0),
        zgpu.bufferEntry(1, .{ .vertex = true }, .uniform, true, 0),
    });

    const bindgroup = gctx.createBindGroup(bindgroup_layout, &.{ .{
        .binding = 0,
        .buffer_handle = gctx.uniforms.buffer,
        .offset = 0,
        .size = @sizeOf(zm.Mat),
    }, .{
        .binding = 1,
        .buffer_handle = gctx.uniforms.buffer,
        .offset = 0,
        .size = @sizeOf(f32),
    } });

    return .{
        .layout = bindgroup_layout,
        .bindgroup = bindgroup,
    };
}

fn @"f32"(in: u32) f32 {
    return @floatFromInt(in);
}

/// view_dim should be height of the viewport in units, starts off by giving square camera and aspect ratio happens in vs
pub fn positionCamera(view_dim: u32, x: f32, y: f32) zm.Mat {
    return zm.orthographicOffCenterRhGl(
        x - @"f32"(view_dim) / 2,
        x + @"f32"(view_dim) / 2,
        y + @"f32"(view_dim) / 2,
        y - @"f32"(view_dim) / 2,
        -1.0,
        1.0,
    );
}
pub const CameraUniformOffsets = struct { mat: u32, asp_rat: u32 };
// returns offset for camera matrix, then the aspect ratio
pub fn gpuUpdate(gctx: *zgpu.GraphicsContext, mat: zm.Mat) CameraUniformOffsets {
    const mem = gctx.uniformsAllocate(zm.Mat, 1);
    mem.slice[0] = mat;
    const mem2 = gctx.uniformsAllocate(f32, 1);
    mem2.slice[0] = @"f32"(gctx.swapchain_descriptor.width) / @"f32"(gctx.swapchain_descriptor.height);
    return .{
        .mat = mem.offset,
        .asp_rat = mem2.offset,
    };
}
