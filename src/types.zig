const std = @import("std");
const c = @import("c.zig");
const String = @import("localized_text.zig").String;

const StatusCode = c.UA_StatusCode;
const STATUSCODE_GOOD = c.UA_STATUSCODE_GOOD;

pub const NodeId = union(enum) {
    numeric: struct {
        namespace: u16,
        identifier: u32,
    },
    string: struct {
        namespace: u16,
        identifier: []const u8,
    },
    guid: struct {
        namespace: u16,
        identifier: Guid,
    },
    byte_string: struct {
        namespace: u16,
        identifier: []const u8,
    },

    /// Create a numeric NodeId
    pub fn initNumeric(namespace: u16, identifier: u32) NodeId {
        return .{ .numeric = .{ .namespace = namespace, .identifier = identifier } };
    }

    /// Create a string NodeId
    pub fn initString(namespace: u16, identifier: []const u8) NodeId {
        return .{ .string = .{ .namespace = namespace, .identifier = identifier } };
    }

    /// Create a GUID NodeId
    pub fn initGuid(namespace: u16, identifier: Guid) NodeId {
        return .{ .guid = .{ .namespace = namespace, .identifier = identifier } };
    }

    /// Create a ByteString NodeId
    pub fn initByteString(namespace: u16, identifier: []const u8) NodeId {
        return .{ .byte_string = .{ .namespace = namespace, .identifier = identifier } };
    }

    /// Null/empty NodeId
    pub const null_id = NodeId{ .numeric = .{ .namespace = 0, .identifier = 0 } };

    /// Convert to C API representation
    pub fn toC(self: NodeId) c.UA_NodeId {
        return switch (self) {
            .numeric => |n| c.UA_NODEID_NUMERIC(n.namespace, n.identifier),
            .string => |s| c.UA_NODEID_STRING(s.namespace, @constCast(s.identifier.ptr)),
            .guid => |g| c.UA_NODEID_GUID(g.namespace, g.identifier.toC()),
            .byte_string => |b| c.UA_NODEID_BYTESTRING(b.namespace, @constCast(b.identifier.ptr)),
        };
    }

    /// Convert from C API representation
    pub fn fromC(value: c.UA_NodeId) NodeId {
        return switch (value.identifierType) {
            c.UA_NODEIDTYPE_NUMERIC => .{
                .numeric = .{
                    .namespace = value.namespaceIndex,
                    .identifier = value.identifier.numeric,
                },
            },
            c.UA_NODEIDTYPE_STRING => .{
                .string = .{
                    .namespace = value.namespaceIndex,
                    .identifier = String.fromC(value.identifier.string),
                },
            },
            c.UA_NODEIDTYPE_GUID => .{
                .guid = .{
                    .namespace = value.namespaceIndex,
                    .identifier = Guid.fromC(value.identifier.guid),
                },
            },
            c.UA_NODEIDTYPE_BYTESTRING => .{
                .byte_string = .{
                    .namespace = value.namespaceIndex,
                    .identifier = String.fromC(value.identifier.byteString),
                },
            },
            else => NodeId.null_id,
        };
    }
};

/// QualifiedName wrapper
pub const QualifiedName = struct {
    namespace_index: u16,
    name: []const u8,

    pub fn init(namespace_index: u16, name: []const u8) QualifiedName {
        return .{ .namespace_index = namespace_index, .name = name };
    }

    pub fn toC(self: QualifiedName) c.UA_QualifiedName {
        return c.UA_QUALIFIEDNAME(self.namespace_index, @constCast(self.name.ptr));
    }

    pub fn fromC(value: c.UA_QualifiedName) QualifiedName {
        return .{
            .namespace_index = value.namespaceIndex,
            .name = String.fromC(value.name),
        };
    }
};

pub const Guid = struct {
    data1: u32,
    data2: u16,
    data3: u16,
    data4: [8]u8,

    pub fn fromC(value: c.UA_Guid) Guid {
        return .{
            .data1 = value.data1,
            .data2 = value.data2,
            .data3 = value.data3,
            .data4 = value.data4,
        };
    }

    pub fn toC(self: Guid) c.UA_Guid {
        return .{
            .data1 = self.data1,
            .data2 = self.data2,
            .data3 = self.data3,
            .data4 = self.data4,
        };
    }
};

pub const ReferenceType = struct {
    pub const organizes = NodeId.initNumeric(0, c.UA_NS0ID_ORGANIZES);
    pub const has_component = NodeId.initNumeric(0, c.UA_NS0ID_HASCOMPONENT);
    pub const has_property = NodeId.initNumeric(0, c.UA_NS0ID_HASPROPERTY);
    pub const has_type_definition = NodeId.initNumeric(0, c.UA_NS0ID_HASTYPEDEFINITION);
};

pub const StandardNodeId = struct {
    // Folders
    pub const objects_folder = NodeId.initNumeric(0, c.UA_NS0ID_OBJECTSFOLDER);
    pub const types_folder = NodeId.initNumeric(0, c.UA_NS0ID_TYPESFOLDER);
    pub const views_folder = NodeId.initNumeric(0, c.UA_NS0ID_VIEWSFOLDER);

    // Object Types
    pub const base_object_type = NodeId.initNumeric(0, c.UA_NS0ID_BASEOBJECTTYPE);
    pub const folder_type = NodeId.initNumeric(0, c.UA_NS0ID_FOLDERTYPE);

    // Variable Types
    pub const base_data_variable_type = NodeId.initNumeric(0, c.UA_NS0ID_BASEDATAVARIABLETYPE);
    pub const property_type = NodeId.initNumeric(0, c.UA_NS0ID_PROPERTYTYPE);
};

test "NodeId numeric creation and conversion" {
    const testing = std.testing;

    const node_id = NodeId.initNumeric(1, 42);
    try testing.expectEqual(@as(u16, 1), node_id.numeric.namespace);
    try testing.expectEqual(@as(u32, 42), node_id.numeric.identifier);

    const c_node_id = node_id.toC();
    const roundtrip = NodeId.fromC(c_node_id);
    try testing.expectEqual(node_id.numeric.namespace, roundtrip.numeric.namespace);
    try testing.expectEqual(node_id.numeric.identifier, roundtrip.numeric.identifier);
}

test "NodeId string creation and conversion" {
    const testing = std.testing;

    const node_id = NodeId.initString(2, "test.node");
    try testing.expectEqual(@as(u16, 2), node_id.string.namespace);
    try testing.expectEqualStrings("test.node", node_id.string.identifier);

    const c_node_id = node_id.toC();
    const roundtrip = NodeId.fromC(c_node_id);
    try testing.expectEqual(node_id.string.namespace, roundtrip.string.namespace);
    try testing.expectEqualStrings(node_id.string.identifier, roundtrip.string.identifier);
}

test "NodeId null_id" {
    const testing = std.testing;

    const null_id = NodeId.null_id;
    try testing.expectEqual(@as(u16, 0), null_id.numeric.namespace);
    try testing.expectEqual(@as(u32, 0), null_id.numeric.identifier);
}

test "StandardNodeId constants" {
    const testing = std.testing;

    try testing.expectEqual(@as(u16, 0), StandardNodeId.objects_folder.numeric.namespace);
    try testing.expectEqual(@as(u16, 0), StandardNodeId.base_data_variable_type.numeric.namespace);
}

test "QualifiedName creation and conversion" {
    const testing = std.testing;

    const qname = QualifiedName.init(1, "MyVariable");
    try testing.expectEqual(@as(u16, 1), qname.namespace_index);
    try testing.expectEqualStrings("MyVariable", qname.name);

    const c_qname = qname.toC();
    const roundtrip = QualifiedName.fromC(c_qname);
    try testing.expectEqual(qname.namespace_index, roundtrip.namespace_index);
    try testing.expectEqualStrings(qname.name, roundtrip.name);
}

test "Guid creation and conversion" {
    const testing = std.testing;

    const guid = Guid{
        .data1 = 0x12345678,
        .data2 = 0x1234,
        .data3 = 0x5678,
        .data4 = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8 },
    };

    const c_guid = guid.toC();
    const roundtrip = Guid.fromC(c_guid);

    try testing.expectEqual(guid.data1, roundtrip.data1);
    try testing.expectEqual(guid.data2, roundtrip.data2);
    try testing.expectEqual(guid.data3, roundtrip.data3);
    try testing.expectEqualSlices(u8, &guid.data4, &roundtrip.data4);
}
