const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var server = try ua.Server.init();
    defer server.deinit();

    // Add a simple integer variable "the answer" = 42
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "the.answer"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "the answer"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(i32, 42),
            .display_name = ua.LocalizedText.init("en-US", "The Answer"),
            .description = ua.LocalizedText.init("en-US", "The answer to life, the universe, and everything"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    std.log.info("Server starting on opc.tcp://localhost:4840", .{});
    std.log.info("Variable 'the answer' = 42 (NodeId: ns=1;s=the.answer)", .{});

    try server.runUntilInterrupt();
}
