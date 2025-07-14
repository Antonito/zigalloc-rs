const std = @import("std");
const testing = std.testing;
const zig_alloc = @import("zig-alloc");
const smp_allocator = zig_alloc.smp;

test "SmpAllocator basic functionality" {
    var allocator_instance = smp_allocator.SmpAllocator.init();
    defer allocator_instance.deinit();
    
    const allocator = allocator_instance.allocator();
    
    // Test basic allocation
    const ptr = try allocator.alloc(u8, 100);
    defer allocator.free(ptr);
    
    // Test writing to allocated memory
    for (ptr, 0..) |*byte, i| {
        byte.* = @intCast(i % 256);
    }
    
    // Verify data integrity
    for (ptr, 0..) |byte, i| {
        try testing.expect(byte == @as(u8, @intCast(i % 256)));
    }
}

test "SmpAllocator multiple allocations" {
    var allocator_instance = smp_allocator.SmpAllocator.init();
    defer allocator_instance.deinit();
    
    const allocator = allocator_instance.allocator();
    
    // Test multiple allocations of different sizes
    const ptr1 = try allocator.alloc(u32, 10);
    const ptr2 = try allocator.alloc(u8, 50);
    const ptr3 = try allocator.alloc(u64, 5);
    
    defer allocator.free(ptr1);
    defer allocator.free(ptr2);
    defer allocator.free(ptr3);
    
    // Verify allocations are different
    try testing.expect(@intFromPtr(ptr1.ptr) != @intFromPtr(ptr2.ptr));
    try testing.expect(@intFromPtr(ptr1.ptr) != @intFromPtr(ptr3.ptr));
    try testing.expect(@intFromPtr(ptr2.ptr) != @intFromPtr(ptr3.ptr));
    
    // Test writing to all allocations
    for (ptr1, 0..) |*val, i| {
        val.* = @intCast(i);
    }
    for (ptr2, 0..) |*val, i| {
        val.* = @intCast(i);
    }
    for (ptr3, 0..) |*val, i| {
        val.* = @intCast(i);
    }
}

test "SmpAllocator realloc" {
    var allocator_instance = smp_allocator.SmpAllocator.init();
    defer allocator_instance.deinit();
    
    const allocator = allocator_instance.allocator();
    
    // Start with small allocation
    var ptr = try allocator.alloc(u8, 10);
    
    // Fill with test data
    for (ptr, 0..) |*byte, i| {
        byte.* = @intCast(i);
    }
    
    // Grow allocation
    ptr = try allocator.realloc(ptr, 20);
    defer allocator.free(ptr);
    
    // Verify original data is preserved
    for (ptr[0..10], 0..) |byte, i| {
        try testing.expect(byte == @as(u8, @intCast(i)));
    }
    
    // Fill new space
    for (ptr[10..], 10..) |*byte, i| {
        byte.* = @intCast(i);
    }
}

test "SmpAllocator alignment" {
    var allocator_instance = smp_allocator.SmpAllocator.init();
    defer allocator_instance.deinit();
    
    const allocator = allocator_instance.allocator();
    
    // Test various alignments
    const ptr1 = try allocator.alignedAlloc(u8, 1, 100);
    defer allocator.free(ptr1);
    try testing.expect(@intFromPtr(ptr1.ptr) % 1 == 0);
    
    const ptr2 = try allocator.alignedAlloc(u8, 8, 100);
    defer allocator.free(ptr2);
    try testing.expect(@intFromPtr(ptr2.ptr) % 8 == 0);
    
    const ptr3 = try allocator.alignedAlloc(u8, 16, 100);
    defer allocator.free(ptr3);
    try testing.expect(@intFromPtr(ptr3.ptr) % 16 == 0);
}