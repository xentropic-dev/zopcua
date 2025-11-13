const std = @import("std");
const testing = std.testing;
const zopcua = @import("zopcua");

const Server = zopcua.Server;
const Client = zopcua.Client;
const NodeId = zopcua.NodeId;
const QualifiedName = zopcua.QualifiedName;
const Variant = zopcua.Variant;
const DataValue = zopcua.DataValue;
const AttributeId = zopcua.AttributeId;
const StandardDataType = zopcua.StandardDataType;

test "DataValue read with timestamps" {
    // Start test server with a variable
    var server = try Server.init();
    defer server.deinit();

    _ = try server.addVariableNode(
        NodeId.initString(1, "temperature"),
        zopcua.StandardNodeId.objects_folder,
        zopcua.ReferenceType.organizes,
        QualifiedName.init(1, "Temperature"),
        zopcua.StandardNodeId.base_data_variable_type,
        .{
            .value = Variant.scalar(f64, 25.5),
            .access_level = .{ .read = true },
        },
    );

    try server.start();
    defer server.stop() catch {};
    std.time.sleep(50 * std.time.ns_per_ms);

    // Connect client
    var client = try Client.init();
    defer client.deinit();
    try client.connect("opc.tcp://localhost:4840");
    defer client.disconnect() catch {};

    // Read with timestamps
    const data_value = try client.readDataValue(testing.allocator, NodeId.initString(1, "temperature"));
    defer data_value.deinit(testing.allocator);

    // Verify value
    try testing.expectEqual(Variant.double, @as(std.meta.Tag(Variant), data_value.value));
    try testing.expectEqual(@as(f64, 25.5), data_value.value.double);

    // Verify we got timestamps (they should be non-null for a successful read)
    try testing.expect(data_value.source_timestamp != null or data_value.server_timestamp != null);

    // Verify status is good
    try testing.expectEqual(@as(u32, 0), data_value.status_code);
}

test "Batch DataValue reads" {
    var server = try Server.init();
    defer server.deinit();

    // Add multiple variables
    _ = try server.addVariableNode(
        NodeId.initString(1, "temp1"),
        zopcua.StandardNodeId.objects_folder,
        zopcua.ReferenceType.organizes,
        QualifiedName.init(1, "Temp1"),
        zopcua.StandardNodeId.base_data_variable_type,
        .{ .value = Variant.scalar(f64, 20.0) },
    );

    _ = try server.addVariableNode(
        NodeId.initString(1, "temp2"),
        zopcua.StandardNodeId.objects_folder,
        zopcua.ReferenceType.organizes,
        QualifiedName.init(1, "Temp2"),
        zopcua.StandardNodeId.base_data_variable_type,
        .{ .value = Variant.scalar(f64, 30.0) },
    );

    _ = try server.addVariableNode(
        NodeId.initString(1, "temp3"),
        zopcua.StandardNodeId.objects_folder,
        zopcua.ReferenceType.organizes,
        QualifiedName.init(1, "Temp3"),
        zopcua.StandardNodeId.base_data_variable_type,
        .{ .value = Variant.scalar(f64, 40.0) },
    );

    try server.start();
    defer server.stop() catch {};
    std.time.sleep(50 * std.time.ns_per_ms);

    var client = try Client.init();
    defer client.deinit();
    try client.connect("opc.tcp://localhost:4840");
    defer client.disconnect() catch {};

    // Batch read all three
    const node_ids = [_]NodeId{
        NodeId.initString(1, "temp1"),
        NodeId.initString(1, "temp2"),
        NodeId.initString(1, "temp3"),
    };

    const data_values = try client.readDataValues(testing.allocator, &node_ids);
    defer testing.allocator.free(data_values);
    defer for (data_values) |dv| dv.deinit(testing.allocator);

    // Verify we got all three
    try testing.expectEqual(@as(usize, 3), data_values.len);

    // Verify values
    try testing.expectEqual(@as(f64, 20.0), data_values[0].value.double);
    try testing.expectEqual(@as(f64, 30.0), data_values[1].value.double);
    try testing.expectEqual(@as(f64, 40.0), data_values[2].value.double);
}

test "Batch attribute reading" {
    var server = try Server.init();
    defer server.deinit();

    _ = try server.addVariableNode(
        NodeId.initString(1, "sensor"),
        zopcua.StandardNodeId.objects_folder,
        zopcua.ReferenceType.organizes,
        QualifiedName.init(1, "MySensor"),
        zopcua.StandardNodeId.base_data_variable_type,
        .{
            .value = Variant.scalar(f64, 42.0),
            .access_level = .{ .read = true, .write = true },
        },
    );

    try server.start();
    defer server.stop() catch {};
    std.time.sleep(50 * std.time.ns_per_ms);

    var client = try Client.init();
    defer client.deinit();
    try client.connect("opc.tcp://localhost:4840");
    defer client.disconnect() catch {};

    // Read multiple attributes in one call
    const attrs = [_]AttributeId{
        .node_class,
        .browse_name,
        .display_name,
        .access_level,
    };

    const values = try client.readAttributes(
        testing.allocator,
        NodeId.initString(1, "sensor"),
        &attrs,
    );
    defer testing.allocator.free(values);
    defer for (values) |v| v.deinit(testing.allocator);

    try testing.expectEqual(@as(usize, 4), values.len);

    // Verify node class
    try testing.expectEqual(zopcua.NodeClass.variable, values[0].node_class);

    // Verify browse name
    try testing.expectEqualStrings("MySensor", values[1].qualified_name.name);

    // Verify display name
    try testing.expectEqualStrings("MySensor", values[2].localized_text.text);

    // Verify access level (read + write = 3)
    try testing.expectEqual(@as(u8, 3), values[3].uint8);
}

test "Individual attribute readers" {
    var server = try Server.init();
    defer server.deinit();

    _ = try server.addVariableNode(
        NodeId.initString(1, "testvar"),
        zopcua.StandardNodeId.objects_folder,
        zopcua.ReferenceType.organizes,
        QualifiedName.init(1, "TestVariable"),
        zopcua.StandardNodeId.base_data_variable_type,
        .{
            .value = Variant.scalar(i32, 123),
            .access_level = .{ .read = true },
        },
    );

    try server.start();
    defer server.stop() catch {};
    std.time.sleep(50 * std.time.ns_per_ms);

    var client = try Client.init();
    defer client.deinit();
    try client.connect("opc.tcp://localhost:4840");
    defer client.disconnect() catch {};

    const node = NodeId.initString(1, "testvar");

    // Test individual readers
    const node_class = try client.readNodeClass(node);
    try testing.expectEqual(zopcua.NodeClass.variable, node_class);

    const browse_name = try client.readBrowseName(testing.allocator, node);
    defer testing.allocator.free(browse_name.name);
    try testing.expectEqualStrings("TestVariable", browse_name.name);

    const display_name = try client.readDisplayName(testing.allocator, node);
    defer testing.allocator.free(display_name.locale);
    defer testing.allocator.free(display_name.text);
    try testing.expectEqualStrings("TestVariable", display_name.text);

    const data_type = try client.readDataType(testing.allocator, node);
    defer data_type.deinit(testing.allocator);
    // Should be Int32 (i=6)
    try testing.expectEqual(@as(u16, 0), data_type.numeric.namespace);
    try testing.expectEqual(@as(u32, 6), data_type.numeric.identifier);

    const value_rank = try client.readValueRank(node);
    try testing.expectEqual(@as(i32, -1), value_rank); // Scalar

    const access_level = try client.readAccessLevel(node);
    try testing.expectEqual(@as(u8, 1), access_level); // Read only
}

test "StandardDataType helpers" {
    // Test enum conversions
    const double_type = StandardDataType.double;
    try testing.expectEqualStrings("Double", double_type.name());

    const node_id = double_type.toNodeId();
    try testing.expectEqual(@as(u16, 0), node_id.numeric.namespace);
    try testing.expectEqual(@as(u32, 11), node_id.numeric.identifier);

    const maybe_type = StandardDataType.fromNodeId(node_id);
    try testing.expect(maybe_type != null);
    try testing.expectEqual(StandardDataType.double, maybe_type.?);

    // Test getDataTypeName
    try testing.expectEqualStrings("Double", zopcua.getDataTypeName(node_id));

    // Test unknown type
    const custom = NodeId.initNumeric(5, 999);
    try testing.expectEqualStrings("Unknown", zopcua.getDataTypeName(custom));

    // Test various standard types
    try testing.expectEqualStrings("Boolean", StandardDataType.boolean.name());
    try testing.expectEqualStrings("String", StandardDataType.string.name());
    try testing.expectEqualStrings("Int32", StandardDataType.int32.name());
    try testing.expectEqualStrings("DateTime", StandardDataType.datetime.name());
}

test "runIterate for subscriptions" {
    var server = try Server.init();
    defer server.deinit();

    _ = try server.addVariableNode(
        NodeId.initString(1, "counter"),
        zopcua.StandardNodeId.objects_folder,
        zopcua.ReferenceType.organizes,
        QualifiedName.init(1, "Counter"),
        zopcua.StandardNodeId.base_data_variable_type,
        .{
            .value = Variant.scalar(i32, 0),
            .access_level = .{ .read = true, .write = true },
        },
    );

    try server.start();
    defer server.stop() catch {};
    std.time.sleep(50 * std.time.ns_per_ms);

    var client = try Client.init();
    defer client.deinit();
    try client.connect("opc.tcp://localhost:4840");
    defer client.disconnect() catch {};

    // Create subscription
    const sub_id = try client.createSubscription(.{
        .publishing_interval = 100.0,
        .priority = 10,
    });
    defer client.deleteSubscription(sub_id) catch {};

    const CallbackContext = struct {
        received: bool = false,
        value: i32 = 0,
    };

    var ctx = CallbackContext{};

    const callback = struct {
        fn onDataChange(
            userdata: ?*anyopaque,
            _: zopcua.SubscriptionId,
            _: zopcua.MonitoredItemId,
            value: *const Variant,
        ) void {
            const c: *CallbackContext = @ptrCast(@alignCast(userdata.?));
            c.received = true;
            if (value.* == .int32) {
                c.value = value.int32;
            }
        }
    }.onDataChange;

    // Create monitored item with callback
    const mon_id = try client.createMonitoredItemWithCallback(
        sub_id,
        .{
            .node_id = NodeId.initString(1, "counter"),
            .sampling_interval = 50.0,
            .queue_size = 10,
        },
        callback,
        &ctx,
    );
    defer client.deleteMonitoredItem(sub_id, mon_id) catch {};

    // Process initial notification
    try client.runIterate(200);
    std.time.sleep(50 * std.time.ns_per_ms);

    // Write a new value
    try client.writeValueAttribute(
        NodeId.initString(1, "counter"),
        Variant.scalar(i32, 42),
    );

    // Process notifications using runIterate
    try client.runIterate(200);
    std.time.sleep(100 * std.time.ns_per_ms);
    try client.runIterate(200);

    // Verify callback was invoked
    try testing.expect(ctx.received);
    try testing.expectEqual(@as(i32, 42), ctx.value);
}

test "DataValue timestamp conversion" {
    // Test the timestamp conversion function directly
    try testing.expectEqual(@as(?i64, null), DataValue.opcuaDateTimeToUnix(0));

    // Known timestamp: Jan 1, 2000 00:00:00 UTC
    const opcua_ts: i64 = 125911584000000000;
    const unix_ts = DataValue.opcuaDateTimeToUnix(opcua_ts);
    try testing.expectEqual(@as(?i64, 946684800), unix_ts);
}
