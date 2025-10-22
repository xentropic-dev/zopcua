const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    std.debug.print("Connecting to example server on localhost:4840...\n", .{});

    var client = try ua.Client.init();
    defer client.deinit();

    try client.connect("opc.tcp://localhost:4840");
    std.debug.print("Connected!\n", .{});

    // Try to write to "the.answer" node (ns=1;s=the.answer)
    const node_id = ua.NodeId.initString(1, "the.answer");
    const new_value = ua.Variant.scalar(i32, 999);

    std.debug.print("Writing value 999...\n", .{});
    try client.writeValueAttribute(node_id, new_value);
    std.debug.print("Write successful!\n", .{});

    // Read it back
    const allocator = std.heap.page_allocator;
    const read_value = try client.readValueAttribute(node_id, allocator);
    defer read_value.deinit(allocator);

    std.debug.print("Read value: {}\n", .{read_value.int32});

    try client.disconnect();
}
