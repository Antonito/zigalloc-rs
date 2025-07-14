const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // This creates a "module", which represents a collection of source files alongside
    // some compilation options, such as optimization mode and linked system libraries.
    // Every executable or library we compile will be based on one or more modules.
    const lib_mod = b.createModule(.{
        // `root_source_file` is the Zig "entry point" of the module. If a module
        // only contains e.g. external object files, you can make this `null`.
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Now, we will create a static library based on the module we created above.
    // This creates a `std.Build.Step.Compile`, which is the build step responsible
    // for actually invoking the compiler.
    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "zigalloc",
        .root_module = lib_mod,
    });

    // https://github.com/ziglang/zig/issues/6817#issuecomment-736129115
    lib.bundle_compiler_rt = true;
    lib.pie = true;

    // Link against libc since we use std.heap.c_allocator
    lib.linkLibC();

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    // Create test step
    const test_step = b.step("test", "Run unit tests");

    // Automatically discover test files in the tests directory
    var tests_dir = std.fs.cwd().openDir("tests", .{ .iterate = true }) catch {
        // No tests directory found or error accessing it, skip tests
        return;
    };
    defer tests_dir.close();

    var iterator = tests_dir.iterate();
    while (iterator.next() catch null) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".zig")) continue;

        const test_file_path = b.fmt("tests/{s}", .{entry.name});
        const test_exe = b.addTest(.{
            .root_source_file = b.path(test_file_path),
            .target = target,
            .optimize = optimize,
        });

        // Add the library module as a dependency
        test_exe.root_module.addImport("zig-alloc", lib_mod);

        // Link against libc for tests
        test_exe.linkLibC();

        const run_test = b.addRunArtifact(test_exe);
        test_step.dependOn(&run_test.step);
    }
}
