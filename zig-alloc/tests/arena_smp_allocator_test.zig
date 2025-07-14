const std = @import("std");
const testing = std.testing;
const zig_alloc = @import("zig-alloc");
const arena_smp_allocator = zig_alloc.arena_smp;

test "ArenaSmpAllocator basic functionality" {
    var allocator_instance = arena_smp_allocator.ArenaSmpAllocator.init();
    defer allocator_instance.deinit();
    
    const allocator = allocator_instance.allocator();
    
    // Test basic allocation
    const ptr = try allocator.alloc(u8, 100);
    
    // Note: Arena allocators don't require individual frees
    // defer allocator.free(ptr); // Not needed for arena
    
    // Test writing to allocated memory
    for (ptr, 0..) |*byte, i| {
        byte.* = @intCast(i % 256);
    }
    
    // Verify data integrity
    for (ptr, 0..) |byte, i| {
        try testing.expect(byte == @as(u8, @intCast(i % 256)));
    }
}

test "ArenaSmpAllocator multiple allocations" {
    var allocator_instance = arena_smp_allocator.ArenaSmpAllocator.init();
    defer allocator_instance.deinit();
    
    const allocator = allocator_instance.allocator();
    
    // Test multiple allocations of different sizes
    const ptr1 = try allocator.alloc(u32, 10);
    const ptr2 = try allocator.alloc(u8, 50);
    const ptr3 = try allocator.alloc(u64, 5);
    
    // No individual frees needed for arena allocator
    
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

test "ArenaSmpAllocator many small allocations" {
    var allocator_instance = arena_smp_allocator.ArenaSmpAllocator.init();
    defer allocator_instance.deinit();
    
    const allocator = allocator_instance.allocator();
    
    // Arena allocators are great for many small allocations
    var ptrs: [100]*u32 = undefined;
    
    for (&ptrs, 0..) |*ptr, i| {
        const item = try allocator.create(u32);
        ptr.* = item;
        ptr.*.* = @intCast(i);
    }
    
    // Verify all allocations
    for (ptrs, 0..) |ptr, i| {
        try testing.expect(ptr.* == @as(u32, @intCast(i)));
    }
    
    // All memory will be freed when arena is deinitialized
}

test "ArenaSmpAllocator alignment" {
    var allocator_instance = arena_smp_allocator.ArenaSmpAllocator.init();
    defer allocator_instance.deinit();
    
    const allocator = allocator_instance.allocator();
    
    // Test various alignments
    const ptr1 = try allocator.alignedAlloc(u8, 1, 100);
    try testing.expect(@intFromPtr(ptr1.ptr) % 1 == 0);
    
    const ptr2 = try allocator.alignedAlloc(u8, 8, 100);
    try testing.expect(@intFromPtr(ptr2.ptr) % 8 == 0);
    
    const ptr3 = try allocator.alignedAlloc(u8, 16, 100);
    try testing.expect(@intFromPtr(ptr3.ptr) % 16 == 0);
}

test "ArenaSmpAllocator bulk pattern" {
    var allocator_instance = arena_smp_allocator.ArenaSmpAllocator.init();
    defer allocator_instance.deinit();
    
    const allocator = allocator_instance.allocator();
    
    // Simulate a typical use case: parse some data structures
    const num_items = 50;
    
    // Allocate array of pointers
    const items = try allocator.alloc(*u64, num_items);
    
    // Allocate each item
    for (items, 0..) |*item_ptr, i| {
        const item = try allocator.create(u64);
        item.* = @intCast(i * i); // Some computation
        item_ptr.* = item;
    }
    
    // Verify all items
    for (items, 0..) |item_ptr, i| {
        const expected = @as(u64, @intCast(i * i));
        try testing.expect(item_ptr.* == expected);
    }
    
    // Everything gets freed at once when arena is deinitialized
}