const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a client with custom configuration
    // This example demonstrates how to configure:
    // - Custom timeout (15 seconds instead of default 5 seconds)
    // - Custom secure channel lifetime (5 minutes instead of default 10 minutes)
    // - Custom session timeout (10 minutes instead of default 20 minutes)
    // - Connectivity check enabled (check every 5 seconds)
    // - Automatic reconnection disabled
    var client = try ua.Client.initWithConfig(.{
        .timeout = 15000, // 15 seconds
        .secure_channel_lifetime = 300000, // 5 minutes
        .requested_session_timeout = 600000, // 10 minutes
        .connectivity_check_interval = 5000, // Check every 5 seconds
        .no_reconnect = true, // Disable auto-reconnect for this example
    });
    defer client.deinit();

    // Get server URL from command line args or use default
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const url = if (args.len > 1) args[1] else "opc.tcp://localhost:4840";

    std.log.info("=== Custom Configuration Client ===", .{});
    std.log.info("Client configured with custom settings:", .{});
    std.log.info("  - Timeout: 15000ms (custom)", .{});
    std.log.info("  - Secure channel lifetime: 300000ms (custom)", .{});
    std.log.info("  - Session timeout: 600000ms (custom)", .{});
    std.log.info("  - Connectivity check: every 5000ms (custom)", .{});
    std.log.info("  - Auto-reconnect: disabled (custom)", .{});
    std.log.info("", .{});
    std.log.info("Connecting to {s}...", .{url});

    client.connect(url) catch |err| {
        std.log.err("Failed to connect to server: {}", .{err});
        std.log.info("", .{});
        std.log.info("Make sure a server is running at {s}", .{url});
        std.log.info("You can use the server-simple or server-custom-config example", .{});
        return err;
    };
    defer client.disconnect() catch |err| {
        std.log.err("Failed to disconnect: {}", .{err});
    };

    std.log.info("Connected successfully!", .{});
    std.log.info("", .{});

    // Try to read the standard server status node
    const server_status_node = ua.NodeId.initNumeric(0, 2256); // ServerStatus node
    std.log.info("Reading ServerStatus node (ns=0;i=2256)...", .{});

    const server_status_result = client.readValueAttribute(allocator, server_status_node) catch |err| {
        std.log.warn("Could not read ServerStatus node: {}", .{err});
        std.log.info("This is normal if the server doesn't expose this node", .{});
        return;
    };
    defer server_status_result.deinit(allocator);

    std.log.info("Successfully read ServerStatus node!", .{});
    std.log.info("Value type: {s}", .{@tagName(server_status_result)});

    // Try to read a custom variable if connecting to our example servers
    std.log.info("", .{});
    std.log.info("Attempting to read example variables...", .{});

    // Try "the answer" from server-simple
    const answer_node = ua.NodeId.initString(1, "the.answer");
    if (client.readValueAttribute(allocator, answer_node)) |answer_value| {
        defer answer_value.deinit(allocator);
        std.log.info("✓ Read 'the.answer': {}", .{answer_value.int32});
    } else |_| {
        std.log.info("  'the.answer' not found (not connected to server-simple)", .{});
    }

    // Try "temperature" from server-custom-config
    const temp_node = ua.NodeId.initString(1, "temperature");
    if (client.readValueAttribute(allocator, temp_node)) |temp_value| {
        defer temp_value.deinit(allocator);
        std.log.info("✓ Read 'temperature': {d} °C", .{temp_value.double});
    } else |_| {
        std.log.info("  'temperature' not found (not connected to server-custom-config)", .{});
    }

    // Try "counter" from server-custom-config
    const counter_node = ua.NodeId.initString(1, "counter");
    if (client.readValueAttribute(allocator, counter_node)) |counter_value| {
        defer counter_value.deinit(allocator);
        std.log.info("✓ Read 'counter': {}", .{counter_value.uint32});
    } else |_| {
        std.log.info("  'counter' not found (not connected to server-custom-config)", .{});
    }

    std.log.info("", .{});
    std.log.info("Client demonstration complete!", .{});
}
