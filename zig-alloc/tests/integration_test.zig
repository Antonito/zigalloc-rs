const std = @import("std");
const testing = std.testing;
const zig_alloc = @import("zig-alloc");

test "Integration: FFI layer basic functionality" {
    // Test that we can create and use FfiAllocators through the direct API
    const smp_ffi = try zig_alloc.ffi.init_allocate(zig_alloc.smp.SmpAllocator);
    defer smp_ffi.deinit_allocated();
    
    // Test allocation and deallocation
    const ptr = smp_ffi.alloc(100, std.mem.Alignment.fromByteUnits(1));
    try testing.expect(ptr != null);
    
    if (ptr) |p| {
        smp_ffi.free(p, 100, std.mem.Alignment.fromByteUnits(1));
    }
}

test "Integration: All allocator types can be created" {
    // Test that all allocator types can be instantiated
    var smp_allocator = zig_alloc.smp.SmpAllocator.init();
    defer smp_allocator.deinit();
    
    var debug_allocator = zig_alloc.debug.DebugAllocator.initWithConfig(false);
    defer debug_allocator.deinit();
    
    var arena_allocator = zig_alloc.arena_smp.ArenaSmpAllocator.init();
    defer arena_allocator.deinit();
    
    // Test that they all provide allocator interface
    const smp_alloc = smp_allocator.allocator();
    const debug_alloc = debug_allocator.allocator();
    const arena_alloc = arena_allocator.allocator();
    
    // Test basic allocations
    const smp_mem = try smp_alloc.alloc(u8, 10);
    defer smp_alloc.free(smp_mem);
    
    const debug_mem = try debug_alloc.alloc(u8, 10);
    defer debug_alloc.free(debug_mem);
    
    const arena_mem = try arena_alloc.alloc(u8, 10);
    // Arena memory freed when arena is deinitialized
    _ = arena_mem;
}