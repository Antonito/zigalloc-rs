//! SMP (Symmetric Multi-Processing) allocator wrapper.
//!
//! This module provides a thin wrapper around Zig's built-in SMP allocator,
//! which is a thread-safe, general-purpose allocator optimized for multi-threaded
//! applications.

const std = @import("std");
const ffi = @import("ffi.zig");

/// Wrapper for the standard SMP allocator.
///
/// This is a zero-cost abstraction that provides the necessary
/// interface for FFI compatibility.
pub const SmpAllocator = struct {
    /// Initialize a new SMP allocator instance.
    pub fn init() SmpAllocator {
        return .{};
    }

    /// Get the Zig allocator interface.
    pub fn allocator(self: *SmpAllocator) std.mem.Allocator {
        _ = self;
        return std.heap.smp_allocator;
    }

    /// Deinitialize the allocator (no-op for SMP allocator).
    pub fn deinit(self: *SmpAllocator) void {
        _ = self;
    }
};

/// Create a new `SmpAllocator`
export fn zig_smp_allocator_create() callconv(.C) ?*anyopaque {
    const allocator = ffi.init_allocate(SmpAllocator) catch return null;
    return @ptrCast(allocator);
}
