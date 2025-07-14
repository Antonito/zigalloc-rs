/// FFI allocator wrapper
pub(crate) struct FfiAllocator {
    /// Ptr
    allocator_ptr: *mut std::ffi::c_void,
}

impl FfiAllocator {
    /// Create a new `FfiAllocator`
    #[must_use]
    pub(crate) fn new(allocator_ptr: *mut std::ffi::c_void) -> Self {
        Self { allocator_ptr }
    }
}

unsafe impl Send for FfiAllocator {}
unsafe impl Sync for FfiAllocator {}

impl Drop for FfiAllocator {
    fn drop(&mut self) {
        unsafe {
            zig_ffi_allocator_destroy(self.allocator_ptr);
        }
    }
}

impl FfiAllocator {
    /// Allocate some memory
    #[inline]
    pub(crate) fn alloc(&self, layout: std::alloc::Layout) -> *mut u8 {
        unsafe {
            zig_ffi_allocator_alloc(
                self.allocator_ptr,
                layout.size() as std::ffi::c_long,
                layout.align() as std::ffi::c_long,
            )
        }
    }

    /// Allocate some memory
    #[inline]
    pub(crate) fn allocate(
        &self,
        layout: std::alloc::Layout,
    ) -> Result<std::ptr::NonNull<[u8]>, std::alloc::AllocError> {
        let ptr = self.alloc(layout);
        if ptr.is_null() {
            return Err(std::alloc::AllocError);
        }

        let mem = unsafe {
            let non_null_ptr = std::ptr::NonNull::new_unchecked(ptr);
            let slice = std::slice::from_raw_parts_mut(non_null_ptr.as_ptr(), layout.size());
            std::ptr::NonNull::new_unchecked(slice)
        };

        Ok(mem)
    }

    /// Dealloc some memory from the allocator
    #[inline]
    pub(crate) fn dealloc(&self, ptr: *mut u8, layout: std::alloc::Layout) {
        unsafe {
            zig_ffi_allocator_dealloc(
                self.allocator_ptr,
                std::mem::transmute::<*mut u8, *mut std::ffi::c_void>(ptr),
                layout.size() as std::ffi::c_long,
                layout.align() as std::ffi::c_long,
            )
        };
    }

    /// Dealloc some memory from the allocator
    #[inline]
    pub(crate) fn deallocate(&self, ptr: std::ptr::NonNull<u8>, layout: std::alloc::Layout) {
        let ptr = unsafe { std::mem::transmute::<std::ptr::NonNull<u8>, *mut u8>(ptr) };
        self.dealloc(ptr, layout);
    }
}

unsafe extern "C" {
    fn zig_ffi_allocator_destroy(allocator: *mut std::ffi::c_void);

    fn zig_ffi_allocator_alloc(
        allocator: *mut std::ffi::c_void,
        size: std::ffi::c_long,
        align: std::ffi::c_long,
    ) -> *mut u8;

    fn zig_ffi_allocator_dealloc(
        allocator: *mut std::ffi::c_void,
        memory: *mut std::ffi::c_void,
        size: std::ffi::c_long,
        align: std::ffi::c_long,
    );
}
