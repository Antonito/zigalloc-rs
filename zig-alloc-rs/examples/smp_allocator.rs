//! Basic usage of the SMP allocator
//! Run with: cargo run --example smp_allocator
#![cfg_attr(feature = "nightly", feature(allocator_api))]
#[cfg(feature = "nightly")]
fn main() {
    use zigalloc::ZigSmpAllocator;

    // Create the allocator
    let allocator = ZigSmpAllocator::new();

    // Use with Vec
    let mut vec = Vec::<i32, &ZigSmpAllocator>::with_capacity_in(10, &allocator);
    for i in 0..5 {
        vec.push(i);
    }

    println!("Created Vec with {} elements: {:?}", vec.len(), vec);
}

#[cfg(not(feature = "nightly"))]
fn main() {
    println!("Skipped, run with a nightly toolchain instead");
}
