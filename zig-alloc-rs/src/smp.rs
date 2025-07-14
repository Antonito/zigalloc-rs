use crate::ffi::FfiAllocator;
use std::alloc::GlobalAlloc;

/// Zig SMP Allocator
pub struct ZigSmpAllocator {
    /// Inner allocator
    ffi_allocator: FfiAllocator,
}

impl ZigSmpAllocator {
    /// Create a new debug allocator
    #[must_use]
    pub fn new() -> Self {
        let allocator_ptr = unsafe { zig_smp_allocator_create() };

        Self {
            ffi_allocator: FfiAllocator::new(allocator_ptr),
        }
    }
}

impl Default for ZigSmpAllocator {
    fn default() -> Self {
        Self::new()
    }
}

unsafe impl GlobalAlloc for ZigSmpAllocator {
    #[inline]
    unsafe fn alloc(&self, layout: std::alloc::Layout) -> *mut u8 {
        self.ffi_allocator.alloc(layout)
    }

    #[inline]
    unsafe fn dealloc(&self, ptr: *mut u8, layout: std::alloc::Layout) {
        self.ffi_allocator.dealloc(ptr, layout);
    }
}

#[cfg(feature = "nightly")]
unsafe impl std::alloc::Allocator for ZigSmpAllocator {
    #[inline]
    fn allocate(
        &self,
        layout: std::alloc::Layout,
    ) -> Result<std::ptr::NonNull<[u8]>, std::alloc::AllocError> {
        self.ffi_allocator.allocate(layout)
    }

    #[inline]
    unsafe fn deallocate(&self, ptr: std::ptr::NonNull<u8>, layout: std::alloc::Layout) {
        self.ffi_allocator.deallocate(ptr, layout);
    }
}

unsafe extern "C" {
    fn zig_smp_allocator_create() -> *mut std::ffi::c_void;
}
