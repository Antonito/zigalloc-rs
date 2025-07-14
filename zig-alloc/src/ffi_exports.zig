//! FFI export functions for C-compatible allocator interface.
//!
//! This module contains all the exported functions that provide the C ABI
//! for allocator operations. These functions work with opaque pointers and
//! use the FfiAllocator abstraction for type safety.

const ffi = @import("ffi.zig");

/// Destroy an allocator
export fn zig_ffi_allocator_destroy(allocator_ptr: *anyopaque) callconv(.C) void {
    const allocator = ffi.mustOpaquePtrToFfiAllocator(allocator_ptr);
    allocator.deinit_allocated();
}

/// Alloc some memory via a Zig allocator
export fn zig_ffi_allocator_alloc(
    allocator_ptr: *anyopaque,
    size: usize,
    alignment: usize,
) callconv(.C) ?*anyopaque {
    const allocator = ffi.opaquePtrToFfiAllocator(allocator_ptr) orelse return null;
    return allocator.alloc(size, .fromByteUnits(alignment));
}

/// Re-alloc some memory via a Zig allocator
export fn zig_ffi_allocator_realloc(
    allocator_ptr: *anyopaque,
    memory: *anyopaque,
    old_size: usize,
    old_alignment: usize,
    new_size: usize,
    new_alignment: usize,
) callconv(.C) ?*anyopaque {
    const allocator = ffi.opaquePtrToFfiAllocator(allocator_ptr) orelse return null;
    return allocator.realloc(
        memory,
        old_size,
        .fromByteUnits(old_alignment),
        new_size,
        .fromByteUnits(new_alignment),
    );
}

/// Dealloc a pointer allocated via a Zig allocator
export fn zig_ffi_allocator_dealloc(
    allocator_ptr: *anyopaque,
    memory: *anyopaque,
    size: usize,
    alignment: usize,
) callconv(.C) void {
    const allocator = ffi.opaquePtrToFfiAllocator(allocator_ptr) orelse return;
    allocator.free(memory, size, .fromByteUnits(alignment));
}