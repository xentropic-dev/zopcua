const std = @import("std");
const ua = @import("ua");

var running = std.atomic.Value(bool).init(true);

fn serverThread(server: *ua.Server) void {
    while (running.load(.seq_cst)) {
        _ = server.iterate(true);
    }
}

pub fn main() !void {
    // Use GPA to detect memory leaks
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked == .leak) {
            std.debug.print("\n❌ Memory leak detected!\n", .{});
        }
    }
    const allocator = gpa.allocator();

    // Test 1: Client lifecycle
    var client = try ua.Client.init();
    client.deinit();

    // Test 2: Server lifecycle with event loop
    var server = try ua.Server.init();
    try server.start();

    // Spawn thread to run server event loop
    const thread = try std.Thread.spawn(.{}, serverThread, .{&server});

    // Let it run for a bit
    std.Thread.sleep(500 * std.time.ns_per_ms);

    // Stop the server
    running.store(false, .seq_cst);
    thread.join();
    try server.stop();
    server.deinit();

    // Test 3: Client connects to server

    // Reset running flag
    running.store(true, .seq_cst);

    // Create and start server
    var test_server = try ua.Server.init();
    try test_server.start();
    const server_thread = try std.Thread.spawn(.{}, serverThread, .{&test_server});

    // Give server time to start listening
    std.Thread.sleep(100 * std.time.ns_per_ms);

    // Create client and connect
    var test_client = try ua.Client.init();
    try test_client.connect("opc.tcp://localhost:4840");

    // Disconnect and cleanup
    try test_client.disconnect();
    test_client.deinit();

    running.store(false, .seq_cst);
    server_thread.join();
    try test_server.stop();
    test_server.deinit();

    // Test 4: Read/Write variable values

    // Reset running flag
    running.store(true, .seq_cst);

    // Create server with a writable variable
    var rw_server = try ua.Server.init();

    // Add a simple writable integer variable
    _ = try rw_server.addVariableNode(
        ua.NodeId.initString(1, "test.value"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "TestValue"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(i32, 100),
            .display_name = ua.LocalizedText.init("en-US", "Test Value"),
            .access_level = .{ .read = true, .write = true },
        },
    );

    try rw_server.start();
    const rw_thread = try std.Thread.spawn(.{}, serverThread, .{&rw_server});

    // Give server time to start
    std.Thread.sleep(100 * std.time.ns_per_ms);

    // Connect client and test read
    var rw_client = try ua.Client.init();
    try rw_client.connect("opc.tcp://localhost:4840");

    const node_id = "ns=1;s=test.value"; // String representation of NodeId

    // Read initial value
    const initial_value = try rw_client.readNodeAttribute(node_id, 13); // UA_ATTRIBUTEID_VALUE
    // Note: c.UA_DataValue doesn't have deinit, but UA_DataValue_clear should be called
    // For now, we'll rely on the C library to clean up
    _ = initial_value; // Mark as used

    // Write new value
    const new_value = ua.Variant.scalar(i32, 999);
    var c_variant = try new_value.toC(allocator);
    defer ua.Variant.freeCVariant(allocator, c_variant);
    try rw_client.writeNodeAttribute(node_id, 13, &c_variant); // UA_ATTRIBUTEID_VALUE

    // Read it back
    const read_back = try rw_client.readNodeAttribute(node_id, 13); // UA_ATTRIBUTEID_VALUE
    _ = read_back; // Mark as used

    // Cleanup
    try rw_client.disconnect();
    rw_client.deinit();

    running.store(false, .seq_cst);
    rw_thread.join();
    try rw_server.stop();
    rw_server.deinit();
}
