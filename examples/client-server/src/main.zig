const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create and start the server in a background thread
    const server_thread = try std.Thread.spawn(.{}, serverThread, .{allocator});
    defer server_thread.join();

    // Give the server time to start
    std.time.sleep(500 * std.time.ns_per_ms);

    // Run the client operations
    try clientOperations(allocator);

    std.log.info("\nPress Ctrl-C to stop the server", .{});
    std.time.sleep(std.math.maxInt(u64)); // Wait for Ctrl-C
}

fn serverThread(allocator: std.mem.Allocator) !void {
    var server = try ua.Server.init();
    defer server.deinit();

    // Add a counter variable that we'll modify
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "counter"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Counter"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(i32, 0),
            .display_name = ua.LocalizedText.init("en-US", "Counter"),
            .description = ua.LocalizedText.init("en-US", "A counter that the client will increment"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    std.log.info("Server started on opc.tcp://localhost:4840", .{});
    try server.runUntilInterrupt();
}

fn clientOperations(allocator: std.mem.Allocator) !void {
    const client = try ua.Client.init();
    defer client.deinit();

    const server_url = "opc.tcp://localhost:4840";
    std.log.info("\n=== Client Operations ===", .{});
    std.log.info("Connecting to {s}...", .{server_url});
    try client.connect(server_url);
    defer client.disconnect() catch |err| {
        std.log.err("Failed to disconnect: {}", .{err});
    };

    const node_id = ua.NodeId.initString(1, "counter");

    // Read initial value
    std.log.info("\n1. Reading initial counter value...", .{});
    const initial_value = try client.readValueAttribute(node_id, allocator);
    defer initial_value.deinit(allocator);
    std.log.info("   Counter = {}", .{initial_value});

    // Increment the counter
    std.log.info("\n2. Incrementing counter...", .{});
    const new_value = ua.Variant.scalar(i32, 1);
    try client.writeValueAttribute(node_id, new_value);
    std.log.info("   Written new value: 1", .{});

    // Read it back
    std.log.info("\n3. Reading updated counter value...", .{});
    const updated_value = try client.readValueAttribute(node_id, allocator);
    defer updated_value.deinit(allocator);
    std.log.info("   Counter = {}", .{updated_value});

    // Increment again
    std.log.info("\n4. Incrementing counter again...", .{});
    const new_value2 = ua.Variant.scalar(i32, 2);
    try client.writeValueAttribute(node_id, new_value2);
    std.log.info("   Written new value: 2", .{});

    // Final read
    std.log.info("\n5. Reading final counter value...", .{});
    const final_value = try client.readValueAttribute(node_id, allocator);
    defer final_value.deinit(allocator);
    std.log.info("   Counter = {}", .{final_value});

    std.log.info("\n=== Client operations completed successfully! ===", .{});
}
