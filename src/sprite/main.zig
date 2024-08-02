const std = @import("std");
const zgpu = @import("zgpu");
const wgpu = zgpu.wgpu;
const zm = @import("zmath");
const render = @import("../render.zig");
const mat = @import("material.zig");

pub const height_in_units = 128;
/// 1 unit is 1/128th of the height of the screen
pub const Pos = extern struct {
    x: f32,
    y: f32,
    scale: f32,
    material: u32,
    comptime {
        const posarray: *allowzero [2]Pos = @ptrFromInt(0);
        std.debug.assert(@intFromPtr(&posarray[1].x) == @sizeOf(Pos)); // stride
        std.debug.assert(@sizeOf(Pos) == 16);
    }
};

pub const State = struct {
    sprite_count: u32,
    pipeline: zgpu.RenderPipelineHandle,
    bindgroup: zgpu.BindGroupHandle,
    pos_buff: zgpu.BufferHandle,
    material_buff: zgpu.BufferHandle,
};

pub const bind_nums: struct { pos: u32, mat: u32, sprite_sheet: u32 } = .{
    .pos = 0,
    .mat = 1,
    .sprite_sheet = 2,
};

pub fn initRender(gctx: *zgpu.GraphicsContext, ally: std.mem.Allocator, camera_bindgroup: zgpu.BindGroupLayoutHandle, sprite_count: u32, mat_list: std.ArrayListUnmanaged(mat.Material)) !State {
    const mat_state = try mat.initRender(gctx, ally, bind_nums.sprite_sheet);
    const bindgroup_layout = gctx.createBindGroupLayout(&.{
        zgpu.bufferEntry(bind_nums.pos, .{ .vertex = true }, .read_only_storage, false, 0),
        zgpu.bufferEntry(bind_nums.mat, .{ .fragment = true, .vertex = true }, .read_only_storage, false, 0),
        mat_state.sprite_sheet_bind.entry_layout,
    });
    defer gctx.releaseResource(bindgroup_layout);
    const pipeline_layout = gctx.createPipelineLayout(&.{ bindgroup_layout, camera_bindgroup });
    defer gctx.releaseResource(pipeline_layout);
    const shadersource = @embedFile("spriteshaders.wgsl");
    const pipeline = pipeline: {
        const vs_module = zgpu.createWgslShaderModule(gctx.device, shadersource, "vs");
        defer vs_module.release();

        const fs_module = zgpu.createWgslShaderModule(gctx.device, shadersource, "fs");
        defer fs_module.release();

        const color_targets = [_]wgpu.ColorTargetState{.{
            .blend = &.{
                .color = .{
                    .src_factor = .one,
                    .dst_factor = .one_minus_src_alpha,
                },
                .alpha = .{
                    .src_factor = .one,
                    .dst_factor = .one_minus_src_alpha,
                },
            },
            .format = zgpu.GraphicsContext.swapchain_format,
        }};

        const pipeline_desc: wgpu.RenderPipelineDescriptor = .{
            .vertex = .{
                .entry_point = "vert_main",
                .module = vs_module,
            },
            .fragment = &.{
                .entry_point = "frag_main",
                .module = fs_module,
                .targets = &color_targets,
                .target_count = color_targets.len,
            },
            .primitive = .{
                .cull_mode = .back, // TODO: change
                .front_face = .ccw, // TODO: change
                .strip_index_format = .uint32,
                .topology = .triangle_strip,
            },
        };
        break :pipeline gctx.createRenderPipeline(pipeline_layout, pipeline_desc);
    };

    const pos_buff = gctx.createBuffer(.{
        .usage = .{
            .copy_dst = true,
            .storage = true,
        },
        .mapped_at_creation = true,
        .size = @sizeOf(Pos) * sprite_count,
    });
    const material_buff = gctx.createBuffer(.{
        .usage = .{
            .copy_dst = true,
            .storage = true,
        },
        .mapped_at_creation = true,
        .size = mat_list.items.len * @sizeOf(mat.Material), // TODO: probably not correct
    });
    const pos_gpu_buffer = gctx.lookupResource(pos_buff).?;
    fillPos(pos_gpu_buffer.getMappedRange(Pos, 0, sprite_count).?);
    // TODO: fill buffer
    pos_gpu_buffer.unmap();
    // TODO: maybe move this to material.zig?
    const material_buffer = gctx.lookupResource(material_buff).?;
    @memcpy(material_buffer.getMappedRange(mat.Material, 0, mat_list.items.len).?, mat_list.items);
    // TODO: fill buffer
    material_buffer.unmap();

    const bindgroup = gctx.createBindGroup(bindgroup_layout, &.{
        .{
            .binding = bind_nums.pos,
            .buffer_handle = pos_buff,
            .offset = 0,
            .size = @sizeOf(Pos) * sprite_count,
        },
        .{
            .binding = bind_nums.mat,
            .buffer_handle = material_buff,
            .offset = 0,
            .size = @sizeOf(mat.Material) * mat_list.items.len,
        },
        mat_state.sprite_sheet_bind.entry,
    });

    return .{ .sprite_count = sprite_count, .pipeline = pipeline, .bindgroup = bindgroup, .pos_buff = pos_buff, .material_buff = material_buff };
}
fn fillPos(pos_buffer: []Pos) void {
    var thing = std.Random.DefaultPrng.init(@bitCast(std.time.timestamp()));
    const rand = thing.random();
    for (pos_buffer) |*pos| {
        pos.* = .{
            .x = (rand.float(f32) - 0.5) * height_in_units,
            .y = (rand.float(f32) - 0.5) * height_in_units,
            .scale = 5,
            .material = 0, // TODO:
        };
    }
}

pub fn draw(gctx: *zgpu.GraphicsContext, state: render.RenderState, encoder: wgpu.CommandEncoder, screen_view: wgpu.TextureView, camera_offs: @import("../camera.zig").CameraUniformOffsets) void {
    const pipeline = gctx.lookupResource(state.sprite_state.pipeline) orelse return;
    const sprite_bindgroup = gctx.lookupResource(state.sprite_state.bindgroup) orelse return;
    const camera_bindgroup = gctx.lookupResource(state.camera_group.bindgroup) orelse return;
    const renderpass = renderpass: {
        const color_attachments = [_]wgpu.RenderPassColorAttachment{.{
            .view = screen_view,
            .load_op = .clear,
            .store_op = .store,
            .clear_value = .{.r = 0.5, .g = 0, .b = 0, .a = 1},
        }};
        // const depth_attachment = wgpu.RenderPassDepthStencilAttachment{
        //     .view = depth_view,
        //     .depth_load_op = .clear,
        //     .depth_store_op = .store,
        //     .depth_clear_value = 1.0,
        // };
        const render_pass_info = wgpu.RenderPassDescriptor{
            .color_attachment_count = color_attachments.len,
            .color_attachments = &color_attachments,
            //.depth_stencil_attachment = &depth_attachment,
        };
        break :renderpass encoder.beginRenderPass(render_pass_info);
    };
    defer {
        renderpass.end();
        renderpass.release();
    }
    renderpass.setPipeline(pipeline);
    renderpass.setBindGroup(0, sprite_bindgroup, null);
    renderpass.setBindGroup(1, camera_bindgroup, &.{ camera_offs.mat, camera_offs.asp_rat });
    renderpass.draw(4, state.sprite_state.sprite_count, 0, 0);
}