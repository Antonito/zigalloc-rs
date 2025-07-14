//! Integration test for memory leak detection with SIGABRT handling.
//!
//! This test is implemented as an integration test (rather than a unit test) because:
//! 1. Signal handlers are process-global and can interfere with other tests running in parallel
//! 2. Integration tests run in separate processes, providing complete isolation
//! 3. This allows us to safely install a SIGABRT handler without affecting other tests

#![feature(allocator_api)]

use std::sync::atomic::{AtomicBool, Ordering};
use zigalloc::ZigDebugAllocator;

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
