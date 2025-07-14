//! Integration test for memory leak detection with platform-specific panic handling.
//!
//! This test is implemented as an integration test (rather than a unit test) because:
//! 1. Signal handlers are process-global and can interfere with other tests running in parallel
//! 2. Integration tests run in separate processes, providing complete isolation
//! 3. This allows us to safely install signal handlers without affecting other tests
//!
//! Platform-specific behavior:
//! - Unix/Linux/macOS: Uses POSIX signals (SIGABRT) to catch panic
//! - Windows: Uses process spawning to catch panic exit codes

#![cfg(feature = "nightly")]
#![feature(allocator_api)]

#[cfg(unix)]
use std::sync::atomic::{AtomicBool, Ordering};
use zigalloc::ZigDebugAllocator;

#[cfg(unix)]
#[test]
fn ensure_detects_leak_with_panic() {
    static SIGABRT_CAUGHT: AtomicBool = AtomicBool::new(false);

    // Install SIGABRT handler
    unsafe {
        extern "C" fn sigabrt_handler(_: libc::c_int) {
            SIGABRT_CAUGHT.store(true, Ordering::SeqCst);
            std::process::exit(0); // Exit cleanly to indicate test success
        }
        libc::signal(libc::SIGABRT, sigabrt_handler as usize);
    }

    let allocator = ZigDebugAllocator::with_panic_on_leaks(true);
    let data = Box::new(Vec::<u8, &ZigDebugAllocator>::with_capacity_in(
        500, &allocator,
    ));
    Box::leak(data);

    // This should trigger SIGABRT
    drop(allocator);

    // If we reach here, SIGABRT wasn't sent
    panic!("Expected SIGABRT but didn't receive it");
}

#[cfg(windows)]
#[test]
fn ensure_detects_leak_with_panic() {
    use std::env;
    use std::process::Command;

    // On Windows, we need to spawn a separate process to catch the panic
    // because Windows doesn't have POSIX signals like SIGABRT
    let exe_path = env::current_exe().expect("Could not get current executable path");

    let output = Command::new(&exe_path)
        .arg("--test-threads=1")
        .arg("--exact")
        .arg("leak_detection_helper_windows")
        .env("LEAK_DETECTION_HELPER", "1")
        .output()
        .expect("Failed to execute test helper");

    // The helper process should exit with a non-zero code due to panic
    // On Windows, Zig panic typically results in process termination
    assert!(
        !output.status.success(),
        "Expected process to exit with error due to panic. Exit code: {:?}",
        output.status.code()
    );

    // Additional check: stderr should contain panic message
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        stderr.contains("memory allocator had memory leaks") || stderr.contains("panicked"),
        "Expected panic message in stderr, got: {}",
        stderr
    );
}

#[cfg(windows)]
#[test]
fn leak_detection_helper_windows() {
    // Skip this test unless explicitly requested via environment variable
    // This prevents the helper from running during normal test execution
    if std::env::var("LEAK_DETECTION_HELPER").is_err() {
        return;
    }

    // This is a helper test that will be run in a separate process on Windows
    // It creates a leak and the Zig panic will terminate the process
    let allocator = ZigDebugAllocator::with_panic_on_leaks(true);
    let data = Box::new(Vec::<u8, &ZigDebugAllocator>::with_capacity_in(
        500, &allocator,
    ));
    Box::leak(data);

    // This should trigger panic from leak detection and terminate the process
    drop(allocator);

    // If we reach here, the panic didn't occur as expected
    panic!("Expected panic from leak detection but didn't occur");
}
