//! Using the debug allocator globally
//! Run with: cargo run --example global_debug_allocator

use zigalloc::ZigGlobalDebugAllocator;

// Replace the global allocator
#[global_allocator]
static GLOBAL: ZigGlobalDebugAllocator = ZigGlobalDebugAllocator;

fn main() {
    // All standard allocations now use the debug allocator
    let vec = vec![1, 2, 3, 4, 5];
    let string = String::from("Hello, World!");

    println!("Created Vec: {:?}", vec);
    println!("Created String: {}", string);
}
