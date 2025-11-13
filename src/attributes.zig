const std = @import("std");
const c = @import("c.zig");
const NodeId = @import("types.zig").NodeId;
const QualifiedName = @import("types.zig").QualifiedName;
const NodeClass = @import("types.zig").NodeClass;
const LocalizedText = @import("localized_text.zig").LocalizedText;

/// Attribute identifier enum for OPC UA attributes
pub const AttributeId = enum(u32) {
    node_id = 1,
    node_class = 2,
    browse_name = 3,
    display_name = 4,
    description = 5,
    write_mask = 6,
    user_write_mask = 7,
    is_abstract = 8,
    symmetric = 9,
    inverse_name = 10,
    contains_no_loops = 11,
    event_notifier = 12,
    value = 13,
    data_type = 14,
    value_rank = 15,
    array_dimensions = 16,
    access_level = 17,
    user_access_level = 18,
    minimum_sampling_interval = 19,
    historizing = 20,
    executable = 21,
    user_executable = 22,

    pub fn toC(self: AttributeId) u32 {
        return @intFromEnum(self);
    }
};

/// Result of reading a single attribute
pub const AttributeValue = union(enum) {
    node_id: NodeId,
    node_class: NodeClass,
    qualified_name: QualifiedName,
    localized_text: LocalizedText,
    uint32: u32,
    uint8: u8,
    int32: i32,
    double: f64,
    boolean: bool,
    byte_string: []const u8,
    uint32_array: []const u32,
    status_error: u32, // Contains status code if read failed

    pub fn deinit(self: AttributeValue, allocator: std.mem.Allocator) void {
        switch (self) {
            .node_id => |nid| nid.deinit(allocator),
            .qualified_name => |*qn| allocator.free(qn.name),
            .localized_text => |*lt| {
                allocator.free(lt.locale);
                allocator.free(lt.text);
            },
            .byte_string => |bs| allocator.free(bs),
            .uint32_array => |arr| allocator.free(arr),
            else => {},
        }
    }
};

test "AttributeId conversion" {
    const testing = std.testing;
    std.testing.refAllDecls(@This());

    try testing.expectEqual(@as(u32, 1), AttributeId.node_id.toC());
    try testing.expectEqual(@as(u32, 2), AttributeId.node_class.toC());
    try testing.expectEqual(@as(u32, 13), AttributeId.value.toC());
}
