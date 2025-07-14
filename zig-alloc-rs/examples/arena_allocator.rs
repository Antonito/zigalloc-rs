//! Basic usage of the Arena allocator
//! Run with: cargo run --example arena_allocator
#![cfg_attr(feature = "nightly", feature(allocator_api))]
#[cfg(feature = "nightly")]
fn main() {
    use zigalloc::ZigArenaSmpAllocator;
    // Create the arena
    let arena = ZigArenaSmpAllocator::new();

    // Create multiple allocations that will all be freed together
    let mut vec1 = Vec::<i32, &ZigArenaSmpAllocator>::with_capacity_in(10, &arena);
    let mut vec2 = Vec::<String, &ZigArenaSmpAllocator>::new_in(&arena);

    // Use them
    vec1.push(42);
    vec2.push("Hello".to_string());
    vec2.push("World".to_string());

    println!("Vec1: {:?}", vec1);
    println!("Vec2: {:?}", vec2);
}

#[cfg(not(feature = "nightly"))]
fn main() {
    println!("Skipped, run with a nightly toolchain instead");
}
