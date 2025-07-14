#![feature(allocator_api)]

use zigalloc::ZigDebugAllocator;

#[test]
fn ensure_detects_leak_with_warning() {
    let allocator = ZigDebugAllocator::with_panic_on_leaks(false);

    let data = Box::new(Vec::<u8, &ZigDebugAllocator>::with_capacity_in(
        500, &allocator,
    ));

    Box::leak(data);
}

#[test]
fn ensure_ok_no_leak() {
    let allocator = ZigDebugAllocator::new();
    let mut data = Vec::<u8, &ZigDebugAllocator>::with_capacity_in(25_000, &allocator);

    data.push(1);
    data.push(2);
    data.push(3);

    // Ensure no crash
}
