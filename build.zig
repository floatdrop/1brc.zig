const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const create_measurements = b.addExecutable(.{
        .name = "create_measurements",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/create_measurements.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(create_measurements);

    const baseline = b.addExecutable(.{
        .name = "baseline",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/baseline.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(baseline);
}
