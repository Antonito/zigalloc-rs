//! FFI (Foreign Function Interface) utilities for exposing Zig allocators to other languages.
//!
//! This module provides the FfiAllocator abstraction that wraps any Zig allocator
//! with a C-compatible interface suitable for cross-language interoperability.

const std = @import("std");

/// FfiAllocator provides a C-compatible wrapper around Zig allocators.
///
/// This struct manages the lifetime of the backing allocator and provides
/// allocation, reallocation, and deallocation methods that can be safely
/// called from foreign code.
pub const FfiAllocator = struct {
    /// Type-erased pointer to the parent allocator struct
    parent: *anyopaque,

    /// Function pointer to deinitialize the parent allocator
    deinit_parent: *const fn (*anyopaque) void,

    /// The Zig allocator interface
    allocator: std.mem.Allocator,

    /// Allocate memory with the specified size and alignment.
    /// Returns null if allocation fails or if size is 0.
    pub fn alloc(
        self: *FfiAllocator,
        size: usize,
        alignment: std.mem.Alignment,
    ) ?*anyopaque {
        // Return null for zero-size allocations
        if (size == 0) {
            return null;
        }

        const mem = self.allocator.rawAlloc(
            size,
            alignment,
            @returnAddress(),
        ) orelse return null;

        return @ptrCast(mem);
    }

    /// Reallocate memory to a new size.
    /// Attempts to resize in-place first, otherwise allocates new memory and copies data.
    /// Returns null if allocation fails.
    pub fn realloc(
        self: *FfiAllocator,
        memory: *anyopaque,
        old_size: usize,
        old_alignment: std.mem.Alignment,
        new_size: usize,
        new_alignment: std.mem.Alignment,
    ) ?*anyopaque {
        // For zero size, just free the memory
        if (new_size == 0) {
            self.free(memory, old_size, old_alignment);
            return null;
        }

        // Try to use the allocator's resize first (only if alignments match)
        if (old_alignment.toByteUnits() == new_alignment.toByteUnits()) {
            if (self.allocator.resize(@as([*]u8, @ptrCast(memory))[0..old_size], new_size)) {
                return memory;
            }
        }

        // Allocate new memory
        const new_mem = self.alloc(new_size, new_alignment) orelse return null;

        // Copy the minimum of old and new sizes to avoid buffer overrun
        const copy_size = @min(old_size, new_size);
        if (copy_size > 0) {
            const dest_bytes = @as([*]u8, @ptrCast(new_mem));
            const src_bytes = @as([*]const u8, @ptrCast(memory));
            @memcpy(dest_bytes[0..copy_size], src_bytes[0..copy_size]);
        }

        // Free old memory
        self.free(memory, old_size, old_alignment);

        return new_mem;
    }

    /// Free memory allocated by this allocator.
    pub fn free(
        self: *FfiAllocator,
        memory: *anyopaque,
        size: usize,
        alignment: std.mem.Alignment,
    ) void {
        const non_const_ptr = @as([*]u8, @ptrCast(memory));
        self.allocator.rawFree(non_const_ptr[0..size], alignment, @returnAddress());
    }

    /// Deinitialize the allocator and free the FfiAllocator struct itself.
    pub fn deinit_allocated(self: *FfiAllocator) void {
        self.deinit();
        std.heap.c_allocator.destroy(self);
    }

    /// Deinitialize the parent allocator.
    pub fn deinit(self: *FfiAllocator) void {
        self.deinit_parent(self.parent);
    }
};

/// Initialize a new FfiAllocator with the given parent and allocator.
pub fn init(
    parent: *anyopaque,
    deinit_parent: *const fn (*anyopaque) void,
    allocator: std.mem.Allocator,
) FfiAllocator {
    return .{
        .parent = parent,
        .deinit_parent = deinit_parent,
        .allocator = allocator,
    };
}

/// Create a heap-allocated FfiAllocator for the given allocator type.
///
/// This function:
/// 1. Creates an instance of type T on the heap using c_allocator
/// 2. Initializes the instance with T.init()
/// 3. Wraps it in an FfiAllocator with proper cleanup handlers
/// 4. Returns a pointer to the heap-allocated FfiAllocator
///
/// The type T must have:
/// - An `init() T` function for initialization
/// - A `deinit(*T) void` method for cleanup
/// - An `allocator(*T) std.mem.Allocator` method
///
/// Returns an error if heap allocation fails.
pub fn init_allocate(
    comptime T: type,
) std.mem.Allocator.Error!*FfiAllocator {
    const parent = try std.heap.c_allocator.create(T);
    parent.* = T.init();

    const self = try std.heap.c_allocator.create(FfiAllocator);

    self.* = init(
        @ptrCast(parent),
        DeinitHandler(T).deinit,
        parent.allocator(),
    );

    return self;
}

/// Converts an opaque pointer to a `*FfiAllocator`
///
/// Returns null if the provided pointer is null.
pub inline fn opaquePtrToFfiAllocator(ptr: ?*anyopaque) ?*align(8) FfiAllocator {
    const non_null_ptr = ptr orelse return null;
    return @alignCast(@ptrCast(non_null_ptr));
}

/// Converts an opaque pointer to a `*FfiAllocator`
///
/// Panics if the provided pointer is null.
pub inline fn mustOpaquePtrToFfiAllocator(ptr: ?*anyopaque) *align(8) FfiAllocator {
    const non_null_ptr = ptr orelse {
        @panic("provided FfiAllocator pointer is null");
    };

    return @alignCast(@ptrCast(non_null_ptr));
}

// Generic handler for deinit
fn DeinitHandler(comptime T: type) type {
    return struct {
        // Invokes deinit on the parent type and deallocates the structure
        fn deinit(ptr: *anyopaque) void {
            const allocator: *align(@alignOf(T)) T = @alignCast(@ptrCast(ptr));
            allocator.deinit();
            std.heap.c_allocator.destroy(allocator);
        }
    };
}
