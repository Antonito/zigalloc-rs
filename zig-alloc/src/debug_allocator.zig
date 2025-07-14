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
    .MutexType = std.Thread.Mutex,
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
    /// Debug allocator
    debug_allocator: std.heap.DebugAllocator(DebugAllocatorConfig),

    /// Whether to panic when the allocator is de-initialized
    /// and we find memory leaks
    panic_on_exit_leaks: bool,

    /// Initialize a debug allocator with default settings (panics on leaks).
    pub fn init() DebugAllocator {
        return .{
            .debug_allocator = std.heap.DebugAllocator(DebugAllocatorConfig){ .backing_allocator = std.heap.page_allocator },
            .panic_on_exit_leaks = true,
        };
    }

    /// Initialize a debug allocator with custom leak handling behavior.
    pub fn initWithConfig(panic_on_leaks: bool) DebugAllocator {
        return .{
            .debug_allocator = std.heap.DebugAllocator(DebugAllocatorConfig){ .backing_allocator = std.heap.page_allocator },
            .panic_on_exit_leaks = panic_on_leaks,
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

/// Deinit handler for DebugAllocator
fn debugAllocatorDeinit(ptr: *anyopaque) void {
    const allocator: *align(@alignOf(DebugAllocator)) DebugAllocator = @alignCast(@ptrCast(ptr));
    allocator.deinit();
    std.heap.c_allocator.destroy(allocator);
}

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
        @compileError("DebugAllocatorCreateConfig size mismatch - expected " ++ DebugAllocatorCreateConfig_ExpectedSize ++ " byte, got " ++ @typeName(@TypeOf(@sizeOf(DebugAllocatorCreateConfig))));
    }

    if (@alignOf(DebugAllocatorCreateConfig) != DebugAllocatorCreateConfig_ExpectedAlign) {
        @compileError("DebugAllocatorCreateConfig alignment mismatch - expected " ++ DebugAllocatorCreateConfig_ExpectedAlign ++ " byte alignment, got " ++ @typeName(@TypeOf(@alignOf(DebugAllocatorCreateConfig))));
    }
}

/// Create a new `DebugAllocator` with the given configuration
export fn zig_debug_allocator_create(config_ptr: ?*const DebugAllocatorCreateConfig) callconv(.C) ?*anyopaque {
    if (config_ptr == null) {
        return null;
    }

    const config = config_ptr.?.*;
    const parent = std.heap.c_allocator.create(DebugAllocator) catch return null;
    parent.* = DebugAllocator.initWithConfig(config.panic_on_leaks);

    const allocator = std.heap.c_allocator.create(ffi.FfiAllocator) catch return null;
    allocator.* = ffi.init(
        @ptrCast(parent),
        debugAllocatorDeinit,
        parent.allocator(),
    );

    return @ptrCast(allocator);
}
