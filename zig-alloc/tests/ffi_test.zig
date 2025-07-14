const std = @import("std");
const testing = std.testing;
const zig_alloc = @import("zig-alloc");
const ffi = zig_alloc.ffi;
const smp_allocator = zig_alloc.smp;

test "FfiAllocator basic operations" {
    // Test with SMP allocator as backing allocator
    const ffi_allocator = try ffi.init_allocate(smp_allocator.SmpAllocator);
    defer ffi_allocator.deinit_allocated();
    
    // Test allocation
    const ptr = ffi_allocator.alloc(100, .fromByteUnits(1));
    try testing.expect(ptr != null);
    
    if (ptr) |p| {
        // Test writing to memory
        const bytes = @as([*]u8, @ptrCast(p));
        bytes[0] = 42;
        bytes[99] = 123;
        
        // Verify data
        try testing.expect(bytes[0] == 42);
        try testing.expect(bytes[99] == 123);
        
        // Test free
        ffi_allocator.free(p, 100, .fromByteUnits(1));
    }
}

test "FfiAllocator alignment" {
    const ffi_allocator = try ffi.init_allocate(smp_allocator.SmpAllocator);
    defer ffi_allocator.deinit_allocated();
    
    // Test various alignments
    const ptr1 = ffi_allocator.alloc(100, .fromByteUnits(1));
    try testing.expect(ptr1 != null);
    if (ptr1) |p| {
        try testing.expect(@intFromPtr(p) % 1 == 0);
        ffi_allocator.free(p, 100, .fromByteUnits(1));
    }
    
    const ptr8 = ffi_allocator.alloc(100, .fromByteUnits(8));
    try testing.expect(ptr8 != null);
    if (ptr8) |p| {
        try testing.expect(@intFromPtr(p) % 8 == 0);
        ffi_allocator.free(p, 100, .fromByteUnits(8));
    }
    
    const ptr16 = ffi_allocator.alloc(100, .fromByteUnits(16));
    try testing.expect(ptr16 != null);
    if (ptr16) |p| {
        try testing.expect(@intFromPtr(p) % 16 == 0);
        ffi_allocator.free(p, 100, .fromByteUnits(16));
    }
}

test "FfiAllocator realloc grow" {
    const ffi_allocator = try ffi.init_allocate(smp_allocator.SmpAllocator);
    defer ffi_allocator.deinit_allocated();
    
    // Initial allocation
    const ptr = ffi_allocator.alloc(10, .fromByteUnits(1));
    try testing.expect(ptr != null);
    
    if (ptr) |p| {
        // Fill with test data
        const bytes = @as([*]u8, @ptrCast(p));
        for (0..10) |i| {
            bytes[i] = @intCast(i);
        }
        
        // Grow allocation
        const new_ptr = ffi_allocator.realloc(p, 10, .fromByteUnits(1), 20, .fromByteUnits(1));
        try testing.expect(new_ptr != null);
        
        if (new_ptr) |np| {
            const new_bytes = @as([*]u8, @ptrCast(np));
            
            // Verify original data is preserved
            for (0..10) |i| {
                try testing.expect(new_bytes[i] == @as(u8, @intCast(i)));
            }
            
            ffi_allocator.free(np, 20, .fromByteUnits(1));
        }
    }
}

test "FfiAllocator realloc shrink" {
    const ffi_allocator = try ffi.init_allocate(smp_allocator.SmpAllocator);
    defer ffi_allocator.deinit_allocated();
    
    // Initial allocation
    const ptr = ffi_allocator.alloc(20, .fromByteUnits(1));
    try testing.expect(ptr != null);
    
    if (ptr) |p| {
        // Fill with test data
        const bytes = @as([*]u8, @ptrCast(p));
        for (0..20) |i| {
            bytes[i] = @intCast(i);
        }
        
        // Shrink allocation
        const new_ptr = ffi_allocator.realloc(p, 20, .fromByteUnits(1), 10, .fromByteUnits(1));
        try testing.expect(new_ptr != null);
        
        if (new_ptr) |np| {
            const new_bytes = @as([*]u8, @ptrCast(np));
            
            // Verify original data is preserved (first 10 bytes)
            for (0..10) |i| {
                try testing.expect(new_bytes[i] == @as(u8, @intCast(i)));
            }
            
            ffi_allocator.free(np, 10, .fromByteUnits(1));
        }
    }
}

test "FfiAllocator realloc to zero" {
    const ffi_allocator = try ffi.init_allocate(smp_allocator.SmpAllocator);
    defer ffi_allocator.deinit_allocated();
    
    // Initial allocation
    const ptr = ffi_allocator.alloc(10, .fromByteUnits(1));
    try testing.expect(ptr != null);
    
    if (ptr) |p| {
        // Realloc to zero size (should free the memory)
        const new_ptr = ffi_allocator.realloc(p, 10, .fromByteUnits(1), 0, .fromByteUnits(1));
        try testing.expect(new_ptr == null);
    }
}

test "FfiAllocator edge cases" {
    const ffi_allocator = try ffi.init_allocate(smp_allocator.SmpAllocator);
    defer ffi_allocator.deinit_allocated();
    
    // Test zero-size allocation (should return null)
    const zero_ptr = ffi_allocator.alloc(0, .fromByteUnits(1));
    try testing.expect(zero_ptr == null);
    
    // Test large alignment
    const aligned_ptr = ffi_allocator.alloc(64, .fromByteUnits(64));
    if (aligned_ptr) |p| {
        try testing.expect(@intFromPtr(p) % 64 == 0);
        ffi_allocator.free(p, 64, .fromByteUnits(64));
    }
}

test "opaquePtrToFfiAllocator null handling" {
    const result = ffi.opaquePtrToFfiAllocator(null);
    try testing.expect(result == null);
}

test "opaquePtrToFfiAllocator valid pointer" {
    const ffi_allocator = try ffi.init_allocate(smp_allocator.SmpAllocator);
    defer ffi_allocator.deinit_allocated();
    
    const ptr: *anyopaque = @ptrCast(ffi_allocator);
    const result = ffi.opaquePtrToFfiAllocator(ptr);
    try testing.expect(result != null);
    try testing.expect(result.? == ffi_allocator);
}