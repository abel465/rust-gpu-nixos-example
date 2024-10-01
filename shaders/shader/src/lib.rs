#![cfg_attr(target_arch = "spirv", no_std)]

use spirv_std::glam::*;
use spirv_std::spirv;

#[spirv(fragment)]
pub fn main_fs(output: &mut Vec4) {
    *output = Vec3::X.extend(1.0);
}

#[spirv(vertex)]
pub fn main_vs(
    #[spirv(vertex_index)] vert_id: i32,
    #[spirv(position, invariant)] out_pos: &mut Vec4,
) {
    let uv = vec2(((vert_id << 1) & 2) as f32, (vert_id & 2) as f32);
    let pos = 2.0 * uv - Vec2::ONE;

    *out_pos = pos.extend(0.0).extend(1.0);
}
