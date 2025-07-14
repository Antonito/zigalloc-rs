//! Arena allocator backed by the SMP allocator.
//!
//! This module provides an arena allocator that uses the thread-safe SMP allocator
//! as its backing allocator. Arena allocators are useful for bulk memory management
//! where all allocations can be freed at once.

const std = @import("std");
const ffi = @import("ffi.zig");

/// Arena allocator that uses SMP allocator for backing memory.
///
/// This allocator is ideal for scenarios where you need to allocate
/// many objects and free them all at once.
pub const ArenaSmpAllocator = struct {
    /// The underlying arena allocator
    arena: std.heap.ArenaAllocator,

    /// Initialize a new arena allocator backed by the SMP allocator.
    pub fn init() ArenaSmpAllocator {
        return .{
            .arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator),
        };
    }

    /// Get the Zig allocator interface.
    pub fn allocator(self: *ArenaSmpAllocator) std.mem.Allocator {
        return self.arena.allocator();
    }

    /// Deinitialize the arena, freeing all memory at once.
    pub fn deinit(self: *ArenaSmpAllocator) void {
        self.arena.deinit();
    }
};

/// Create a new `ArenaSmpAllocator`
export fn zig_arena_smp_allocator_create() callconv(.C) ?*anyopaque {
    const allocator = ffi.init_allocate(ArenaSmpAllocator) catch return null;
    return @ptrCast(allocator);
}
