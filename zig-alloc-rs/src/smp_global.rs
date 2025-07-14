use crate::ZigSmpAllocator;
use std::alloc::{GlobalAlloc, Layout};
use std::sync::LazyLock;

/// A global allocator wrapper around ZigSmpAllocator
///
/// This provides a global allocator implementation using Zig's SMP allocator.
pub struct ZigGlobalSmpAllocator;

static ALLOCATOR: LazyLock<ZigSmpAllocator> = LazyLock::new(ZigSmpAllocator::new);

unsafe impl GlobalAlloc for ZigGlobalSmpAllocator {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        unsafe { ALLOCATOR.alloc(layout) }
    }

    unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout) {
        unsafe {
            ALLOCATOR.dealloc(ptr, layout);
        }
    }
}
