const std = @import("std");
const mat = @import("sprite/material.zig");
const sprite = @import("sprite/main.zig");

pub const Pos = struct {
    x: f32,
    y: f32,
};
pub const Acc = struct {
    x: f32,
    y: f32,
    pub const ZERO: Acc = .{ .x = 0, .y = 0 };
};
pub const HitBoxInfo = struct {
    width: f32,
    height: f32,
};
pub const Vel = struct {
    x: f32,
    y: f32,
    pub const ZERO: Vel = .{ .x = 0, .y = 0 };
};
pub const Moveable = struct {
    lastPos: Pos,
    vel: Vel,
    acc: Acc,
};
pub const Common = struct {
    pos: Pos,
    hit: ?HitBoxInfo = null,
    material: u32,
    /// the resulting sprites x in units will be scaled by this (y changed according to its aspect ratio)
    scale: f32 = 1,

    /// returns a sprite using 1 atlas pixel = `constant_scale` units
    pub fn useConstantScale(self: @This(), mat_list: std.ArrayListUnmanaged(mat.Material), constant_scale: f32) @This() {
        var self_mut = self;
        const atlas_dims = mat_list.items[self.material].atlas_dims;
        // scale by x axis
        self_mut.scale = @as(f32, @floatFromInt(atlas_dims[0])) * constant_scale;
        return self_mut;
    }
    /// the resulting sprites hitbox will be consistent with what its sprite appears like on screen (without respect to transparency)
    pub fn consistentHitbox(self: @This(), mat_list: std.ArrayListUnmanaged(mat.Material)) @This() {
        var self_mut = self;
        const atlas_dims = mat_list.items[self.material].atlas_dims;
        // dims.y / dims.x
        const dim_ratio = @as(f32, @floatFromInt(atlas_dims[1])) / @as(f32, @floatFromInt(atlas_dims[0]));
        self_mut.hit = .{
            .width = self.scale,
            .height = self.scale * dim_ratio,
        };
        return self_mut;
    }
};

pub const Player = struct {
    common: Common,
    moveable: Moveable,
};

pub const State = struct {
    solids: std.MultiArrayList(Common),
    player: Player,
    pub fn getVisibleObjectCount(self: @This()) u32 {
        // solids + player
        return @intCast(self.solids.len + 1);
    }
    /// returns how long into the buffer should actually be rendered
    pub fn fillGPUPosBuff(self: @This(), buff: []sprite.Pos) u32 {
        std.debug.assert(self.getVisibleObjectCount() == buff.len);
        const solidslice = self.solids.slice();
        for (0.., solidslice.items(.pos), solidslice.items(.scale), solidslice.items(.material)) |i, pos, scale, material| {
            buff[i] = .{ .x = pos.x, .y = pos.y, .scale = scale, .material = material };
        }
        buff[buff.len - 1] = .{
            .x = self.player.common.pos.x,
            .y = self.player.common.pos.y,
            .scale = self.player.common.scale,
            .material = self.player.common.material,
        };
        return @intCast(buff.len);
    }
};

pub fn init(solids: []const Common, player: Common, ally: std.mem.Allocator) !State {
    var solids_final: std.MultiArrayList(Common) = .{};
    try solids_final.resize(ally, solids.len);
    for (solids, 0..) |solid, i| solids_final.set(i, solid);
    const player_final: Player = .{ .common = player, .moveable = .{
        .vel = Vel.ZERO,
        .acc = Acc.ZERO,
        .lastPos = player.pos,
    } };
    return .{
        .solids = solids_final,
        .player = player_final,
    };
}

pub fn deinit(self: State, ally: std.mem.Allocator) void {
    self.solids.deinit(ally);
}
