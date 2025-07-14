#![feature(allocator_api)]

//! zigalloc-rs
//!
//! Exposes Zig allocators to Rust
//!

/// FFI bindings
mod ffi;

/// Debug allocator
mod debug;
pub use debug::ZigDebugAllocator;

/// Debug global allocator
mod debug_global;
pub use debug_global::ZigGlobalDebugAllocator;

/// SMP allocator
///
/// High performance, multi-thread
mod smp;
pub use smp::ZigSmpAllocator;

/// Arena SMP
mod arena_smp;
pub use arena_smp::ZigArenaSmpAllocator;

/// SMP global allocator
mod smp_global;
pub use smp_global::ZigGlobalSmpAllocator;

/// Arena SMP global allocator
mod arena_smp_global;
pub use arena_smp_global::ZigGlobalArenaSmpAllocator;
