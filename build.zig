const std = @import("std");
const builtin = @import("builtin");

const MbedtlsLinkMode = enum { static, system };

pub const SetupOptions = struct {
    mbedtls: MbedtlsLinkMode = .static,
};

/// Setup function for downstream users.
/// Example:
///   const ua = @import("ua");
///   pub fn build(b: *std.Build) void {
///       const exe = b.addExecutable(.{ ... });
///       ua.setup(exe, .{});
///   }
pub fn setup(step: *std.Build.Step.Compile, opts: SetupOptions) void {
    const ua = step.step.owner.dependencyFromBuildZig(@This(), .{
        .mbedtls = opts.mbedtls,
    });
    step.root_module.addImport("ua", ua.module("ua"));

    linkSystemLibraries(step, step.root_module.resolved_target.?);
}

/// Links platform-specific system libraries required by open62541
fn linkSystemLibraries(step: *std.Build.Step.Compile, target: std.Build.ResolvedTarget) void {
    switch (target.result.os.tag) {
        .windows => {
            step.linkSystemLibrary("ws2_32");
            step.linkSystemLibrary("advapi32");
            step.linkSystemLibrary("crypt32");
            step.linkSystemLibrary("bcrypt");
            step.linkSystemLibrary("iphlpapi");
        },
        .macos => {
            step.linkFramework("Security");
            step.linkFramework("CoreFoundation");
        },
        else => {},
    }
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mbedtls_link = b.option(
        MbedtlsLinkMode,
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

    lib.addCSourceFiles(.{
        .files = &.{
            "vendor/open62541.c",
            "vendor/helpers.c",
        },
        .flags = &.{
            "-D_DARWIN_C_SOURCE",
            "-D_POSIX_C_SOURCE=200112L",
            "-std=c99",
            // Disable UB sanitizer for open62541 v1.4.12
            // This version has a memcpy(NULL, NULL, 0) case in writeValueAttributeWithoutRange
            // when handling scalar values with arrayDimensionsSize=0, which is technically UB
            // but works in practice. Fixed in later versions of open62541.
            // See: vendor/open62541.c line ~39788
            "-fno-sanitize=undefined",
        },
    });
    lib.addIncludePath(b.path("vendor"));

    linkMbedtls(b, lib, target, optimize, mbedtls_link);

    module.linkLibrary(lib);
    b.installArtifact(lib);

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
        .flags = &.{
            "-D_DARWIN_C_SOURCE",
            "-D_POSIX_C_SOURCE=200112L",
            "-std=c99",
            // See comment above in lib.addCSourceFiles for why this is needed
            "-fno-sanitize=undefined",
        },
    });
    lib_unit_tests.addIncludePath(b.path("vendor"));
    lib_unit_tests.linkLibC();

    linkMbedtls(b, lib_unit_tests, target, optimize, mbedtls_link);
    linkSystemLibraries(lib_unit_tests, target);

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    // Integration tests (run as executable, not unit test)
    const integration_test = b.addExecutable(.{
        .name = "integration_test",
        .root_source_file = b.path("tests/integration_test.zig"),
        .target = target,
        .optimize = optimize,
    });
    integration_test.root_module.addImport("ua", module);
    integration_test.addCSourceFiles(.{
        .files = &.{
            "vendor/open62541.c",
            "vendor/helpers.c",
        },
        .flags = &.{
            "-D_DARWIN_C_SOURCE",
            "-D_POSIX_C_SOURCE=200112L",
            "-std=c99",
            // See comment above in lib.addCSourceFiles for why this is needed
            "-fno-sanitize=undefined",
        },
    });
    integration_test.addIncludePath(b.path("vendor"));
    integration_test.linkLibC();
    linkMbedtls(b, integration_test, target, optimize, mbedtls_link);
    linkSystemLibraries(integration_test, target);

    const run_integration_test = b.addRunArtifact(integration_test);
    const integration_step = b.step("test-integration", "Run integration tests");
    integration_step.dependOn(&run_integration_test.step);

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
    link_mode: MbedtlsLinkMode,
) void {
    switch (link_mode) {
        .static => {
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
            if (target.result.os.tag == .macos) {
                const brew_prefix = if (target.result.cpu.arch == .aarch64)
                    "/opt/homebrew"
                else
                    "/usr/local";
                step.addIncludePath(.{ .cwd_relative = b.fmt("{s}/include", .{brew_prefix}) });
                step.addLibraryPath(.{ .cwd_relative = b.fmt("{s}/lib", .{brew_prefix}) });
            }

            step.linkSystemLibrary("mbedtls");
            step.linkSystemLibrary("mbedx509");
            step.linkSystemLibrary("mbedcrypto");
        },
    }
}
