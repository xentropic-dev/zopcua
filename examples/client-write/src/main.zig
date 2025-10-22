const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.log.err("Usage: {s} <new-value>", .{args[0]});
        std.log.info("Example: {s} 100", .{args[0]});
        return error.InvalidArguments;
    }

    const new_value_int = try std.fmt.parseInt(i32, args[1], 10);

    // Connect to server
    const client = try ua.Client.init();
    defer client.deinit();

    const server_url = "opc.tcp://localhost:4840";
    std.log.info("Connecting to {s}...", .{server_url});
    try client.connect(server_url);
    defer client.disconnect() catch |err| {
        std.log.err("Failed to disconnect: {}", .{err});
    };

    // Work with "the answer" variable from server-simple or server-advanced
    const node_id = ua.NodeId.initString(1, "the.answer");

    // Read the current value
    std.log.info("Reading current value of: ns=1;s=the.answer", .{});
    const current_value = try client.readValueAttribute(node_id, allocator);
    defer current_value.deinit(allocator);
    std.log.info("Current value: {}", .{current_value});

    // Write the new value
    const new_value = ua.Variant.scalar(i32, new_value_int);
    std.log.info("Writing new value: {}", .{new_value});
    try client.writeValueAttribute(node_id, new_value);

    // Read it back to confirm
    const confirmed_value = try client.readValueAttribute(node_id, allocator);
    defer confirmed_value.deinit(allocator);
    std.log.info("Confirmed value: {}", .{confirmed_value});
}
