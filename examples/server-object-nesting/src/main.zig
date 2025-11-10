const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var server = try ua.Server.init();
    defer server.deinit();

    std.log.info("Creating organized node structure with object folders...", .{});

    // Create a "Equipment" folder to organize all equipment
    const equipment_folder = try server.addObjectNode(
        ua.NodeId.initString(1, "equipment"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Equipment"),
        ua.StandardNodeId.folder_type,
        .{
            .display_name = ua.LocalizedText.init("en-US", "Equipment"),
            .description = ua.LocalizedText.initText("All plant equipment"),
        },
    );

    // Create a "Sensors" folder under Equipment
    const sensors_folder = try server.addObjectNode(
        ua.NodeId.initString(1, "sensors"),
        equipment_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Sensors"),
        ua.StandardNodeId.folder_type,
        .{
            .display_name = ua.LocalizedText.init("en-US", "Sensors"),
            .description = ua.LocalizedText.initText("Sensor measurements"),
        },
    );

    // Create an "Actuators" folder under Equipment
    const actuators_folder = try server.addObjectNode(
        ua.NodeId.initString(1, "actuators"),
        equipment_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Actuators"),
        ua.StandardNodeId.folder_type,
        .{
            .display_name = ua.LocalizedText.init("en-US", "Actuators"),
            .description = ua.LocalizedText.initText("Control actuators"),
        },
    );

    // Add temperature sensor under Sensors folder
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "temperature"),
        sensors_folder,
        ua.ReferenceType.has_component,
        ua.QualifiedName.init(1, "Temperature"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(f64, 23.5),
            .display_name = ua.LocalizedText.init("en-US", "Temperature"),
            .description = ua.LocalizedText.initText("Ambient temperature in Celsius"),
            .access_level = .{ .read = true },
        },
    );

    // Add pressure sensor under Sensors folder
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "pressure"),
        sensors_folder,
        ua.ReferenceType.has_component,
        ua.QualifiedName.init(1, "Pressure"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(f64, 101.325),
            .display_name = ua.LocalizedText.init("en-US", "Pressure"),
            .description = ua.LocalizedText.initText("Atmospheric pressure in kPa"),
            .access_level = .{ .read = true },
        },
    );

    // Add humidity sensor under Sensors folder
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "humidity"),
        sensors_folder,
        ua.ReferenceType.has_component,
        ua.QualifiedName.init(1, "Humidity"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(f64, 45.0),
            .display_name = ua.LocalizedText.init("en-US", "Humidity"),
            .description = ua.LocalizedText.initText("Relative humidity percentage"),
            .access_level = .{ .read = true },
        },
    );

    // Add valve position under Actuators folder
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "valve_position"),
        actuators_folder,
        ua.ReferenceType.has_component,
        ua.QualifiedName.init(1, "ValvePosition"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(f64, 50.0),
            .display_name = ua.LocalizedText.init("en-US", "Valve Position"),
            .description = ua.LocalizedText.initText("Main valve position (0-100%)"),
            .access_level = .{ .read = true, .write = true },
        },
    );

    // Add motor speed under Actuators folder
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "motor_speed"),
        actuators_folder,
        ua.ReferenceType.has_component,
        ua.QualifiedName.init(1, "MotorSpeed"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(f64, 1500.0),
            .display_name = ua.LocalizedText.init("en-US", "Motor Speed"),
            .description = ua.LocalizedText.initText("Motor speed in RPM"),
            .access_level = .{ .read = true, .write = true },
        },
    );

    std.log.info("Node structure created:", .{});
    std.log.info("  Equipment/", .{});
    std.log.info("    ├── Sensors/", .{});
    std.log.info("    │   ├── Temperature (23.5°C)", .{});
    std.log.info("    │   ├── Pressure (101.325 kPa)", .{});
    std.log.info("    │   └── Humidity (45.0%)", .{});
    std.log.info("    └── Actuators/", .{});
    std.log.info("        ├── ValvePosition (50.0%)", .{});
    std.log.info("        └── MotorSpeed (1500.0 RPM)", .{});
    std.log.info("", .{});
    std.log.info("Server starting on opc.tcp://localhost:4840", .{});
    std.log.info("Browse to ns=1;s=equipment to see the organized structure", .{});

    try server.runUntilInterrupt();
}
