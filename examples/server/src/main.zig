var running = std.atomic.Value(bool).init(true);

fn handleSignal(sig: c_int) callconv(.C) void {
    _ = sig;
    running.store(false, .seq_cst);
}

pub fn main() !void {
    const act = std.posix.Sigaction{
        .handler = .{ .handler = handleSignal },
        .mask = std.posix.empty_sigset,
        .flags = 0,
    };

    std.posix.sigaction(std.posix.SIG.INT, &act, null);
    std.posix.sigaction(std.posix.SIG.TERM, &act, null);

    var server = try ua.Server.init();
    defer server.deinit();
    try server.start();
    defer server.stop() catch |err| {
        std.log.err("Failed to stop server: {}", .{err});
    };

    std.log.info("OPC UA Server started on port 4840. Press Ctrl-C to stop.", .{});

    while (running.load(.seq_cst)) {
        _ = server.iterate(true);
    }

    std.log.info("Shutting down server...", .{});
}

const std = @import("std");
const ua = @import("ua");
