use std::env;
use std::path::Path;
use std::process::Command;

fn main() {
    let manifest_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    let out_dir = env::var("OUT_DIR").unwrap();
    let zig_alloc_dir = Path::new(&manifest_dir).parent().unwrap().join("zig-alloc");

    // Detect nightly toolchain and enable nightly feature
    if is_nightly_toolchain() {
        println!("cargo::rustc-cfg=feature=\"nightly\"");
    }

    // Get configurable library name (default: "zigalloc")
    let lib_name = env::var("ZIG_LIB_NAME").unwrap_or_else(|_| "zigalloc".to_string());
    let lib_filename = if cfg!(windows) {
        format!("{lib_name}.lib")
    } else {
        format!("lib{lib_name}.a")
    };
    let lib_dst = Path::new(&out_dir).join(&lib_filename);

    // Build with Zig
    match build_with_zig(&zig_alloc_dir, &lib_dst, &lib_filename) {
        Ok(_) => println!("cargo::warning=Built {lib_filename} with Zig"),
        Err(err) => {
            eprintln!("Failed to build with Zig: {err}");
            eprintln!("Please install Zig from https://ziglang.org/download/");
            panic!("Cannot build without Zig compiler");
        }
    }

    // Tell cargo to rerun if dependencies change
    println!("cargo::rerun-if-changed=../zig-alloc/src");
    println!("cargo::rerun-if-changed=../zig-alloc/build.zig");

    // Link the library
    println!("cargo::rustc-link-search=native={out_dir}");
    println!("cargo::rustc-link-lib=static={lib_name}");
}

fn build_with_zig(zig_alloc_dir: &Path, lib_dst: &Path, lib_filename: &str) -> Result<(), String> {
    // Check if zig is available
    if Command::new("zig").arg("version").output().is_err() {
        return Err("Zig compiler not found in PATH".to_string());
    }

    // Build the Zig library
    let mut args = vec!["build", "-Doptimize=ReleaseSafe"];

    if cfg!(target_os = "windows") && cfg!(target_arch = "x86_64") {
        if cfg!(target_env = "msvc") {
            args.push("-Dtarget=x86_64-windows-msvc");
        } else if cfg!(target_env = "gnu") {
            args.push("-Dtarget=x86_64-windows-gnu");
        }
    }

    let output = Command::new("zig")
        .args(&args)
        .current_dir(zig_alloc_dir)
        .output()
        .map_err(|err| format!("Failed to execute zig build: {err}"))?;

    if !output.status.success() {
        return Err(format!(
            "Zig build failed: {}",
            String::from_utf8_lossy(&output.stderr)
        ));
    }

    // Copy the built library
    let lib_src = zig_alloc_dir.join("zig-out/lib").join(lib_filename);
    std::fs::copy(&lib_src, lib_dst)
        .map_err(|err| format!("Failed to copy {lib_filename}: {err}"))?;

    Ok(())
}

fn is_nightly_toolchain() -> bool {
    // Check if RUSTC_VERSION is set and contains "nightly"
    if let Ok(version) = env::var("RUSTC_VERSION") {
        return version.contains("nightly");
    }

    // Fallback: run rustc --version to check for nightly
    if let Ok(output) = Command::new("rustc").arg("--version").output() {
        if let Ok(version_str) = String::from_utf8(output.stdout) {
            return version_str.contains("nightly");
        }
    }

    false
}
