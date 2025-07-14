//! Root module for Zig allocators with FFI support.
//! 
//! This module organizes various allocator implementations that can be used
//! from other languages through the C ABI. All allocators follow a consistent
//! pattern using the FfiAllocator abstraction.

const std = @import("std");

/// Arena allocator backed by the SMP allocator
pub const arena_smp = @import("arena_smp_allocator.zig");

/// Debug allocator with leak detection and safety features
pub const debug = @import("debug_allocator.zig");

/// Thread-safe general-purpose allocator
pub const smp = @import("smp_allocator.zig");

/// FFI utilities for C-compatible allocator interface
pub const ffi = @import("ffi.zig");

/// FFI export functions for C ABI
pub const ffi_exports = @import("ffi_exports.zig");

// Validation pattern to ensure all export functions are included in the final library
comptime {
    // Reference modules to ensure their export functions are included
    _ = arena_smp;
    _ = debug;
    _ = smp;
    _ = ffi_exports;
}

