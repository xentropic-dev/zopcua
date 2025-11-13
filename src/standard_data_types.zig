const c = @import("c.zig");
const NodeId = @import("types.zig").NodeId;

/// Standard OPC UA data types with their NodeIds
pub const StandardDataType = enum(u32) {
    boolean = 1,
    sbyte = 2,
    byte = 3,
    int16 = 4,
    uint16 = 5,
    int32 = 6,
    uint32 = 7,
    int64 = 8,
    uint64 = 9,
    float = 10,
    double = 11,
    string = 12,
    datetime = 13,
    guid = 14,
    bytestring = 15,
    xml_element = 16,
    node_id = 17,
    expanded_node_id = 18,
    status_code = 19,
    qualified_name = 20,
    localized_text = 21,
    extension_object = 22,
    data_value = 23,
    variant = 24,
    diagnostic_info = 25,

    /// Convert from a NodeId to a StandardDataType (if it matches)
    pub fn fromNodeId(node_id: NodeId) ?StandardDataType {
        return switch (node_id) {
            .numeric => |n| blk: {
                if (n.namespace != 0) break :blk null;
                break :blk std.meta.intToEnum(StandardDataType, n.identifier) catch null;
            },
            else => null,
        };
    }

    /// Convert to a NodeId
    pub fn toNodeId(self: StandardDataType) NodeId {
        return NodeId.initNumeric(0, @intFromEnum(self));
    }

    /// Get the human-readable name of the data type
    pub fn name(self: StandardDataType) []const u8 {
        return switch (self) {
            .boolean => "Boolean",
            .sbyte => "SByte",
            .byte => "Byte",
            .int16 => "Int16",
            .uint16 => "UInt16",
            .int32 => "Int32",
            .uint32 => "UInt32",
            .int64 => "Int64",
            .uint64 => "UInt64",
            .float => "Float",
            .double => "Double",
            .string => "String",
            .datetime => "DateTime",
            .guid => "Guid",
            .bytestring => "ByteString",
            .xml_element => "XmlElement",
            .node_id => "NodeId",
            .expanded_node_id => "ExpandedNodeId",
            .status_code => "StatusCode",
            .qualified_name => "QualifiedName",
            .localized_text => "LocalizedText",
            .extension_object => "ExtensionObject",
            .data_value => "DataValue",
            .variant => "Variant",
            .diagnostic_info => "DiagnosticInfo",
        };
    }
};

/// Get human-readable name for any data type NodeId (including custom types)
pub fn getDataTypeName(data_type_id: NodeId) []const u8 {
    if (StandardDataType.fromNodeId(data_type_id)) |std_type| {
        return std_type.name();
    }
    return "Unknown";
}

const std = @import("std");

test "StandardDataType conversion" {
    const testing = std.testing;
    std.testing.refAllDecls(@This());

    // Test toNodeId
    const double_node_id = StandardDataType.double.toNodeId();
    try testing.expectEqual(@as(u16, 0), double_node_id.numeric.namespace);
    try testing.expectEqual(@as(u32, 11), double_node_id.numeric.identifier);

    // Test fromNodeId
    const maybe_type = StandardDataType.fromNodeId(double_node_id);
    try testing.expect(maybe_type != null);
    try testing.expectEqual(StandardDataType.double, maybe_type.?);

    // Test name
    try testing.expectEqualStrings("Double", StandardDataType.double.name());
    try testing.expectEqualStrings("Boolean", StandardDataType.boolean.name());
}

test "StandardDataType getDataTypeName" {
    const testing = std.testing;

    // Test standard type
    const double_node_id = NodeId.initNumeric(0, 11);
    try testing.expectEqualStrings("Double", getDataTypeName(double_node_id));

    // Test custom type
    const custom_node_id = NodeId.initNumeric(2, 1001);
    try testing.expectEqualStrings("Unknown", getDataTypeName(custom_node_id));
}
