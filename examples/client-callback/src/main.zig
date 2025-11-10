const std = @import("std");
const ua = @import("ua");

/// Context structure to track callback invocations
const CallbackContext = struct {
    count: u32 = 0,
    last_value: ?f64 = null,
};

/// Callback function invoked when monitored value changes
fn temperatureCallback(
    userdata: ?*anyopaque,
    subscription_id: ua.SubscriptionId,
    monitored_item_id: ua.MonitoredItemId,
    value: *const ua.Variant,
) void {
    _ = subscription_id;
    _ = monitored_item_id;

    // Extract our context
    const ctx = @as(*CallbackContext, @ptrCast(@alignCast(userdata.?)));
    ctx.count += 1;

    // Extract and store the value
    if (value.* == .double) {
        ctx.last_value = value.double;
        std.log.info("[Callback #{d}] Temperature changed: {d:.2}°C", .{ ctx.count, value.double });
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create and start the server in a background thread
    const server_thread = try std.Thread.spawn(.{}, serverThread, .{allocator});
    defer server_thread.join();

    // Give the server time to start
    std.Thread.sleep(500 * std.time.ns_per_ms);

    // Run the client operations with callbacks
    try clientOperations();

    std.log.info("\nPress Ctrl-C to stop", .{});
    std.Thread.sleep(std.math.maxInt(u64)); // Wait for Ctrl-C
}

fn serverThread(allocator: std.mem.Allocator) !void {
    _ = allocator;

    var server = try ua.Server.init();
    defer server.deinit();

    // Add a temperature variable that we'll monitor
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "temperature"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Temperature"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(f64, 20.0),
            .display_name = ua.LocalizedText.init("en-US", "Temperature"),
            .description = ua.LocalizedText.init("en-US", "Room temperature sensor"),
            .access_level = .{ .read = true, .write = true },
        },
    );

    std.log.info("Server started on opc.tcp://localhost:4840", .{});
    try server.runUntilInterrupt();
}

fn clientOperations() !void {
    const client = try ua.Client.init();
    defer client.deinit();

    const server_url = "opc.tcp://localhost:4840";
    std.log.info("\n=== Client Callback Example ===", .{});
    std.log.info("Connecting to {s}...", .{server_url});
    try client.connect(server_url);
    defer client.disconnect() catch |err| {
        std.log.err("Failed to disconnect: {}", .{err});
    };

    const node_id = ua.NodeId.initString(1, "temperature");

    // Create a subscription with fast publishing for demonstration
    std.log.info("\nCreating subscription...", .{});
    const subscription_id = try client.createSubscription(.{
        .publishing_interval = 100.0, // 100ms for quick updates
        .priority = 10,
    });
    defer client.deleteSubscription(subscription_id) catch {};
    std.log.info("Subscription created (ID: {d})", .{subscription_id});

    // Create callback context
    var ctx = CallbackContext{};

    // Create monitored item with callback
    std.log.info("\nCreating monitored item with callback...", .{});
    const monitored_item_id = try client.createMonitoredItemWithCallback(
        subscription_id,
        .{
            .node_id = node_id,
            .sampling_interval = 50.0, // Sample every 50ms
            .queue_size = 10,
        },
        temperatureCallback,
        &ctx,
    );
    defer client.deleteMonitoredItem(subscription_id, monitored_item_id) catch {};
    std.log.info("Monitored item created (ID: {d})", .{monitored_item_id});

    std.log.info("\nWaiting for initial callback...", .{});
    _ = ua.c.UA_Client_run_iterate(client.handle, 200);
    std.Thread.sleep(100 * std.time.ns_per_ms);

    // Simulate temperature changes
    const temperatures = [_]f64{ 21.5, 22.0, 23.5, 24.0, 22.5 };
    for (temperatures, 0..) |temp, i| {
        std.log.info("\nWriting temperature value: {d:.2}°C", .{temp});
        try client.writeValueAttribute(node_id, ua.Variant.scalar(f64, temp));

        // Process client messages to trigger callback
        _ = ua.c.UA_Client_run_iterate(client.handle, 200);
        std.Thread.sleep(150 * std.time.ns_per_ms);
        _ = ua.c.UA_Client_run_iterate(client.handle, 200);

        // Show status after each change
        if (i < temperatures.len - 1) {
            std.Thread.sleep(500 * std.time.ns_per_ms);
        }
    }

    // Final summary
    std.log.info("\n=== Summary ===", .{});
    std.log.info("Total callbacks received: {d}", .{ctx.count});
    if (ctx.last_value) |value| {
        std.log.info("Last temperature: {d:.2}°C", .{value});
    }

    std.log.info("\n=== Callback example completed successfully! ===", .{});
    std.log.info("The callback was invoked {d} times during the example", .{ctx.count});
}
