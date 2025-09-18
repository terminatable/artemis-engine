const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Print build info
    std.debug.print("\n╭─────────────────────────────────────────╮\n", .{});
    std.debug.print("│        Artemis Engine 1.0.0            │\n", .{});
    std.debug.print("│        Modular Foundation               │\n", .{});
    std.debug.print("╰─────────────────────────────────────────╯\n", .{});
    std.debug.print("Target: {}\n", .{target.result});
    std.debug.print("Optimize: {}\n", .{optimize});
    std.debug.print("─────────────────────────────────────────\n\n", .{});

    // Create module
    const artemis_engine = b.addModule("artemis-engine", .{
        .root_source_file = b.path("src/artemis.zig"),
    });

    // Core test
    const core_test = b.addExecutable(.{
        .name = "artemis-core-test",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/test_core.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_core_test = b.addRunArtifact(core_test);
    const test_step = b.step("test", "Run core tests");
    test_step.dependOn(&run_core_test.step);

    // Basic example
    const basic_example = b.addExecutable(.{
        .name = "artemis-basic",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/basic.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    basic_example.root_module.addImport("artemis-engine", artemis_engine);

    const run_basic = b.addRunArtifact(basic_example);
    const basic_step = b.step("run-basic", "Run basic example");
    basic_step.dependOn(&run_basic.step);

    // All examples
    const examples_step = b.step("examples", "Run all examples");
    examples_step.dependOn(basic_step);

    // Benchmark
    const bench_exe = b.addExecutable(.{
        .name = "artemis-bench",
        .root_module = b.createModule(.{
            .root_source_file = b.path("bench/main.zig"),
            .target = target,
            .optimize = .ReleaseFast,
        }),
    });
    bench_exe.root_module.addImport("artemis-engine", artemis_engine);

    const run_bench = b.addRunArtifact(bench_exe);
    const bench_step = b.step("bench", "Run benchmarks");
    bench_step.dependOn(&run_bench.step);

    std.debug.print("✨ Build system ready!\n", .{});
    std.debug.print("Commands: test, run-basic, examples, bench\n\n", .{});
}