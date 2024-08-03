const std = @import("std");
const sprite = @import("sprite/main.zig");
const materials = @import("sprite/material.zig");
const object = @import("object.zig");

pub const Outs = struct {
    all_mats: std.ArrayListUnmanaged(materials.Material),
    solids: []const object.Common,
    player: object.Common,
};

pub fn init(ally: std.mem.Allocator) !Outs {
    var mat_list = materials.makeMatList();
    const mat0 = try materials.createMaterial(ally, &mat_list, .{ .atlas_pos = .{ 0, 0 }, .atlas_dims = .{ 5, 7 } });
    const mat1 = try materials.createMaterial(ally, &mat_list, .{ .atlas_pos = .{ 11, 0 }, .atlas_dims = .{ 9, 7 } });
    
    const solid = @as(object.Common, .{
        .material = mat0,
        .pos = .{
            .x = 40,
            .y = 0,
        },
        .scale = 1,
    }).useConstantScale(mat_list, 4);
    const player = @as(object.Common, .{
        .material = mat1,
        .pos = .{
            .x = 0,
            .y = 0,
        },
        .scale = 1,
    }).useConstantScale(mat_list, 4);
    std.debug.print("{d}",.{mat1});
    return .{
        .all_mats = mat_list,
        .solids = &.{solid},
        .player = player,
    };
}
