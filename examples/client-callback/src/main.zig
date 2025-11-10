const std = @import("std");
const ua = @import("ua");

/// Context structure to track callback invocations for temperature
const TemperatureContext = struct {
    count: u32 = 0,
    last_value: ?f64 = null,
};

/// Context structure to track callback invocations for status messages
const StatusContext = struct {
    count: u32 = 0,
};

/// Callback function invoked when temperature changes
fn temperatureCallback(
    userdata: ?*anyopaque,
    subscription_id: ua.SubscriptionId,
    monitored_item_id: ua.MonitoredItemId,
    value: *const ua.Variant,
) void {
    _ = subscription_id;
    _ = monitored_item_id;

    // Extract our context
    const ctx: *TemperatureContext = @ptrCast(@alignCast(userdata.?));
    ctx.count += 1;

    // Extract and store the value
    if (value.* == .double) {
        ctx.last_value = value.double;
        std.log.info("[Temperature Callback #{d}] Temperature changed: {d:.2}°C", .{ ctx.count, value.double });
    }
}

/// Callback function invoked when status message changes
fn statusCallback(
    userdata: ?*anyopaque,
    subscription_id: ua.SubscriptionId,
    monitored_item_id: ua.MonitoredItemId,
    value: *const ua.Variant,
) void {
    _ = subscription_id;
    _ = monitored_item_id;

    // Extract our context
    const ctx: *StatusContext = @ptrCast(@alignCast(userdata.?));
    ctx.count += 1;

    // Log the string value (no need to store it - variant is only valid during callback)
    if (value.* == .string) {
        std.log.info("[Status Callback #{d}] Status changed: \"{s}\"", .{ ctx.count, value.string });
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

    // Add a temperature variable (f64) that we'll monitor
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

    // Add a status message variable (string) that we'll monitor
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "status"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Status"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar([]const u8, "Initializing"),
            .display_name = ua.LocalizedText.init("en-US", "Status Message"),
            .description = ua.LocalizedText.init("en-US", "Current system status"),
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

    const temp_node_id = ua.NodeId.initString(1, "temperature");
    const status_node_id = ua.NodeId.initString(1, "status");

    // Create a subscription with fast publishing for demonstration
    std.log.info("\nCreating subscription...", .{});
    const subscription_id = try client.createSubscription(.{
        .publishing_interval = 100.0, // 100ms for quick updates
        .priority = 10,
    });
    defer client.deleteSubscription(subscription_id) catch |err| {
        std.log.err("Failed to delete subscription: {}", .{err});
    };
    std.log.info("Subscription created (ID: {d})", .{subscription_id});

    // Create callback contexts
    var temp_ctx = TemperatureContext{};
    var status_ctx = StatusContext{};

    // Create monitored item for temperature (f64)
    std.log.info("\nCreating monitored item for temperature (f64)...", .{});
    const temp_mon_id = try client.createMonitoredItemWithCallback(
        subscription_id,
        .{
            .node_id = temp_node_id,
            .sampling_interval = 50.0, // Sample every 50ms
            .queue_size = 10,
        },
        temperatureCallback,
        &temp_ctx,
    );
    defer client.deleteMonitoredItem(subscription_id, temp_mon_id) catch |err| {
        std.log.err("Failed to delete monitored item: {}", .{err});
    };
    std.log.info("Temperature monitored item created (ID: {d})", .{temp_mon_id});

    // Create monitored item for status (string)
    std.log.info("Creating monitored item for status (string)...", .{});
    const status_mon_id = try client.createMonitoredItemWithCallback(
        subscription_id,
        .{
            .node_id = status_node_id,
            .sampling_interval = 50.0,
            .queue_size = 10,
        },
        statusCallback,
        &status_ctx,
    );
    defer client.deleteMonitoredItem(subscription_id, status_mon_id) catch |err| {
        std.log.err("Failed to delete monitored item: {}", .{err});
    };
    std.log.info("Status monitored item created (ID: {d})", .{status_mon_id});

    std.log.info("\nWaiting for initial callbacks...", .{});
    _ = ua.c.UA_Client_run_iterate(client.handle, 200);
    std.Thread.sleep(100 * std.time.ns_per_ms);

    // Simulate temperature and status changes
    const temperatures = [_]f64{ 21.5, 22.0, 23.5, 24.0, 22.5 };
    const statuses = [_][]const u8{ "Warming up", "Normal", "Hot", "Very Hot", "Cooling down" };

    for (temperatures, statuses, 0..) |temp, status, i| {
        std.log.info("\n--- Update {d} ---", .{i + 1});
        std.log.info("Writing temperature: {d:.2}°C", .{temp});
        try client.writeValueAttribute(temp_node_id, ua.Variant.scalar(f64, temp));

        std.log.info("Writing status: \"{s}\"", .{status});
        try client.writeValueAttribute(status_node_id, ua.Variant.scalar([]const u8, status));

        // Process client messages to trigger callbacks
        _ = ua.c.UA_Client_run_iterate(client.handle, 200);
        std.Thread.sleep(150 * std.time.ns_per_ms);
        _ = ua.c.UA_Client_run_iterate(client.handle, 200);

        // Delay between updates
        if (i < temperatures.len - 1) {
            std.Thread.sleep(500 * std.time.ns_per_ms);
        }
    }

    // Final summary
    std.log.info("\n=== Summary ===", .{});
    std.log.info("Temperature callbacks: {d}", .{temp_ctx.count});
    if (temp_ctx.last_value) |value| {
        std.log.info("Last temperature: {d:.2}°C", .{value});
    }
    std.log.info("Status callbacks: {d}", .{status_ctx.count});

    std.log.info("\n=== Callback example completed successfully! ===", .{});
    std.log.info("Total callbacks received: {d} (temperature + status)", .{temp_ctx.count + status_ctx.count});
}
