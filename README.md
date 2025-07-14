# Zig Allocator for Rust

Zig allocators for Rust applications, primarily useful for development and debugging.

## ⚠️ Important Notice

**This is a development/debugging tool, not a production allocator.**

While Zig's allocators are production ready, this particular library hasn't been properly benchmarked.

For production applications, use proven allocators like [jemalloc](https://github.com/jemalloc/jemalloc) or [mimalloc](https://github.com/microsoft/mimalloc).

## Quick Start

Add to your `Cargo.toml`:

```toml
[dependencies]
zigalloc = { git = "https://github.com/Antonito/zigalloc-rs" }
```

**Requirements**:
- Rust nightly (for `#![feature(allocator_api)]`)
- zig 0.14.0

## Available Allocators

### Custom Allocators (using allocator API)
- **`ZigSmpAllocator`** - Thread-safe general-purpose allocator ([SmpAllocator](https://ziglang.org/documentation/master/std/#std.heap.SmpAllocator))
- **`ZigArenaSmpAllocator`** - Arena allocator for bulk deallocation ([ArenaAllocator](https://ziglang.org/documentation/master/std/#std.heap.ArenaAllocator))
- **`ZigDebugAllocator`** - Debug allocator with leak detection ([DebugAllocator](https://ziglang.org/documentation/master/std/#std.heap.DebugAllocator))

### Global Allocators (drop-in replacements)
- **`ZigGlobalDebugAllocator`** - Global debug allocator for app-wide leak detection
- **`ZigGlobalSmpAllocator`** - Global SMP allocator for performance testing
- **`ZigGlobalArenaSmpAllocator`** - Global arena allocator (mainly for testing)

## Usage Examples

### Memory Leak Detection (scopped)

```rust
#![feature(allocator_api)]
use zigalloc::ZigDebugAllocator;

fn main() {
    let allocator = ZigDebugAllocator::new();

    let mut vec = Vec::<u8, &ZigDebugAllocator>::with_capacity_in(1000, &allocator);
    vec.push(42);

    // Memory leaks will be reported when allocator is dropped
}
```

### Memory Leak Detection (app-wide)

```rust
use zigalloc::ZigGlobalDebugAllocator;

#[global_allocator]
static GLOBAL: ZigGlobalDebugAllocator = ZigGlobalDebugAllocator;

fn main() {
    // All allocations are now tracked for leaks
    let vec = vec![1, 2, 3, 4, 5];
    let map = std::collections::HashMap::new();
}
```

## Running Examples

The repository includes simple examples for each allocator:

```sh
# Custom allocator examples
cargo run --example smp_allocator
cargo run --example arena_allocator
cargo run --example debug_allocator

# Global allocator examples
cargo run --example global_debug_allocator
cargo run --example global_smp_allocator
cargo run --example global_arena_allocator
```

## Building

The build process automatically:
1. Compiles the Zig allocator library
2. Links it statically into your Rust binary
3. No manual Zig installation required

> `zig` needs to be installed on the machine
