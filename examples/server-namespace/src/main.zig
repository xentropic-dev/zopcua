const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var server = try ua.Server.init();
    defer server.deinit();

    // Add custom namespaces
    const sensor_ns = try server.addNamespace("http://example.com/sensors");
    const actuator_ns = try server.addNamespace("http://example.com/actuators");

    std.log.info("Created sensor namespace at index {d}", .{sensor_ns});
    std.log.info("Created actuator namespace at index {d}", .{actuator_ns});

    // Verify namespace lookup
    const found_ns = try server.getNamespaceByName("http://example.com/sensors");
    std.log.info("Verified sensor namespace lookup: index {d}", .{found_ns});

    // Add nodes in different namespaces
    _ = try server.addVariableNode(
        ua.NodeId.initString(sensor_ns, "temperature"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(sensor_ns, "Temperature"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(f64, 22.5),
            .display_name = ua.LocalizedText.init("en-US", "Temperature Sensor"),
            .description = ua.LocalizedText.init("en-US", "Temperature in Celsius"),
            .access_level = .{ .read = true },
        },
    );

    _ = try server.addVariableNode(
        ua.NodeId.initString(sensor_ns, "humidity"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(sensor_ns, "Humidity"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(f64, 65.0),
            .display_name = ua.LocalizedText.init("en-US", "Humidity Sensor"),
            .description = ua.LocalizedText.init("en-US", "Relative humidity percentage"),
            .access_level = .{ .read = true },
        },
    );

    _ = try server.addVariableNode(
        ua.NodeId.initString(actuator_ns, "valve"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(actuator_ns, "Valve"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(bool, false),
            .display_name = ua.LocalizedText.init("en-US", "Control Valve"),
            .description = ua.LocalizedText.init("en-US", "Main control valve (open/closed)"),
            .access_level = .{ .read = true, .write = true },
        },
    );

    std.log.info("Server running on opc.tcp://localhost:4840", .{});
    std.log.info("Variables:", .{});
    std.log.info("  - Temperature: ns={d};s=temperature", .{sensor_ns});
    std.log.info("  - Humidity: ns={d};s=humidity", .{sensor_ns});
    std.log.info("  - Valve: ns={d};s=valve", .{actuator_ns});

    try server.runUntilInterrupt();
}
