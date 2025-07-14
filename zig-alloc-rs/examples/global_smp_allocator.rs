//! Using the SMP allocator globally
//! Run with: cargo run --example global_smp_allocator

use zigalloc::ZigGlobalSmpAllocator;

// Replace the global allocator with SMP allocator
#[global_allocator]
static GLOBAL: ZigGlobalSmpAllocator = ZigGlobalSmpAllocator;

fn main() {
    // All standard allocations now use the SMP allocator
    let vec = vec![1, 2, 3, 4, 5];
    let string = String::from("Hello, World!");

    println!("Created Vec: {:?}", vec);
    println!("Created String: {}", string);
}
