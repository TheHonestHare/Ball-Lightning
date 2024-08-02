const std = @import("std");
const sprite = @import("sprite/main.zig");
const materials = @import("sprite/material.zig");

pub fn init(ally: std.mem.Allocator) !std.ArrayListUnmanaged(materials.Material) {
    var mat_list = materials.makeMatList();
    _ = try materials.createMaterial(ally, &mat_list, .{ .atlas_pos = .{ 0, 0 }, .atlas_dims = .{ 5, 7 } });

    return mat_list;
}
