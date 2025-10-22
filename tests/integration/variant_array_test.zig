const std = @import("std");
const ua = @import("ua");
const test_helpers = @import("test_helpers");
const TestServer = test_helpers.TestServer;
const fixtures = test_helpers.fixtures;
const assertions = test_helpers.assertions;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const allocator = std.heap.page_allocator;

    try stdout.print("=== Variant Array Integration Tests ===\n", .{});

    // Create and setup server
    var test_server = try TestServer.init(allocator, 4840);
    defer test_server.deinit();

    const nodes = try fixtures.setupStandardNodes(&test_server.server, allocator);
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

    // Test all array types
    try testBooleanArray(&client, nodes.boolean_array, allocator, stdout);
    try testSByteArray(&client, nodes.sbyte_array, allocator, stdout);
    try testByteArray(&client, nodes.byte_array, allocator, stdout);
    try testInt16Array(&client, nodes.int16_array, allocator, stdout);
    try testUInt16Array(&client, nodes.uint16_array, allocator, stdout);
    try testInt32Array(&client, nodes.int32_array, allocator, stdout);
    try testUInt32Array(&client, nodes.uint32_array, allocator, stdout);
    try testInt64Array(&client, nodes.int64_array, allocator, stdout);
    try testUInt64Array(&client, nodes.uint64_array, allocator, stdout);
    try testFloatArray(&client, nodes.float_array, allocator, stdout);
    try testDoubleArray(&client, nodes.double_array, allocator, stdout);
    try testDateTimeArray(&client, nodes.date_time_array, allocator, stdout);
    try testStatusCodeArray(&client, nodes.status_code_array, allocator, stdout);

    // TODO: Test edge cases like empty arrays
    // try testEmptyArrays(&client, allocator, stdout);

    try stdout.print("\n=== ✓ All Variant Array Tests Passed ===\n", .{});
}

fn testBooleanArray(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] Boolean array...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial array length: {}\n", .{initial.boolean_array.len});
    try assertions.expectVariantEqual(ua.Variant.array(bool, &fixtures.TestArrayData.boolean_array), initial);

    const new_data = [_]bool{ false, false, true, true, false };
    const new_value = ua.Variant.array(bool, &new_data);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote array of length {}\n", .{new_data.len});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back array length: {}\n", .{read_back.boolean_array.len});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ Boolean array test passed\n", .{});
}

fn testSByteArray(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] SByte array...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial array length: {}\n", .{initial.sbyte_array.len});
    try assertions.expectVariantEqual(ua.Variant.array(i8, &fixtures.TestArrayData.sbyte_array), initial);

    // Must write same-length array due to arrayDimensions constraint
    const new_data = [_]i8{ 10, 20, 30, 40, 50 };
    const new_value = ua.Variant.array(i8, &new_data);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote array of length {}\n", .{new_data.len});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back array length: {}\n", .{read_back.sbyte_array.len});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ SByte array test passed\n", .{});
}

fn testByteArray(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] Byte array...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial array length: {}\n", .{initial.byte_array.len});
    try assertions.expectVariantEqual(ua.Variant.array(u8, &fixtures.TestArrayData.byte_array), initial);

    const new_data = [_]u8{ 100, 150, 200, 250, 255 };
    const new_value = ua.Variant.array(u8, &new_data);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote array of length {}\n", .{new_data.len});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back array length: {}\n", .{read_back.byte_array.len});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ Byte array test passed\n", .{});
}

fn testInt16Array(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] Int16 array...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial array length: {}\n", .{initial.int16_array.len});
    try assertions.expectVariantEqual(ua.Variant.array(i16, &fixtures.TestArrayData.int16_array), initial);

    const new_data = [_]i16{ -1000, -500, 0, 500, 1000 };
    const new_value = ua.Variant.array(i16, &new_data);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote array of length {}\n", .{new_data.len});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back array length: {}\n", .{read_back.int16_array.len});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ Int16 array test passed\n", .{});
}

fn testUInt16Array(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] UInt16 array...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial array length: {}\n", .{initial.uint16_array.len});
    try assertions.expectVariantEqual(ua.Variant.array(u16, &fixtures.TestArrayData.uint16_array), initial);

    const new_data = [_]u16{ 1000, 2000, 3000, 4000, 5000 };
    const new_value = ua.Variant.array(u16, &new_data);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote array of length {}\n", .{new_data.len});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back array length: {}\n", .{read_back.uint16_array.len});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ UInt16 array test passed\n", .{});
}

fn testInt32Array(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] Int32 array...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial array length: {}\n", .{initial.int32_array.len});
    try assertions.expectVariantEqual(ua.Variant.array(i32, &fixtures.TestArrayData.int32_array), initial);

    const new_data = [_]i32{ -100000, -50000, 0, 50000, 100000 };
    const new_value = ua.Variant.array(i32, &new_data);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote array of length {}\n", .{new_data.len});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back array length: {}\n", .{read_back.int32_array.len});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ Int32 array test passed\n", .{});
}

fn testUInt32Array(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] UInt32 array...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial array length: {}\n", .{initial.uint32_array.len});
    try assertions.expectVariantEqual(ua.Variant.array(u32, &fixtures.TestArrayData.uint32_array), initial);

    const new_data = [_]u32{ 100000, 200000, 300000, 400000, 500000 };
    const new_value = ua.Variant.array(u32, &new_data);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote array of length {}\n", .{new_data.len});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back array length: {}\n", .{read_back.uint32_array.len});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ UInt32 array test passed\n", .{});
}

fn testInt64Array(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] Int64 array...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial array length: {}\n", .{initial.int64_array.len});
    try assertions.expectVariantEqual(ua.Variant.array(i64, &fixtures.TestArrayData.int64_array), initial);

    const new_data = [_]i64{ -1000000000000, 0, 1000000000000, 2000000000000, 3000000000000 };
    const new_value = ua.Variant.array(i64, &new_data);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote array of length {}\n", .{new_data.len});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back array length: {}\n", .{read_back.int64_array.len});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ Int64 array test passed\n", .{});
}

fn testUInt64Array(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] UInt64 array...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial array length: {}\n", .{initial.uint64_array.len});
    try assertions.expectVariantEqual(ua.Variant.array(u64, &fixtures.TestArrayData.uint64_array), initial);

    const new_data = [_]u64{ 1000000000000, 2000000000000, 3000000000000, 4000000000000, 5000000000000 };
    const new_value = ua.Variant.array(u64, &new_data);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote array of length {}\n", .{new_data.len});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back array length: {}\n", .{read_back.uint64_array.len});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ UInt64 array test passed\n", .{});
}

fn testFloatArray(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] Float array...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial array length: {}\n", .{initial.float_array.len});
    try assertions.expectVariantEqual(ua.Variant.array(f32, &fixtures.TestArrayData.float_array), initial);

    const new_data = [_]f32{ 1.1, 2.2, 3.3, 4.4, 5.5 };
    const new_value = ua.Variant.array(f32, &new_data);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote array of length {}\n", .{new_data.len});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back array length: {}\n", .{read_back.float_array.len});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ Float array test passed\n", .{});
}

fn testDoubleArray(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] Double array...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial array length: {}\n", .{initial.double_array.len});
    try assertions.expectVariantEqual(ua.Variant.array(f64, &fixtures.TestArrayData.double_array), initial);

    const new_data = [_]f64{ 10.123456, 20.234567, 30.345678, 40.456789, 50.567890 };
    const new_value = ua.Variant.array(f64, &new_data);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote array of length {}\n", .{new_data.len});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back array length: {}\n", .{read_back.double_array.len});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ Double array test passed\n", .{});
}

fn testDateTimeArray(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] DateTime array...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial array length: {}\n", .{initial.date_time_array.len});
    try assertions.expectVariantEqual(
        ua.Variant{ .date_time_array = &fixtures.TestArrayData.date_time_array },
        initial,
    );

    const new_data = [_]i64{ 132900000000000000, 132900000000000001, 132900000000000002 };
    const new_value = ua.Variant{ .date_time_array = &new_data };
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote array of length {}\n", .{new_data.len});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back array length: {}\n", .{read_back.date_time_array.len});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ DateTime array test passed\n", .{});
}

fn testStatusCodeArray(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] StatusCode array...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial array length: {}\n", .{initial.status_code_array.len});
    try assertions.expectVariantEqual(
        ua.Variant{ .status_code_array = &fixtures.TestArrayData.status_code_array },
        initial,
    );

    const new_data = [_]u32{ 0x00000000, 0x00010000, 0x00020000 };
    const new_value = ua.Variant{ .status_code_array = &new_data };
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote array of length {}\n", .{new_data.len});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back array length: {}\n", .{read_back.status_code_array.len});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ StatusCode array test passed\n", .{});
}

fn testEmptyArrays(_: *ua.Client, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] Empty arrays...\n", .{});

    // Create a temporary node with an empty array
    var test_server = try TestServer.init(allocator, 4841);
    defer test_server.deinit();

    const empty_node = try test_server.server.addVariableNode(
        ua.NodeId.initString(1, "test.empty_array"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "TestEmptyArray"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.array(i32, &fixtures.TestArrayData.empty_int32_array),
            .display_name = ua.LocalizedText.init("en-US", "Test Empty Array"),
            .access_level = .{ .read = true, .write = true },
            .value_rank = 1,
            .array_dimensions = &[_]u32{0},
        },
        allocator,
    );

    try test_server.startAsync();
    defer test_server.stop() catch |err| {
        std.debug.print("Failed to stop test server: {}\n", .{err});
    };

    var url_buf: [128]u8 = undefined;
    const endpoint_url = try test_server.getEndpointUrl(&url_buf);
    var test_client = try ua.Client.init();
    defer test_client.deinit();
    try test_client.connect(endpoint_url);
    defer test_client.disconnect() catch |err| {
        std.debug.print("Failed to disconnect test client: {}\n", .{err});
    };

    const empty_result = try test_client.readValueAttribute(empty_node, allocator);
    defer empty_result.deinit(allocator);
    try stdout.print("  Empty array length: {}\n", .{empty_result.int32_array.len});
    if (empty_result.int32_array.len != 0) {
        return error.ExpectedEmptyArray;
    }

    try stdout.print("  ✓ Empty array test passed\n", .{});
}
