//! Basic usage of the Debug allocator for leak detection
//! Run with: cargo run --example debug_allocator
#![cfg_attr(feature = "nightly", feature(allocator_api))]
#[cfg(feature = "nightly")]
fn main() {
    use zigalloc::ZigDebugAllocator;

    // Create the debug allocator
    let allocator = ZigDebugAllocator::new();

    // Use with Vec - this will be tracked for leaks
    let mut vec = Vec::<i32, &ZigDebugAllocator>::with_capacity_in(10, &allocator);
    for i in 0..5 {
        vec.push(i);
    }

    println!("Created Vec with {} elements: {:?}", vec.len(), vec);
}

#[cfg(not(feature = "nightly"))]
fn main() {
    println!("Skipped, run with a nightly toolchain instead");
}
