use std::borrow::Cow;
use std::path::PathBuf;

pub fn main() {
    build_shader();
}

pub fn build_shader() -> wgpu::ShaderModuleDescriptorSpirV<'static> {
    let manifest_dir = option_env!("RUNNER_DIR").unwrap_or(env!("CARGO_MANIFEST_DIR"));
    let crate_path = [manifest_dir, "..", "shaders", "shader"]
        .iter()
        .copied()
        .collect::<PathBuf>();

    let builder = spirv_builder::SpirvBuilder::new(crate_path, "spirv-unknown-vulkan1.1")
        .shader_panic_strategy(spirv_builder::ShaderPanicStrategy::SilentExit);
    let initial_result = builder.build().unwrap();
    let path = initial_result.module.unwrap_single();
    let data = std::fs::read(path).unwrap();
    let spirv = Cow::Owned(wgpu::util::make_spirv_raw(&data).into_owned());
    wgpu::ShaderModuleDescriptorSpirV {
        label: None,
        source: spirv,
    }
}
