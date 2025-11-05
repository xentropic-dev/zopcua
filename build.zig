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
            // Allow __DATE__ and __TIME__ macros in open62541 v1.4.12 for release builds
            "-Wno-error=date-time",
        },
    });
    lib.addIncludePath(b.path("vendor"));

    linkMbedtls(b, lib, target, optimize, mbedtls_link);

    module.linkLibrary(lib);
    b.installArtifact(lib);

    const lib_unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
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

    // Variant memory lifecycle tests
    const variant_memory_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/variant_memory_test.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    variant_memory_tests.root_module.addImport("ua", module);
    variant_memory_tests.addCSourceFiles(.{
        .files = &.{
            "vendor/open62541.c",
            "vendor/helpers.c",
        },
        .flags = &.{
            "-D_DARWIN_C_SOURCE",
            "-D_POSIX_C_SOURCE=200112L",
            "-std=c99",
            "-fno-sanitize=undefined",
        },
    });
    variant_memory_tests.addIncludePath(b.path("vendor"));
    variant_memory_tests.linkLibC();
    linkMbedtls(b, variant_memory_tests, target, optimize, mbedtls_link);
    linkSystemLibraries(variant_memory_tests, target);

    const run_variant_memory_tests = b.addRunArtifact(variant_memory_tests);
    test_step.dependOn(&run_variant_memory_tests.step);

    // Separate step for just memory tests
    const memory_test_step = b.step("test-memory", "Run Variant memory lifecycle tests");
    memory_test_step.dependOn(&run_variant_memory_tests.step);

    // Test helpers module for integration tests
    const test_helpers_module = b.addModule("test_helpers", .{
        .root_source_file = b.path("tests/helpers/test_server.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_helpers_module.addImport("ua", module);

    // Helper function to create integration test executables
    const createIntegrationTest = struct {
        fn create(
            builder: *std.Build,
            name: []const u8,
            source: []const u8,
            tgt: std.Build.ResolvedTarget,
            opt: std.builtin.OptimizeMode,
            mod: *std.Build.Module,
            helpers: *std.Build.Module,
            mbedtls_mode: MbedtlsLinkMode,
        ) *std.Build.Step.Compile {
            const exe = builder.addExecutable(.{
                .name = name,
                .root_module = builder.createModule(.{
                    .root_source_file = builder.path(source),
                    .target = tgt,
                    .optimize = opt,
                }),
            });
            exe.root_module.addImport("ua", mod);
            exe.root_module.addImport("test_helpers", helpers);
            exe.addCSourceFiles(.{
                .files = &.{
                    "vendor/open62541.c",
                    "vendor/helpers.c",
                },
                .flags = &.{
                    "-D_DARWIN_C_SOURCE",
                    "-D_POSIX_C_SOURCE=200112L",
                    "-std=c99",
                    "-fno-sanitize=undefined",
                },
            });
            exe.addIncludePath(builder.path("vendor"));
            exe.linkLibC();
            linkMbedtls(builder, exe, tgt, opt, mbedtls_mode);
            linkSystemLibraries(exe, tgt);
            return exe;
        }
    }.create;

    // Legacy integration test (backward compatibility)
    const integration_test = createIntegrationTest(
        b,
        "integration_test",
        "tests/integration_test.zig",
        target,
        optimize,
        module,
        test_helpers_module,
        mbedtls_link,
    );
    const run_integration_test = b.addRunArtifact(integration_test);
    const integration_step = b.step("test-integration", "Run legacy integration tests");
    integration_step.dependOn(&run_integration_test.step);

    // New comprehensive integration tests
    const variant_scalar_test = createIntegrationTest(
        b,
        "variant_scalar_test",
        "tests/integration/variant_scalar_test.zig",
        target,
        optimize,
        module,
        test_helpers_module,
        mbedtls_link,
    );
    const run_variant_scalar = b.addRunArtifact(variant_scalar_test);
    const variant_scalar_step = b.step("test-variant-scalar", "Run Variant scalar integration tests");
    variant_scalar_step.dependOn(&run_variant_scalar.step);

    const variant_array_test = createIntegrationTest(
        b,
        "variant_array_test",
        "tests/integration/variant_array_test.zig",
        target,
        optimize,
        module,
        test_helpers_module,
        mbedtls_link,
    );
    const run_variant_array = b.addRunArtifact(variant_array_test);
    const variant_array_step = b.step("test-variant-array", "Run Variant array integration tests");
    variant_array_step.dependOn(&run_variant_array.step);

    const concurrent_test = createIntegrationTest(
        b,
        "concurrent_test",
        "tests/integration/concurrent_test.zig",
        target,
        optimize,
        module,
        test_helpers_module,
        mbedtls_link,
    );
    const run_concurrent = b.addRunArtifact(concurrent_test);
    const concurrent_step = b.step("test-concurrent", "Run concurrent access integration tests");
    concurrent_step.dependOn(&run_concurrent.step);

    // Comprehensive integration test suite
    const integration_all_step = b.step("test-integration-all", "Run all integration tests");
    integration_all_step.dependOn(&run_integration_test.step);
    integration_all_step.dependOn(&run_variant_scalar.step);
    integration_all_step.dependOn(&run_variant_array.step);
    integration_all_step.dependOn(&run_concurrent.step);

    // Quick integration tests (non-concurrent for faster CI)
    const integration_quick_step = b.step("test-integration-quick", "Run quick integration tests (no concurrent)");
    integration_quick_step.dependOn(&run_variant_scalar.step);
    integration_quick_step.dependOn(&run_variant_array.step);

    const docs_lib = b.addLibrary(.{
        .name = "ua",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
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
