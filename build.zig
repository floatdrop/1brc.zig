const std = @import("std");

pub fn addBinary(b: *std.Build, name: []const u8, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    var buffer: [100]u8 = undefined;
    const path = std.fmt.bufPrint(&buffer, "src/{s}.zig", .{name}) catch unreachable;

    const exe = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = b.path(path),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    addBinary(b, "00_baseline", target, optimize);
    addBinary(b, "01_redo_floats", target, optimize);
    addBinary(b, "02_direct_simd_search", target, optimize);
    addBinary(b, "03_optimize_reading", target, optimize);
    addBinary(b, "04_arena_allocator", target, optimize);
    addBinary(b, "05_parallel", target, optimize);
    addBinary(b, "06_short_hash", target, optimize);

    addBinary(b, "check_collisions", target, optimize);
    addBinary(b, "create_measurements", target, optimize);
}
