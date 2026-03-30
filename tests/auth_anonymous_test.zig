const std = @import("std");
const ua = @import("ua");
const test_helpers = @import("test_helpers");
const TestServer = test_helpers.TestServer;
const fixtures = test_helpers.fixtures;
const assertions = test_helpers.assertions;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    
    std.debug.print("\n=== Running Authentication Integration Tests ===\n", .{});
    
    // Test 1: Basic anonymous authentication (default OPC UA behavior)
    std.debug.print("\nTest 1: Basic anonymous authentication\n", .{});
    
    // Create and setup server
    var test_server = try TestServer.init(allocator, 4840);
    defer test_server.deinit();

    const nodes = try fixtures.setupStandardNodes(&test_server.server);
    try test_server.startAsync();
    defer {
        test_server.stop() catch |err| {
            std.debug.print("Failed to stop test server: {}\n", .{err});
        };
    }

    // Connect client with anonymous authentication (default)
    var url_buf: [128]u8 = undefined;
    const endpoint_url = try test_server.getEndpointUrl(&url_buf);
    
    var client = try ua.Client.init();
    defer client.deinit();
    try client.connect(endpoint_url);
    defer {
        client.disconnect() catch |err| {
            std.debug.print("Failed to disconnect client: {}\n", .{err});
        };
    }

    // Verify we can read a value (connection works)
    const initial = try client.readValueAttribute(allocator, nodes.boolean);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(
        ua.Variant.scalar(bool, fixtures.TestScalarData.boolean_value),
        initial,
    );

    std.debug.print("✓ Anonymous authentication works\n", .{});
    
    // Test 2: Verify authentication API exists (compile-time check)
    std.debug.print("\nTest 2: Authentication API compile-time checks\n", .{});
    
    // Check that AuthenticationConfig exists and can be created
    const anonymous_config = ua.AuthenticationConfig{
        .identity_token = .anonymous,
    };
    _ = anonymous_config;
    
    std.debug.print("✓ Authentication API compiles correctly\n", .{});
    
    std.debug.print("\n=== Authentication integration tests passed! ===\n", .{});
}