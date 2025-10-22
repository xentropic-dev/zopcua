const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    const client = try ua.Client.init();
    defer client.deinit();

    const url = "opc.tcp://localhost:4840";
    std.log.info("Connecting to {s}...", .{url});

    try client.connect(url);
    defer client.disconnect() catch |err| {
        std.log.err("Failed to disconnect: {}", .{err});
    };

    std.log.info("Connected successfully!", .{});
}
