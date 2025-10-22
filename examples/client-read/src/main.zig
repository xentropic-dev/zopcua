const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Connect to server
    const client = try ua.Client.init();
    defer client.deinit();

    const server_url = "opc.tcp://localhost:4840";
    std.log.info("Connecting to {s}...", .{server_url});
    try client.connect(server_url);
    defer client.disconnect() catch |err| {
        std.log.err("Failed to disconnect: {}", .{err});
    };

    // Read "the answer" variable from server-simple or server-advanced
    const node_id = ua.NodeId.initString(1, "the.answer");
    std.log.info("Reading node: ns=1;s=the.answer", .{});

    const value = try client.readValueAttribute(node_id, allocator);
    defer value.deinit(allocator);

    // Print the result
    std.log.info("Value: {}", .{value});
}
