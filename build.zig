const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add build option for mbedtls linking strategy
    const mbedtls_link = b.option(
        enum { static, system },
        "mbedtls",
        "Link mbedtls statically (vendored) or use system libraries (default: static)",
    ) orelse .static;

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

    // Link mbedtls based on build option
    linkMbedtls(b, lib, target, optimize, mbedtls_link);

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

    // Link mbedtls for tests
    linkMbedtls(b, lib_unit_tests, target, optimize, mbedtls_link);

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

fn linkMbedtls(
    b: *std.Build,
    step: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    link_mode: enum { static, system },
) void {
    switch (link_mode) {
        .static => {
            // Use vendored mbedtls
            const mbedtls = b.dependency("libmbedtls", .{
                .target = target,
                .optimize = optimize,
            });
            step.addIncludePath(mbedtls.path("vendor/include"));
            step.linkLibrary(mbedtls.artifact("mbedtls"));
            step.linkLibrary(mbedtls.artifact("mbedcrypto"));
            step.linkLibrary(mbedtls.artifact("mbedx509"));
        },
        .system => {
            // Use system mbedtls
            if (target.result.os.tag == .macos) {
                const brew_prefix = if (target.result.cpu.arch == .aarch64)
                    "/opt/homebrew"
                else
                    "/usr/local";
                step.addIncludePath(.{ .cwd_relative = b.fmt("{s}/include", .{brew_prefix}) });
                step.addLibraryPath(.{ .cwd_relative = b.fmt("{s}/lib", .{brew_prefix}) });
            }
            // On Linux, pkg-config or standard paths should find it
            // On Windows with vcpkg, you'd set VCPKG_ROOT and add those paths here

            step.linkSystemLibrary("mbedtls");
            step.linkSystemLibrary("mbedx509");
            step.linkSystemLibrary("mbedcrypto");
        },
    }
}
