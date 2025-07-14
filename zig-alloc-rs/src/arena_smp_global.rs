use crate::ZigArenaSmpAllocator;
use std::alloc::{GlobalAlloc, Layout};
use std::sync::LazyLock;

/// A global allocator wrapper around ZigArenaSmpAllocator
///
/// This provides a global allocator implementation using Zig's Arena+SMP allocator.
///
/// Note: This is primarily for testing scenarios. In practice, arena allocators
/// are typically used in more limited scopes for bulk deallocation patterns.
pub struct ZigGlobalArenaSmpAllocator;

static ALLOCATOR: LazyLock<ZigArenaSmpAllocator> = LazyLock::new(ZigArenaSmpAllocator::new);

unsafe impl GlobalAlloc for ZigGlobalArenaSmpAllocator {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        unsafe { ALLOCATOR.alloc(layout) }
    }

    unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout) {
        unsafe {
            ALLOCATOR.dealloc(ptr, layout);
        }
    }
}
