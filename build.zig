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

    const _00_baseline = b.addExecutable(.{
        .name = "00_baseline",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/00_baseline.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(_00_baseline);

    const _01_redo_floats = b.addExecutable(.{
        .name = "01_redo_floats",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/01_redo_floats.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(_01_redo_floats);
}
