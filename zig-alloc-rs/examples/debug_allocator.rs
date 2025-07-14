//! Basic usage of the Debug allocator for leak detection
//! Run with: cargo run --example debug_allocator

#![feature(allocator_api)]

use zigalloc::ZigDebugAllocator;

fn main() {
    // Create the debug allocator
    let allocator = ZigDebugAllocator::new();

    // Use with Vec - this will be tracked for leaks
    let mut vec = Vec::<i32, &ZigDebugAllocator>::with_capacity_in(10, &allocator);
    for i in 0..5 {
        vec.push(i);
    }

    println!("Created Vec with {} elements: {:?}", vec.len(), vec);
}
