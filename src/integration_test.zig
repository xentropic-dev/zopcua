const std = @import("std");
const ua = @import("root.zig");

// Test calling Server.init - narrow down the issue
test "integration: call server init" {
    std.debug.print("\n=== Test call server init ===\n", .{});
    const testing = std.testing;

    std.debug.print("[1] Before Server.init() call\n", .{});

    // Try to init server
    var server = ua.Server.init() catch |err| {
        std.debug.print("[ERROR] Server.init() failed: {}\n", .{err});
        return err;
    };

    std.debug.print("[2] Server.init() returned\n", .{});
    defer server.deinit();

    std.debug.print("[3] Test complete\n", .{});
    try testing.expect(true);
}
