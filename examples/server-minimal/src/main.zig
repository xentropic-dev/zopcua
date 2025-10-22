const ua = @import("ua");

pub fn main() !void {
    var server = try ua.Server.init();
    defer server.deinit();

    try server.runUntilInterrupt();
}
