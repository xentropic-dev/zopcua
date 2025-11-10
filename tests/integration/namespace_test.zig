const std = @import("std");
const ua = @import("ua");

test "namespace management end-to-end" {
    const testing = std.testing;

    var server = try ua.Server.init();
    defer server.deinit();

    // Add custom namespaces
    const sensor_ns = try server.addNamespace("http://example.com/sensors");
    const control_ns = try server.addNamespace("http://example.com/controls");

    // Verify indices are sequential
    try testing.expectEqual(@as(u16, 2), sensor_ns);
    try testing.expectEqual(@as(u16, 3), control_ns);

    // Lookup by name
    const found_sensor = try server.getNamespaceByName("http://example.com/sensors");
    try testing.expectEqual(sensor_ns, found_sensor);

    // Lookup by index
    const sensor_uri = try server.getNamespaceByIndex(testing.allocator, sensor_ns);
    defer testing.allocator.free(sensor_uri);
    try testing.expectEqualStrings("http://example.com/sensors", sensor_uri);

    // Use namespace in node creation
    _ = try server.addVariableNode(
        ua.NodeId.initString(sensor_ns, "temperature"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(sensor_ns, "Temperature"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(f64, 23.5),
            .display_name = ua.LocalizedText.init("en-US", "Temperature Sensor"),
            .access_level = .{ .read = true },
        },
    );
}

test "namespace persistence across server lifecycle" {
    const testing = std.testing;

    var server = try ua.Server.init();

    const ns_idx = try server.addNamespace("http://example.com/persistent");

    // Start and stop server (namespace should survive)
    try server.start();

    // Verify namespace still accessible
    const found = try server.getNamespaceByName("http://example.com/persistent");
    try testing.expectEqual(ns_idx, found);

    try server.stop();
    server.deinit();
}
