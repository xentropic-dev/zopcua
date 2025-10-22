const std = @import("std");
const ua = @import("src/root.zig");

pub fn main() !void {
    std.debug.print("About to call Server.init()\n", .{});
    var server = try ua.Server.init();
    defer server.deinit();
    std.debug.print("Server.init() succeeded\n", .{});
}
