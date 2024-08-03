const std = @import("std");
const zgpu = @import("zgpu");
const wgpu = zgpu.wgpu;
const img = @import("img");

const Bind = @import("../render.zig").Bind;
pub const Material = extern struct {
    /// x, y of top left corner where top = y0
    atlas_pos: [2]u32,
    /// width, height
    atlas_dims: [2]u32,
};

pub const RenderState = struct {
    texture: zgpu.TextureHandle,
    texture_view: zgpu.TextureViewHandle,
    sprite_sheet_bind: Bind,
};

pub fn makeMatList() std.ArrayListUnmanaged(Material) {
    return .{};
}

pub fn initRender(gctx: *zgpu.GraphicsContext, ally: std.mem.Allocator, bindnum: u32) !RenderState {
    var sheet = try img.ImageUnmanaged.fromMemory(ally, @embedFile("spritesheet.png")[0..]);
    defer sheet.deinit(ally);
    try sheet.convert(ally, .rgba32);
    const width: u32 = @intCast(sheet.width);
    const height: u32 = @intCast(sheet.height);
    const texture = gctx.createTexture(.{
        .dimension = .tdim_2d,
        .format = .rgba8_unorm,
        .label = "sprite sheet",
        .size = .{ .width = width, .height = height },
        .usage = .{ .copy_dst = true, .texture_binding = true },
    });
    gctx.queue.writeTexture(
        .{ .texture = gctx.lookupResource(texture).? },
        .{
            .bytes_per_row = @intCast(sheet.rowByteSize()),
            .rows_per_image = height,
        },
        .{
            .width = width,
            .height = height,
        },
        u8,
        sheet.rawBytes(),
    );
    const entry_layout = zgpu.textureEntry(bindnum, .{
        .fragment = true,
    }, .float, .tvdim_2d, false);
    // TODO: move buffer creation to here?
    const texture_view_handle = gctx.createTextureView(texture, .{ .format = .rgba8_unorm });
    const entry: zgpu.BindGroupEntryInfo = .{
        .binding = bindnum,
        .texture_view_handle = texture_view_handle,
    };
    return .{
        .sprite_sheet_bind = .{
            .bindnum = bindnum,
            .entry_layout = entry_layout,
            .entry = entry,
        },
        .texture = texture,
        .texture_view = texture_view_handle,
    };
}

pub fn createMaterial(ally: std.mem.Allocator, mat_list: *std.ArrayListUnmanaged(Material), mat: Material) !u32 {
    try mat_list.append(ally, mat);
    return @intCast(mat_list.items.len - 1);
}
