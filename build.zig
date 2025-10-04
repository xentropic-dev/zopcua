const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("ua", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const lib = b.addLibrary(.{ .name = "ua", .linkage = .static, .root_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    }) });

    lib.addCSourceFiles(.{
        .files = &.{
            "vendor/open62541.c",
            "vendor/helpers.c",
        },
        .flags = &.{
            "-D__DATE__=\"1970-01-01\"",
            "-D__TIME__=\"00:00:00\"",
            "-D_DARWIN_C_SOURCE",
            "-D_POSIX_C_SOURCE=200112L",
            "-std=c99",
        },
    });
    lib.addIncludePath(b.path("vendor"));

    module.linkLibrary(lib);
    b.installArtifact(lib);

    // Documentation generation
    const docs_lib = b.addStaticLibrary(.{
        .name = "ua",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const docs_step = b.step("docs", "Generate documentation");
    const install_docs = b.addInstallDirectory(.{
        .source_dir = docs_lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    docs_step.dependOn(&install_docs.step);
}
