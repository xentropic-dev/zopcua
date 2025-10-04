const std = @import("std");
const builtin = @import("builtin");

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

    const c_flags = &[_][]const u8{
        "-D_DARWIN_C_SOURCE",
        "-D_POSIX_C_SOURCE=200112L",
        "-std=c99",
    };

    lib.addCSourceFiles(.{
        .files = &.{
            "vendor/open62541.c",
            "vendor/helpers.c",
        },
        .flags = c_flags,
    });
    lib.addIncludePath(b.path("vendor"));

    // Add mbedtls for macOS
    if (target.result.os.tag == .macos) {
        const brew_prefix = if (target.result.cpu.arch == .aarch64)
            "/opt/homebrew"
        else
            "/usr/local";

        lib.addIncludePath(.{ .cwd_relative = b.fmt("{s}/include", .{brew_prefix}) });
        lib.addLibraryPath(.{ .cwd_relative = b.fmt("{s}/lib", .{brew_prefix}) });
    }

    lib.linkSystemLibrary("mbedtls");
    lib.linkSystemLibrary("mbedx509");
    lib.linkSystemLibrary("mbedcrypto");

    module.linkLibrary(lib);
    b.installArtifact(lib);

    // Unit tests
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib_unit_tests.addCSourceFiles(.{
        .files = &.{
            "vendor/open62541.c",
            "vendor/helpers.c",
        },
        .flags = c_flags,
    });
    lib_unit_tests.addIncludePath(b.path("vendor"));
    lib_unit_tests.linkLibC();

    // Add mbedtls for macOS (tests)
    if (target.result.os.tag == .macos) {
        const brew_prefix = if (target.result.cpu.arch == .aarch64)
            "/opt/homebrew"
        else
            "/usr/local";

        lib_unit_tests.addIncludePath(.{ .cwd_relative = b.fmt("{s}/include", .{brew_prefix}) });
        lib_unit_tests.addLibraryPath(.{ .cwd_relative = b.fmt("{s}/lib", .{brew_prefix}) });
    }

    lib_unit_tests.linkSystemLibrary("mbedtls");
    lib_unit_tests.linkSystemLibrary("mbedx509");
    lib_unit_tests.linkSystemLibrary("mbedcrypto");

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

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
