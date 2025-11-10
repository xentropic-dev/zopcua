const std = @import("std");
const ua = @import("ua");
const test_helpers = @import("test_helpers");
const TestServer = test_helpers.TestServer;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Create and start server
    var test_server = try TestServer.init(allocator, 4840);
    defer test_server.deinit();

    try test_server.startAsync();
    defer test_server.stop() catch |err| {
        std.debug.print("Failed to stop test server: {}\n", .{err});
    };

    // Connect client
    var url_buf: [128]u8 = undefined;
    const endpoint_url = try test_server.getEndpointUrl(&url_buf);
    var client = try ua.Client.init();
    defer client.deinit();
    try client.connect(endpoint_url);
    defer client.disconnect() catch |err| {
        std.debug.print("Failed to disconnect client: {}\n", .{err});
    };

    // Test browsing
    std.debug.print("Testing browse functionality...\n", .{});

    // Test 1: Browse Objects folder
    std.debug.print("  Test 1: Browse Objects folder...\n", .{});
    var result = try client.browse(ua.StandardNodeId.objects_folder, allocator);
    defer result.deinit(allocator);

    // The Objects folder should have at least one child
    if (result.references.len == 0) {
        std.debug.print("    FAILED: Expected at least one reference\n", .{});
        return error.TestFailed;
    }
    if (result.status_code != ua.c.UA_STATUSCODE_GOOD) {
        std.debug.print("    FAILED: Expected GOOD status code\n", .{});
        return error.TestFailed;
    }
    std.debug.print("    PASSED: Found {} references\n", .{result.references.len});

    // Test 2: Verify browse result data
    std.debug.print("  Test 2: Verify browse result data...\n", .{});
    var valid_count: usize = 0;
    for (result.references) |ref| {
        if (ref.browse_name.name.len > 0 and ref.node_class != .unspecified) {
            valid_count += 1;
        }
    }
    if (valid_count != result.references.len) {
        std.debug.print("    FAILED: Some references have invalid data\n", .{});
        return error.TestFailed;
    }
    std.debug.print("    PASSED: All {} references have valid data\n", .{valid_count});

    std.debug.print("All browse tests passed!\n", .{});
}
