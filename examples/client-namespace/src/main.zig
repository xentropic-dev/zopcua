const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try ua.Client.init();
    defer client.deinit();

    std.log.info("Connecting to server at opc.tcp://localhost:4840...", .{});
    try client.connect("opc.tcp://localhost:4840");
    defer client.disconnect() catch |err| {
        std.log.err("Failed to disconnect: {}", .{err});
    };

    std.log.info("Connected successfully!", .{});

    // Discover standard OPC UA namespace
    const std_ns = try client.getNamespaceByName("http://opcfoundation.org/UA/");
    std.log.info("OPC UA standard namespace index: {d}", .{std_ns});

    // Discover custom namespaces from the server
    // (Assumes a server with these namespaces is running - see server-namespace example)
    const sensor_ns = client.getNamespaceByName("http://example.com/sensors") catch |err| {
        std.log.warn("Could not find sensors namespace: {s}", .{@errorName(err)});
        std.log.info("Make sure the server-namespace example is running first!", .{});
        return err;
    };
    std.log.info("Sensors namespace index: {d}", .{sensor_ns});

    const actuator_ns = client.getNamespaceByName("http://example.com/actuators") catch null;

    if (actuator_ns) |ns| {
        std.log.info("Actuators namespace index: {d}", .{ns});
    }

    // Use discovered namespace indices to read variables
    std.log.info("\nReading variables from discovered namespaces...", .{});

    // Read temperature from sensors namespace
    const temp_node = ua.NodeId.initString(sensor_ns, "temperature");
    const temp_value = try client.readValueAttribute(allocator, temp_node);
    defer temp_value.deinit(allocator);

    std.log.info("Temperature (ns={d};s=temperature): {d}°C", .{ sensor_ns, temp_value.double });

    // Read humidity from sensors namespace
    const humidity_node = ua.NodeId.initString(sensor_ns, "humidity");
    const humidity_value = try client.readValueAttribute(allocator, humidity_node);
    defer humidity_value.deinit(allocator);

    std.log.info("Humidity (ns={d};s=humidity): {d}%", .{ sensor_ns, humidity_value.double });

    // Read valve state from actuators namespace (if available)
    if (actuator_ns) |ns| {
        const valve_node = ua.NodeId.initString(ns, "valve");
        const valve_value = try client.readValueAttribute(allocator, valve_node);
        defer valve_value.deinit(allocator);

        const valve_state = if (valve_value.boolean) "OPEN" else "CLOSED";
        std.log.info("Valve (ns={d};s=valve): {s}", .{ ns, valve_state });

        // Write to valve
        std.log.info("\nToggling valve state...", .{});
        const new_state = !valve_value.boolean;
        try client.writeValueAttribute(valve_node, ua.Variant.scalar(bool, new_state));

        // Read back to confirm
        const updated_value = try client.readValueAttribute(allocator, valve_node);
        defer updated_value.deinit(allocator);

        const updated_state = if (updated_value.boolean) "OPEN" else "CLOSED";
        std.log.info("Valve after toggle: {s}", .{updated_state});
    }

    std.log.info("\n✓ Successfully demonstrated dynamic namespace discovery!", .{});
}
