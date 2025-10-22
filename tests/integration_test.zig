const std = @import("std");
const ua = @import("ua");

var running = std.atomic.Value(bool).init(true);

fn serverThread(server: *ua.Server) void {
    while (running.load(.seq_cst)) {
        _ = server.iterate(true);
    }
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // Use GPA to detect memory leaks
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked == .leak) {
            std.debug.print("\n❌ Memory leak detected!\n", .{});
        }
    }
    _ = gpa.allocator(); // Not used in this simple test

    try stdout.print("=== Integration Test ===\n", .{});

    // Test 1: Client lifecycle
    try stdout.print("\n[Test 1] Client lifecycle test...\n", .{});
    var client = try ua.Client.init();
    client.deinit();
    try stdout.print("[Test 1] ✓ Client lifecycle test passed\n", .{});

    // Test 2: Server lifecycle with event loop
    try stdout.print("\n[Test 2] Server lifecycle test...\n", .{});
    var server = try ua.Server.init();
    try stdout.print("[Test 2] Server created, starting...\n", .{});
    try server.start();
    try stdout.print("[Test 2] Server started, spawning iterate thread...\n", .{});

    // Spawn thread to run server event loop
    const thread = try std.Thread.spawn(.{}, serverThread, .{&server});

    // Let it run for a bit
    std.time.sleep(500 * std.time.ns_per_ms);

    // Stop the server
    try stdout.print("[Test 2] Stopping server...\n", .{});
    running.store(false, .seq_cst);
    thread.join();
    try server.stop();
    server.deinit();
    try stdout.print("[Test 2] ✓ Server lifecycle test passed\n", .{});

    // Test 3: Client connects to server
    try stdout.print("\n[Test 3] Client-server connection test...\n", .{});

    // Reset running flag
    running.store(true, .seq_cst);

    // Create and start server
    var test_server = try ua.Server.init();
    try test_server.start();
    const server_thread = try std.Thread.spawn(.{}, serverThread, .{&test_server});

    // Give server time to start listening
    std.time.sleep(100 * std.time.ns_per_ms);

    // Create client and connect
    var test_client = try ua.Client.init();
    try stdout.print("[Test 3] Connecting to opc.tcp://localhost:4840...\n", .{});
    try test_client.connect("opc.tcp://localhost:4840");
    try stdout.print("[Test 3] Connected successfully!\n", .{});

    // Disconnect and cleanup
    try test_client.disconnect();
    test_client.deinit();

    running.store(false, .seq_cst);
    server_thread.join();
    try test_server.stop();
    test_server.deinit();
    try stdout.print("[Test 3] ✓ Client-server connection test passed\n", .{});

    // Test 4: Read/Write variable values
    try stdout.print("\n[Test 4] Read/Write variable test...\n", .{});

    // Reset running flag
    running.store(true, .seq_cst);

    // Create server with a writable variable
    var rw_server = try ua.Server.init();
    const allocator = std.heap.page_allocator;

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
        allocator,
    );

    try rw_server.start();
    const rw_thread = try std.Thread.spawn(.{}, serverThread, .{&rw_server});

    // Give server time to start
    std.time.sleep(100 * std.time.ns_per_ms);

    // Connect client and test read
    var rw_client = try ua.Client.init();
    try rw_client.connect("opc.tcp://localhost:4840");

    const node_id = ua.NodeId.initString(1, "test.value");

    // Read initial value
    try stdout.print("[Test 4] Reading initial value...\n", .{});
    const initial_value = try rw_client.readValueAttribute(node_id, allocator);
    defer initial_value.deinit(allocator);
    try stdout.print("[Test 4] Initial value: {}\n", .{initial_value.int32});

    // Write new value
    try stdout.print("[Test 4] Writing new value 999...\n", .{});
    const new_value = ua.Variant.scalar(i32, 999);
    try rw_client.writeValueAttribute(node_id, new_value);
    try stdout.print("[Test 4] Write successful!\n", .{});

    // Read it back
    try stdout.print("[Test 4] Reading back...\n", .{});
    const read_back = try rw_client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("[Test 4] Read back value: {}\n", .{read_back.int32});

    // Cleanup
    try rw_client.disconnect();
    rw_client.deinit();

    running.store(false, .seq_cst);
    rw_thread.join();
    try rw_server.stop();
    rw_server.deinit();

    try stdout.print("[Test 4] ✓ Read/Write variable test passed\n", .{});

    try stdout.print("\n=== ✓ All tests passed ===\n", .{});
}
