use std::{alloc::GlobalAlloc, sync::LazyLock};

use crate::ZigDebugAllocator;

pub struct ZigGlobalDebugAllocator;

unsafe impl GlobalAlloc for ZigGlobalDebugAllocator {
    #[inline]
    unsafe fn alloc(&self, layout: std::alloc::Layout) -> *mut u8 {
        let allocator = get_or_init_alloc();
        unsafe { allocator.alloc(layout) }
    }

    #[inline]
    unsafe fn dealloc(&self, ptr: *mut u8, layout: std::alloc::Layout) {
        let allocator = get_or_init_alloc();
        unsafe { allocator.dealloc(ptr, layout) }
    }
}

#[inline]
fn get_or_init_alloc() -> &'static ZigDebugAllocator {
    static ALLOC: LazyLock<ZigDebugAllocator> = LazyLock::new(ZigDebugAllocator::new);
    &ALLOC
}
