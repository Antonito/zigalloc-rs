use crate::ffi::FfiAllocator;
use std::alloc::GlobalAlloc;

/// Zig Debug Allocator
pub struct ZigDebugAllocator {
    /// Inner allocator
    ffi_allocator: FfiAllocator,
}

/// Configuration for creating debug allocators
#[repr(C, align(1))]
#[derive(Clone, Copy, Debug)]
pub struct DebugAllocatorConfig {
    /// Whether to panic when leaks are detected on deinit
    pub panic_on_leaks: bool,
}

// Compile-time checks to ensure FFI compatibility
const _: () = {
    // Verify struct size and alignment match expected C layout
    assert!(
        std::mem::size_of::<DebugAllocatorConfig>() == 1,
        "DebugAllocatorConfig size must be 1 byte for FFI compatibility"
    );

    const fn assert(condition: bool, message: &str) {
        if !condition {
            panic!("{}", message);
        }
    }
};

impl Default for DebugAllocatorConfig {
    fn default() -> Self {
        Self {
            panic_on_leaks: true,
        }
    }
}

impl ZigDebugAllocator {
    /// Create a new debug allocator with default settings (panics on leaks)
    #[must_use]
    pub fn new() -> Self {
        Self::with_config(DebugAllocatorConfig::default())
    }

    /// Create a new debug allocator with the given configuration
    #[must_use]
    pub fn with_config(config: DebugAllocatorConfig) -> Self {
        let allocator_ptr = unsafe { zig_debug_allocator_create(&config) };

        Self {
            ffi_allocator: FfiAllocator::new(allocator_ptr),
        }
    }

    /// Create a new debug allocator with configurable panic behavior
    #[must_use]
    pub fn with_panic_on_leaks(panic_on_leaks: bool) -> Self {
        Self::with_config(DebugAllocatorConfig { panic_on_leaks })
    }
}

impl Default for ZigDebugAllocator {
    fn default() -> Self {
        Self::new()
    }
}

unsafe impl GlobalAlloc for ZigDebugAllocator {
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
unsafe impl std::alloc::Allocator for ZigDebugAllocator {
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
    fn zig_debug_allocator_create(config: *const DebugAllocatorConfig) -> *mut std::ffi::c_void;
}
