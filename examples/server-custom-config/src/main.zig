const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a server with custom configuration
    // This example demonstrates how to configure:
    // - Custom port (8080 instead of default 4840)
    // - Custom TCP buffer size (128KB instead of default 64KB)
    // - Custom shutdown delay (1 second graceful shutdown)
    var server = try ua.Server.initWithConfig(.{
        .port = 8080,
        .tcp_buf_size = 131072, // 128KB
        .shutdown_delay = 1000.0, // 1 second in milliseconds
    });
    defer server.deinit();

    // Add a simple temperature variable to demonstrate the server works
    _ = try server.addVariableNode(

        ua.NodeId.initString(1, "temperature"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Temperature"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(f64, 21.5),
            .display_name = ua.LocalizedText.init("en-US", "Temperature"),
            .description = ua.LocalizedText.init("en-US", "Current room temperature in Celsius"),
            .access_level = .{ .read = true, .write = true },
        },
    );

    // Add a counter variable
    _ = try server.addVariableNode(

        ua.NodeId.initString(1, "counter"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Counter"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(u32, 0),
            .display_name = ua.LocalizedText.init("en-US", "Counter"),
            .description = ua.LocalizedText.init("en-US", "A simple counter variable"),
            .access_level = .{ .read = true, .write = true },
        },
    );

    std.log.info("=== Custom Configuration Server ===", .{});
    std.log.info("Server starting with custom configuration:", .{});
    std.log.info("  - Port: 8080 (custom)", .{});
    std.log.info("  - TCP Buffer: 128KB (custom)", .{});
    std.log.info("  - Shutdown delay: 1000ms (custom)", .{});
    std.log.info("", .{});
    std.log.info("Connect to: opc.tcp://localhost:8080", .{});
    std.log.info("", .{});
    std.log.info("Available variables:", .{});
    std.log.info("  - Temperature (ns=1;s=temperature) = 21.5 °C", .{});
    std.log.info("  - Counter (ns=1;s=counter) = 0", .{});
    std.log.info("", .{});
    std.log.info("Press Ctrl-C to stop", .{});

    try server.runUntilInterrupt();
}
