const std = @import("std");
const ua = @import("ua");
const test_helpers = @import("test_helpers");
const TestServer = test_helpers.TestServer;
const fixtures = test_helpers.fixtures;
const assertions = test_helpers.assertions;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Create and setup server
    var test_server = try TestServer.init(allocator, 4840);
    defer test_server.deinit();

    const nodes = try fixtures.setupStandardNodes(&test_server.server);
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
    try testBoolean(&client, nodes.boolean, allocator);
    try testSByte(&client, nodes.sbyte, allocator);
    try testByte(&client, nodes.byte, allocator);
    try testInt16(&client, nodes.int16, allocator);
    try testUInt16(&client, nodes.uint16, allocator);
    try testInt32(&client, nodes.int32, allocator);
    try testUInt32(&client, nodes.uint32, allocator);
    try testInt64(&client, nodes.int64, allocator);
    try testUInt64(&client, nodes.uint64, allocator);
    try testFloat(&client, nodes.float, allocator);
    try testDouble(&client, nodes.double, allocator);
    try testString(&client, nodes.string, allocator);
    try testDateTime(&client, nodes.date_time, allocator);
    try testGuid(&client, nodes.guid, allocator);
    try testByteString(&client, nodes.byte_string, allocator);
    try testNodeId(&client, nodes.node_id, allocator);
    try testStatusCode(&client, nodes.status_code, allocator);
    try testLocalizedText(&client, nodes.localized_text, allocator);
}

fn testBoolean(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {

    // Read initial value
    const initial = try client.readValueAttribute(allocator, node_id);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(ua.Variant.scalar(bool, fixtures.TestScalarData.boolean_value), initial);

    // Write new value
    const new_value = ua.Variant.scalar(bool, false);
    try client.writeValueAttribute(node_id, new_value);

    // Read back
    const read_back = try client.readValueAttribute(allocator, node_id);
    defer read_back.deinit(allocator);
    try assertions.expectVariantEqual(new_value, read_back);
}

fn testSByte(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {
    const initial = try client.readValueAttribute(allocator, node_id);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(ua.Variant.scalar(i8, fixtures.TestScalarData.sbyte_value), initial);

    const new_value = ua.Variant.scalar(i8, 127);
    try client.writeValueAttribute(node_id, new_value);

    const read_back = try client.readValueAttribute(allocator, node_id);
    defer read_back.deinit(allocator);
    try assertions.expectVariantEqual(new_value, read_back);
}

fn testByte(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {
    const initial = try client.readValueAttribute(allocator, node_id);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(ua.Variant.scalar(u8, fixtures.TestScalarData.byte_value), initial);

    const new_value = ua.Variant.scalar(u8, 128);
    try client.writeValueAttribute(node_id, new_value);

    const read_back = try client.readValueAttribute(allocator, node_id);
    defer read_back.deinit(allocator);
    try assertions.expectVariantEqual(new_value, read_back);
}

fn testInt16(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {
    const initial = try client.readValueAttribute(allocator, node_id);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(ua.Variant.scalar(i16, fixtures.TestScalarData.int16_value), initial);

    const new_value = ua.Variant.scalar(i16, 32000);
    try client.writeValueAttribute(node_id, new_value);

    const read_back = try client.readValueAttribute(allocator, node_id);
    defer read_back.deinit(allocator);
    try assertions.expectVariantEqual(new_value, read_back);
}

fn testUInt16(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {
    const initial = try client.readValueAttribute(allocator, node_id);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(ua.Variant.scalar(u16, fixtures.TestScalarData.uint16_value), initial);

    const new_value = ua.Variant.scalar(u16, 50000);
    try client.writeValueAttribute(node_id, new_value);

    const read_back = try client.readValueAttribute(allocator, node_id);
    defer read_back.deinit(allocator);
    try assertions.expectVariantEqual(new_value, read_back);
}

fn testInt32(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {
    const initial = try client.readValueAttribute(allocator, node_id);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(ua.Variant.scalar(i32, fixtures.TestScalarData.int32_value), initial);

    const new_value = ua.Variant.scalar(i32, 2000000000);
    try client.writeValueAttribute(node_id, new_value);

    const read_back = try client.readValueAttribute(allocator, node_id);
    defer read_back.deinit(allocator);
    try assertions.expectVariantEqual(new_value, read_back);
}

fn testUInt32(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {
    const initial = try client.readValueAttribute(allocator, node_id);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(ua.Variant.scalar(u32, fixtures.TestScalarData.uint32_value), initial);

    const new_value = ua.Variant.scalar(u32, 3000000000);
    try client.writeValueAttribute(node_id, new_value);

    const read_back = try client.readValueAttribute(allocator, node_id);
    defer read_back.deinit(allocator);
    try assertions.expectVariantEqual(new_value, read_back);
}

fn testInt64(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {
    const initial = try client.readValueAttribute(allocator, node_id);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(ua.Variant.scalar(i64, fixtures.TestScalarData.int64_value), initial);

    const new_value = ua.Variant.scalar(i64, 9000000000000);
    try client.writeValueAttribute(node_id, new_value);

    const read_back = try client.readValueAttribute(allocator, node_id);
    defer read_back.deinit(allocator);
    try assertions.expectVariantEqual(new_value, read_back);
}

fn testUInt64(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {
    const initial = try client.readValueAttribute(allocator, node_id);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(ua.Variant.scalar(u64, fixtures.TestScalarData.uint64_value), initial);

    const new_value = ua.Variant.scalar(u64, 15000000000000000000);
    try client.writeValueAttribute(node_id, new_value);

    const read_back = try client.readValueAttribute(allocator, node_id);
    defer read_back.deinit(allocator);
    try assertions.expectVariantEqual(new_value, read_back);
}

fn testFloat(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {
    const initial = try client.readValueAttribute(allocator, node_id);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(ua.Variant.scalar(f32, fixtures.TestScalarData.float_value), initial);

    const new_value = ua.Variant.scalar(f32, 2.71828);
    try client.writeValueAttribute(node_id, new_value);

    const read_back = try client.readValueAttribute(allocator, node_id);
    defer read_back.deinit(allocator);
    try assertions.expectVariantEqual(new_value, read_back);
}

fn testDouble(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {
    const initial = try client.readValueAttribute(allocator, node_id);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(ua.Variant.scalar(f64, fixtures.TestScalarData.double_value), initial);

    const new_value = ua.Variant.scalar(f64, 1.41421356);
    try client.writeValueAttribute(node_id, new_value);

    const read_back = try client.readValueAttribute(allocator, node_id);
    defer read_back.deinit(allocator);
    try assertions.expectVariantEqual(new_value, read_back);
}

fn testString(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {
    const initial = try client.readValueAttribute(allocator, node_id);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(ua.Variant.scalar([]const u8, fixtures.TestScalarData.string_value), initial);

    const new_value = ua.Variant.scalar([]const u8, "Modified String Value");
    try client.writeValueAttribute(node_id, new_value);

    const read_back = try client.readValueAttribute(allocator, node_id);
    defer read_back.deinit(allocator);
    try assertions.expectVariantEqual(new_value, read_back);
}

fn testDateTime(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {
    const initial = try client.readValueAttribute(allocator, node_id);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(ua.Variant{ .date_time = fixtures.TestScalarData.date_time_value }, initial);

    const new_value = ua.Variant{ .date_time = 132900000000000000 };
    try client.writeValueAttribute(node_id, new_value);

    const read_back = try client.readValueAttribute(allocator, node_id);
    defer read_back.deinit(allocator);
    try assertions.expectVariantEqual(new_value, read_back);
}

fn testGuid(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {
    const initial = try client.readValueAttribute(allocator, node_id);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(ua.Variant{ .guid = fixtures.TestScalarData.guidValue() }, initial);

    const new_guid = ua.Guid{
        .data1 = 0xAABBCCDD,
        .data2 = 0x1122,
        .data3 = 0x3344,
        .data4 = [_]u8{ 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC },
    };
    const new_value = ua.Variant{ .guid = new_guid };
    try client.writeValueAttribute(node_id, new_value);

    const read_back = try client.readValueAttribute(allocator, node_id);
    defer read_back.deinit(allocator);
    try assertions.expectVariantEqual(new_value, read_back);
}

fn testByteString(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {
    const initial = try client.readValueAttribute(allocator, node_id);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(ua.Variant{ .byte_string = fixtures.TestScalarData.byte_string_value }, initial);

    const new_value = ua.Variant{ .byte_string = "New Binary \xFF\xFE\xFD" };
    try client.writeValueAttribute(node_id, new_value);

    const read_back = try client.readValueAttribute(allocator, node_id);
    defer read_back.deinit(allocator);
    try assertions.expectVariantEqual(new_value, read_back);
}

fn testNodeId(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {
    const initial = try client.readValueAttribute(allocator, node_id);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(ua.Variant.scalar(ua.NodeId, fixtures.TestScalarData.nodeIdValue()), initial);

    const new_node = ua.NodeId.initNumeric(2, 5000);
    const new_value = ua.Variant.scalar(ua.NodeId, new_node);
    try client.writeValueAttribute(node_id, new_value);

    const read_back = try client.readValueAttribute(allocator, node_id);
    defer read_back.deinit(allocator);
    try assertions.expectVariantEqual(new_value, read_back);
}

fn testStatusCode(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {
    const initial = try client.readValueAttribute(allocator, node_id);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(ua.Variant{ .status_code = fixtures.TestScalarData.status_code_value }, initial);

    const new_value = ua.Variant{ .status_code = 0x80000000 };
    try client.writeValueAttribute(node_id, new_value);

    const read_back = try client.readValueAttribute(allocator, node_id);
    defer read_back.deinit(allocator);
    try assertions.expectVariantEqual(new_value, read_back);
}

fn testLocalizedText(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {
    const initial = try client.readValueAttribute(allocator, node_id);
    defer initial.deinit(allocator);
    try assertions.expectVariantEqual(
        ua.Variant.scalar(ua.LocalizedText, fixtures.TestScalarData.localizedTextValue()),
        initial,
    );

    const new_text = ua.LocalizedText.init("de-DE", "Geänderter Text");
    const new_value = ua.Variant.scalar(ua.LocalizedText, new_text);
    try client.writeValueAttribute(node_id, new_value);

    const read_back = try client.readValueAttribute(allocator, node_id);
    defer read_back.deinit(allocator);
    try assertions.expectVariantEqual(new_value, read_back);
}
