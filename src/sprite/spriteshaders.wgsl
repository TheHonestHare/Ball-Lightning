

const vertices = array<vec2f,3>(
    vec2<f32>( 0.5, -0.5),
    vec2<f32>( 0.0,  0.5),
    vec2<f32>(-0.5, -0.5),
);

const clipheight_unit_ratio = 2. / 128.;

struct Pos {
    x: f32,
    y: f32,
    scale: f32,
    material: u32,
}

struct Material {
    /// x, y of top left corner where top = y0
    atlas_pos: vec2u,
    /// width, height
    atlas_dims: vec2u,
}

@group(0) @binding(0) var<storage, read> pos: array<Pos>;
@group(0) @binding(1) var<storage, read> mats: array<Material>;
@group(0) @binding(2) var sprite_sheet: texture_2d<f32>;
@group(1) @binding(0) var<uniform> cameraMat: mat4x4f;
@group(1) @binding(1) var<uniform> asp_rat: f32;

struct VertexOut {
    @builtin(position) pos: vec4f,
    @location(0) uv: vec2f,
    @location(1) @interpolate(flat) mat_i: u32
}
// vertex arrangement is
// 2-3
// |\|
// 0-1

@vertex fn vert_main(@builtin(vertex_index) index: u32, @builtin(instance_index) inst: u32) -> VertexOut {
    let pos_mask = vec2<bool>(vec2u(index & 1, index & 2));
    let botleft_clip: vec4f = vec4f(pos[inst].x, pos[inst].y, 0.0, 1.0) * cameraMat;
    let atlas_dims = vec2f(mats[pos[inst].material].atlas_dims);
    var offsets: vec2f = vec2f(clipheight_unit_ratio) * vec2f(pos_mask) * pos[inst].scale;
    offsets.y *= atlas_dims.y / atlas_dims.x;
    var pos_clip: vec4f = vec4f(botleft_clip.xy + offsets, botleft_clip.zw);
    pos_clip.x /= asp_rat;
    return VertexOut(pos_clip, vec2f(pos_mask), pos[inst].material);
}

@fragment fn frag_main(@location(0) uv: vec2f, @location(1) @interpolate(flat) mat_i: u32) -> @location(0) vec4<f32> {
    let material = mats[mat_i];
    let range = (1-uv) * vec2f(material.atlas_dims) + vec2f(material.atlas_pos);
    return textureLoad(sprite_sheet, vec2u(floor(range)), 0);
    //return vec4f(uv, 0.0, 1.0);
}