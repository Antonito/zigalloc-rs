use std::env;
use std::path::Path;
use std::process::Command;

fn main() {
    let manifest_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    let out_dir = env::var("OUT_DIR").unwrap();
    let zig_alloc_dir = Path::new(&manifest_dir).parent().unwrap().join("zig-alloc");

    // Get configurable library name (default: "zigalloc")
    let lib_name = env::var("ZIG_LIB_NAME").unwrap_or_else(|_| "zigalloc".to_string());
    let lib_filename = format!("lib{}.a", lib_name);
    let lib_dst = Path::new(&out_dir).join(&lib_filename);

    // Build with Zig
    match build_with_zig(&zig_alloc_dir, &lib_dst, &lib_filename) {
        Ok(_) => println!("cargo::warning=Built {} with Zig", lib_filename),
        Err(e) => {
            eprintln!("Failed to build with Zig: {}", e);
            eprintln!("Please install Zig from https://ziglang.org/download/");
            panic!("Cannot build without Zig compiler");
        }
    }

    // Tell cargo to rerun if dependencies change
    println!("cargo::rerun-if-changed=../zig-alloc/src");
    println!("cargo::rerun-if-changed=../zig-alloc/build.zig");

    // Link the library
    println!("cargo::rustc-link-search=native={}", out_dir);
    println!("cargo::rustc-link-lib=static={}", lib_name);
}

fn build_with_zig(zig_alloc_dir: &Path, lib_dst: &Path, lib_filename: &str) -> Result<(), String> {
    // Check if zig is available
    if Command::new("zig").arg("version").output().is_err() {
        return Err("Zig compiler not found in PATH".to_string());
    }

    // Build the Zig library
    let output = Command::new("zig")
        .args(["build", "-Doptimize=ReleaseSafe"])
        .current_dir(zig_alloc_dir)
        .output()
        .map_err(|e| format!("Failed to execute zig build: {}", e))?;

    if !output.status.success() {
        return Err(format!(
            "Zig build failed: {}",
            String::from_utf8_lossy(&output.stderr)
        ));
    }

    // Copy the built library
    let lib_src = zig_alloc_dir.join("zig-out/lib").join(lib_filename);
    std::fs::copy(&lib_src, lib_dst)
        .map_err(|e| format!("Failed to copy {}: {}", lib_filename, e))?;

    Ok(())
}
