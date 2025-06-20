use std::env;

fn main() {
    // set arch aliases to make cfg_attr usage less awkward
    for cfg in ["mobi", "wasm"] {
        println!("cargo::rustc-check-cfg=cfg({})", cfg);
    }

    if env::var("CARGO_CFG_TARGET_ARCH").unwrap_or_default() == "wasm32" {
        println!("cargo:rustc-cfg=wasm");
    } else {
        println!("cargo:rustc-cfg=mobi");
    }
}
