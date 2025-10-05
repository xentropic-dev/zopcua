const std = @import("std");
const ua = @import("ua");

var running = std.atomic.Value(bool).init(true);

fn handleSignal(sig: c_int) callconv(.C) void {
    _ = sig;
    running.store(false, .seq_cst);
}

/// Add demo variables to the server
fn addDemoVariables(server: *ua.Server, allocator: std.mem.Allocator) !void {
    // Add variables directly to the Objects folder
    const parent = ua.StandardNodeId.objects_folder;

    // Integer variable - "the answer"
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "the.answer"),
        parent,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "the answer"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(i32, 42),
            .description = ua.LocalizedText.init("en-US", "the answer to life, the universe, and everything"),
            .display_name = ua.LocalizedText.init("en-US", "The Answer"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    // Temperature sensor (double)
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "temperature"),
        parent,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Temperature"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(f64, 23.5),
            .description = ua.LocalizedText.init("en-US", "Current temperature in Celsius"),
            .display_name = ua.LocalizedText.init("en-US", "Temperature (°C)"),
            .access_level = .{ .read = true },
        },
        allocator,
    );

    // Status string
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "status"),
        parent,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Status"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar([]const u8, "Running"),
            .description = ua.LocalizedText.initText("System status"),
            .display_name = ua.LocalizedText.init("en-US", "System Status"),
            .access_level = .{ .read = true },
        },
        allocator,
    );

    // Boolean flag
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "enabled"),
        parent,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Enabled"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(bool, true),
            .description = ua.LocalizedText.initText("System enabled flag"),
            .display_name = ua.LocalizedText.init("en-US", "Enabled"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    // Array of measurements
    const measurements = [_]f64{ 10.1, 20.2, 30.3, 40.4, 50.5 };
    const array_dims = [_]u32{5}; // Specify the array dimension size
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "measurements"),
        parent,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Measurements"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.array(f64, &measurements),
            .description = ua.LocalizedText.initText("Array of measurement values"),
            .display_name = ua.LocalizedText.init("en-US", "Measurements"),
            .access_level = .{ .read = true },
            .value_rank = 1, // One-dimensional array
            .array_dimensions = &array_dims, // Must match value_rank
        },
        allocator,
    );

    // Counter (unsigned int)
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "counter"),
        parent,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Counter"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(u32, 0),
            .description = ua.LocalizedText.initText("Event counter"),
            .display_name = ua.LocalizedText.init("en-US", "Event Counter"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    // Pressure reading (float)
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "pressure"),
        parent,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Pressure"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(f32, 101.325),
            .description = ua.LocalizedText.initText("Atmospheric pressure in kPa"),
            .display_name = ua.LocalizedText.init("en-US", "Pressure (kPa)"),
            .access_level = .{ .read = true },
        },
        allocator,
    );

    // Byte value
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "byte_value"),
        parent,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "ByteValue"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(u8, 255),
            .description = ua.LocalizedText.initText("Single byte value"),
            .display_name = ua.LocalizedText.init("en-US", "Byte Value"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    std.log.info("Successfully created 8 demo variables", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const act = std.posix.Sigaction{
        .handler = .{ .handler = handleSignal },
        .mask = std.posix.empty_sigset,
        .flags = 0,
    };
    std.posix.sigaction(std.posix.SIG.INT, &act, null);
    std.posix.sigaction(std.posix.SIG.TERM, &act, null);

    var server = try ua.Server.init();
    defer server.deinit();

    try addDemoVariables(&server, allocator);

    try server.start();
    defer server.stop() catch |err| {
        std.log.err("Failed to stop server: {}", .{err});
    };

    std.log.info("OPC UA Server started on port 4840. Press Ctrl-C to stop.", .{});
    std.log.info("Browse to 'Objects' folder to see all demo variables", .{});

    while (running.load(.seq_cst)) {
        _ = server.iterate(true);
    }

    std.log.info("Shutting down server...", .{});
}
