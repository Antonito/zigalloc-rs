//! Debug allocator with leak detection and safety features.
//!
//! This module provides a debug allocator that can detect memory leaks,
//! buffer overruns, and other memory safety issues. It's useful for
//! development and testing.

const std = @import("std");
const ffi = @import("ffi.zig");

/// Default configuration for the debug allocator with sensible safety settings.
const DebugAllocatorConfig = std.heap.DebugAllocatorConfig{
    .stack_trace_frames = if (std.debug.sys_can_stack_trace) 6 else 0,

    .safety = true,
    .thread_safe = true,
    .backing_allocator_zeroes = true,
    .canary = @truncate(0x9232a6ff85dff10f),

    // Enables emitting info messages with the size and address of every allocation.
    .verbose_log = false,
};

/// Debug allocator wrapper with configurable leak detection.
///
/// This allocator provides memory safety features including:
/// - Leak detection
/// - Buffer overflow detection (via canary values)
/// - Thread safety
/// - Optional stack traces for allocations
pub const DebugAllocator = struct {
    /// Configuration options for `DebugAllocator.init`.
    pub const Config = struct {
        /// Whether to panic when the allocator is de-initialized and leaks are found.
        panic_on_leaks: bool = true,
    };

    /// Debug allocator
    debug_allocator: std.heap.DebugAllocator(DebugAllocatorConfig),

    /// Whether to panic when the allocator is de-initialized
    /// and we find memory leaks
    panic_on_exit_leaks: bool,

    /// Initialize a debug allocator with the given configuration.
    pub fn init(config: Config) DebugAllocator {
        return .{
            .debug_allocator = .{ .backing_allocator = std.heap.page_allocator },
            .panic_on_exit_leaks = config.panic_on_leaks,
        };
    }

    /// Get the Zig allocator interface.
    pub fn allocator(self: *DebugAllocator) std.mem.Allocator {
        return self.debug_allocator.allocator();
    }

    /// Deinitialize the allocator and check for memory leaks.
    /// Will panic or print warnings if leaks are detected based on configuration.
    pub fn deinit(self: *DebugAllocator) void {
        const deinit_status = self.debug_allocator.deinit();

        if (deinit_status == .leak) {
            if (self.panic_on_exit_leaks) {
                @panic("memory allocator had memory leaks");
            } else {
                std.debug.print("warning: memory allocator had memory leaks\n", .{});
            }
        }
    }
};

/// Configuration for creating debug allocators via FFI
pub const DebugAllocatorCreateConfig = extern struct {
    /// Whether to panic when leaks are detected on deinit
    panic_on_leaks: bool,
};

// Compile-time checks to ensure FFI compatibility
comptime {
    const DebugAllocatorCreateConfig_ExpectedSize = 1;
    const DebugAllocatorCreateConfig_ExpectedAlign = 1;

    // Verify struct size and alignment match expected C layout
    if (@sizeOf(DebugAllocatorCreateConfig) != DebugAllocatorCreateConfig_ExpectedSize) {
        @compileError(std.fmt.comptimePrint(
            "DebugAllocatorCreateConfig size mismatch - expected {d} byte, got {d}",
            .{ DebugAllocatorCreateConfig_ExpectedSize, @sizeOf(DebugAllocatorCreateConfig) },
        ));
    }

    if (@alignOf(DebugAllocatorCreateConfig) != DebugAllocatorCreateConfig_ExpectedAlign) {
        @compileError(std.fmt.comptimePrint(
            "DebugAllocatorCreateConfig alignment mismatch - expected {d} byte alignment, got {d}",
            .{ DebugAllocatorCreateConfig_ExpectedAlign, @alignOf(DebugAllocatorCreateConfig) },
        ));
    }
}

/// Create a new `DebugAllocator` with the given configuration
export fn zig_debug_allocator_create(config_ptr: ?*const DebugAllocatorCreateConfig) callconv(.c) ?*anyopaque {
    const config = (config_ptr orelse return null).*;

    const allocator = ffi.createWithConfig(DebugAllocator, .{
        .panic_on_leaks = config.panic_on_leaks,
    }) catch return null;

    return @ptrCast(allocator);
}
