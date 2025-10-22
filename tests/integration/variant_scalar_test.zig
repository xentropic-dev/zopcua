const std = @import("std");
const ua = @import("ua");
const test_helpers = @import("test_helpers");
const TestServer = test_helpers.TestServer;
const fixtures = test_helpers.fixtures;
const assertions = test_helpers.assertions;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const allocator = std.heap.page_allocator;

    try stdout.print("=== Variant Scalar Integration Tests ===\n", .{});

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

    // Test all scalar types
    try testBoolean(&client, nodes.boolean, allocator, stdout);
    try testSByte(&client, nodes.sbyte, allocator, stdout);
    try testByte(&client, nodes.byte, allocator, stdout);
    try testInt16(&client, nodes.int16, allocator, stdout);
    try testUInt16(&client, nodes.uint16, allocator, stdout);
    try testInt32(&client, nodes.int32, allocator, stdout);
    try testUInt32(&client, nodes.uint32, allocator, stdout);
    try testInt64(&client, nodes.int64, allocator, stdout);
    try testUInt64(&client, nodes.uint64, allocator, stdout);
    try testFloat(&client, nodes.float, allocator, stdout);
    try testDouble(&client, nodes.double, allocator, stdout);
    try testString(&client, nodes.string, allocator, stdout);
    try testDateTime(&client, nodes.date_time, allocator, stdout);
    try testGuid(&client, nodes.guid, allocator, stdout);
    try testByteString(&client, nodes.byte_string, allocator, stdout);
    try testNodeId(&client, nodes.node_id, allocator, stdout);
    try testStatusCode(&client, nodes.status_code, allocator, stdout);
    try testLocalizedText(&client, nodes.localized_text, allocator, stdout);

    try stdout.print("\n=== ✓ All Variant Scalar Tests Passed ===\n", .{});
}

fn testBoolean(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] Boolean scalar...\n", .{});

    // Read initial value
    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial value: {}\n", .{initial.boolean});
    try assertions.expectVariantEqual(ua.Variant.scalar(bool, fixtures.TestScalarData.boolean_value), initial);

    // Write new value
    const new_value = ua.Variant.scalar(bool, false);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote: {}\n", .{false});

    // Read back
    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back: {}\n", .{read_back.boolean});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ Boolean test passed\n", .{});
}

fn testSByte(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] SByte scalar...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial value: {}\n", .{initial.sbyte});
    try assertions.expectVariantEqual(ua.Variant.scalar(i8, fixtures.TestScalarData.sbyte_value), initial);

    const new_value = ua.Variant.scalar(i8, 127);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote: {}\n", .{127});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back: {}\n", .{read_back.sbyte});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ SByte test passed\n", .{});
}

fn testByte(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] Byte scalar...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial value: {}\n", .{initial.byte});
    try assertions.expectVariantEqual(ua.Variant.scalar(u8, fixtures.TestScalarData.byte_value), initial);

    const new_value = ua.Variant.scalar(u8, 128);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote: {}\n", .{128});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back: {}\n", .{read_back.byte});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ Byte test passed\n", .{});
}

fn testInt16(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] Int16 scalar...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial value: {}\n", .{initial.int16});
    try assertions.expectVariantEqual(ua.Variant.scalar(i16, fixtures.TestScalarData.int16_value), initial);

    const new_value = ua.Variant.scalar(i16, 32000);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote: {}\n", .{32000});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back: {}\n", .{read_back.int16});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ Int16 test passed\n", .{});
}

fn testUInt16(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] UInt16 scalar...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial value: {}\n", .{initial.uint16});
    try assertions.expectVariantEqual(ua.Variant.scalar(u16, fixtures.TestScalarData.uint16_value), initial);

    const new_value = ua.Variant.scalar(u16, 50000);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote: {}\n", .{50000});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back: {}\n", .{read_back.uint16});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ UInt16 test passed\n", .{});
}

fn testInt32(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] Int32 scalar...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial value: {}\n", .{initial.int32});
    try assertions.expectVariantEqual(ua.Variant.scalar(i32, fixtures.TestScalarData.int32_value), initial);

    const new_value = ua.Variant.scalar(i32, 2000000000);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote: {}\n", .{2000000000});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back: {}\n", .{read_back.int32});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ Int32 test passed\n", .{});
}

fn testUInt32(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] UInt32 scalar...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial value: {}\n", .{initial.uint32});
    try assertions.expectVariantEqual(ua.Variant.scalar(u32, fixtures.TestScalarData.uint32_value), initial);

    const new_value = ua.Variant.scalar(u32, 3000000000);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote: {}\n", .{3000000000});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back: {}\n", .{read_back.uint32});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ UInt32 test passed\n", .{});
}

fn testInt64(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] Int64 scalar...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial value: {}\n", .{initial.int64});
    try assertions.expectVariantEqual(ua.Variant.scalar(i64, fixtures.TestScalarData.int64_value), initial);

    const new_value = ua.Variant.scalar(i64, 9000000000000);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote: {}\n", .{9000000000000});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back: {}\n", .{read_back.int64});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ Int64 test passed\n", .{});
}

fn testUInt64(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] UInt64 scalar...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial value: {}\n", .{initial.uint64});
    try assertions.expectVariantEqual(ua.Variant.scalar(u64, fixtures.TestScalarData.uint64_value), initial);

    const new_value = ua.Variant.scalar(u64, 15000000000000000000);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote: {}\n", .{15000000000000000000});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back: {}\n", .{read_back.uint64});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ UInt64 test passed\n", .{});
}

fn testFloat(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] Float scalar...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial value: {d}\n", .{initial.float});
    try assertions.expectVariantEqual(ua.Variant.scalar(f32, fixtures.TestScalarData.float_value), initial);

    const new_value = ua.Variant.scalar(f32, 2.71828);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote: {d}\n", .{2.71828});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back: {d}\n", .{read_back.float});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ Float test passed\n", .{});
}

fn testDouble(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] Double scalar...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial value: {d}\n", .{initial.double});
    try assertions.expectVariantEqual(ua.Variant.scalar(f64, fixtures.TestScalarData.double_value), initial);

    const new_value = ua.Variant.scalar(f64, 1.41421356);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote: {d}\n", .{1.41421356});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back: {d}\n", .{read_back.double});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ Double test passed\n", .{});
}

fn testString(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] String scalar...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial value: {s}\n", .{initial.string});
    try assertions.expectVariantEqual(ua.Variant.scalar([]const u8, fixtures.TestScalarData.string_value), initial);

    const new_value = ua.Variant.scalar([]const u8, "Modified String Value");
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote: {s}\n", .{"Modified String Value"});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back: {s}\n", .{read_back.string});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ String test passed\n", .{});
}

fn testDateTime(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] DateTime scalar...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial value: {}\n", .{initial.date_time});
    try assertions.expectVariantEqual(ua.Variant{ .date_time = fixtures.TestScalarData.date_time_value }, initial);

    const new_value = ua.Variant{ .date_time = 132900000000000000 };
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote: {}\n", .{132900000000000000});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back: {}\n", .{read_back.date_time});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ DateTime test passed\n", .{});
}

fn testGuid(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] Guid scalar...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial value: {x}-{x}-{x}\n", .{ initial.guid.data1, initial.guid.data2, initial.guid.data3 });
    try assertions.expectVariantEqual(ua.Variant{ .guid = fixtures.TestScalarData.guidValue() }, initial);

    const new_guid = ua.Guid{
        .data1 = 0xAABBCCDD,
        .data2 = 0x1122,
        .data3 = 0x3344,
        .data4 = [_]u8{ 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC },
    };
    const new_value = ua.Variant{ .guid = new_guid };
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote new GUID\n", .{});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print(
        "  Read back: {x}-{x}-{x}\n",
        .{ read_back.guid.data1, read_back.guid.data2, read_back.guid.data3 },
    );
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ Guid test passed\n", .{});
}

fn testByteString(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] ByteString scalar...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial value length: {}\n", .{initial.byte_string.len});
    try assertions.expectVariantEqual(ua.Variant{ .byte_string = fixtures.TestScalarData.byte_string_value }, initial);

    const new_value = ua.Variant{ .byte_string = "New Binary \xFF\xFE\xFD" };
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote new ByteString\n", .{});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back length: {}\n", .{read_back.byte_string.len});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ ByteString test passed\n", .{});
}

fn testNodeId(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] NodeId scalar...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print(
        "  Initial value: ns={} i={}\n",
        .{ initial.node_id.numeric.namespace, initial.node_id.numeric.identifier },
    );
    try assertions.expectVariantEqual(ua.Variant.scalar(ua.NodeId, fixtures.TestScalarData.nodeIdValue()), initial);

    const new_node = ua.NodeId.initNumeric(2, 5000);
    const new_value = ua.Variant.scalar(ua.NodeId, new_node);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote: ns=2 i=5000\n", .{});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print(
        "  Read back: ns={} i={}\n",
        .{ read_back.node_id.numeric.namespace, read_back.node_id.numeric.identifier },
    );
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ NodeId test passed\n", .{});
}

fn testStatusCode(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] StatusCode scalar...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial value: 0x{X}\n", .{initial.status_code});
    try assertions.expectVariantEqual(ua.Variant{ .status_code = fixtures.TestScalarData.status_code_value }, initial);

    const new_value = ua.Variant{ .status_code = 0x80000000 };
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote: 0x80000000\n", .{});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back: 0x{X}\n", .{read_back.status_code});
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ StatusCode test passed\n", .{});
}

fn testLocalizedText(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator, stdout: anytype) !void {
    try stdout.print("\n[Test] LocalizedText scalar...\n", .{});

    const initial = try client.readValueAttribute(node_id, allocator);
    defer initial.deinit(allocator);
    try stdout.print("  Initial value: {s}:{s}\n", .{ initial.localized_text.locale, initial.localized_text.text });
    try assertions.expectVariantEqual(
        ua.Variant.scalar(ua.LocalizedText, fixtures.TestScalarData.localizedTextValue()),
        initial,
    );

    const new_text = ua.LocalizedText.init("de-DE", "Geänderter Text");
    const new_value = ua.Variant.scalar(ua.LocalizedText, new_text);
    try client.writeValueAttribute(node_id, new_value);
    try stdout.print("  Wrote: de-DE:Geänderter Text\n", .{});

    const read_back = try client.readValueAttribute(node_id, allocator);
    defer read_back.deinit(allocator);
    try stdout.print("  Read back: {s}:{s}\n", .{ read_back.localized_text.locale, read_back.localized_text.text });
    try assertions.expectVariantEqual(new_value, read_back);

    try stdout.print("  ✓ LocalizedText test passed\n", .{});
}
