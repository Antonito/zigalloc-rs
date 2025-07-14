//! Using the Arena SMP allocator globally
//! Run with: cargo run --example global_arena_allocator

use zigalloc::ZigGlobalArenaSmpAllocator;

// Replace the global allocator with Arena SMP allocator
#[global_allocator]
static GLOBAL: ZigGlobalArenaSmpAllocator = ZigGlobalArenaSmpAllocator;

fn main() {
    // All standard allocations now use the Arena SMP allocator
    let vec = vec![1, 2, 3, 4, 5];
    let string = String::from("Hello, World!");

    println!("Created Vec: {:?}", vec);
    println!("Created String: {}", string);
    println!("Global Arena SMP allocator example completed successfully");

    // Note: Arena allocators are typically used in more limited scopes
    // This global usage is primarily for testing scenarios
}
