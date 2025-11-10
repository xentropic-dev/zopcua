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
    /// For string/bytestring variants, allocates temporary null-terminated strings.
    /// Caller must call freeToC() with the same allocator to clean up.
    pub fn toC(self: NodeId, allocator: std.mem.Allocator) !c.UA_NodeId {
        return switch (self) {
            .numeric => |n| c.UA_NODEID_NUMERIC(n.namespace, n.identifier),
            .string => |s| blk: {
                const buf = try allocator.alloc(u8, s.identifier.len + 1);
                const null_terminated = try std.fmt.bufPrintZ(buf, "{s}", .{s.identifier});
                break :blk c.UA_NODEID_STRING(s.namespace, @constCast(null_terminated.ptr));
            },
            .guid => |g| c.UA_NODEID_GUID(g.namespace, g.identifier.toC()),
            .byte_string => |b| blk: {
                const buf = try allocator.alloc(u8, b.identifier.len + 1);
                const null_terminated = try std.fmt.bufPrintZ(buf, "{s}", .{b.identifier});
                break :blk c.UA_NODEID_BYTESTRING(b.namespace, @constCast(null_terminated.ptr));
            },
        };
    }

    /// Free memory allocated by toC() for string/bytestring NodeIds
    pub fn freeToC(self: NodeId, c_node_id: c.UA_NodeId, allocator: std.mem.Allocator) void {
        switch (self) {
            .string, .byte_string => {
                if (c_node_id.identifier.string.data) |data| {
                    const len = c_node_id.identifier.string.length;
                    allocator.free(data[0 .. len + 1]); // +1 for null terminator
                }
            },
            .numeric, .guid => {}, // No cleanup needed
        }
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

    /// Convert to C API representation
    /// Allocates temporary null-terminated string.
    /// Caller must call freeToC() with the same allocator to clean up.
    pub fn toC(self: QualifiedName, allocator: std.mem.Allocator) !c.UA_QualifiedName {
        const buf = try allocator.alloc(u8, self.name.len + 1);
        const null_terminated = try std.fmt.bufPrintZ(buf, "{s}", .{self.name});
        return c.UA_QUALIFIEDNAME(self.namespace_index, @constCast(null_terminated.ptr));
    }

    /// Free memory allocated by toC()
    pub fn freeToC(self: QualifiedName, c_qname: c.UA_QualifiedName, allocator: std.mem.Allocator) void {
        _ = self;
        if (c_qname.name.data) |data| {
            const len = c_qname.name.length;
            allocator.free(data[0 .. len + 1]); // +1 for null terminator
        }
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

/// BrowseDirection specifies the direction of references to follow
pub const BrowseDirection = enum(u32) {
    /// Follow references in the forward direction
    forward = c.UA_BROWSEDIRECTION_FORWARD,
    /// Follow references in the inverse direction
    inverse = c.UA_BROWSEDIRECTION_INVERSE,
    /// Follow references in both directions
    both = c.UA_BROWSEDIRECTION_BOTH,

    pub fn toC(self: BrowseDirection) c.UA_BrowseDirection {
        return @intFromEnum(self);
    }

    pub fn fromC(value: c.UA_BrowseDirection) BrowseDirection {
        return switch (value) {
            c.UA_BROWSEDIRECTION_FORWARD => .forward,
            c.UA_BROWSEDIRECTION_INVERSE => .inverse,
            c.UA_BROWSEDIRECTION_BOTH => .both,
            else => .forward, // Default to forward for invalid values
        };
    }
};

/// NodeClass represents the class of a node in the OPC UA address space
pub const NodeClass = enum(u32) {
    unspecified = 0,
    object = c.UA_NODECLASS_OBJECT,
    variable = c.UA_NODECLASS_VARIABLE,
    method = c.UA_NODECLASS_METHOD,
    object_type = c.UA_NODECLASS_OBJECTTYPE,
    variable_type = c.UA_NODECLASS_VARIABLETYPE,
    reference_type = c.UA_NODECLASS_REFERENCETYPE,
    data_type = c.UA_NODECLASS_DATATYPE,
    view = c.UA_NODECLASS_VIEW,

    pub fn toC(self: NodeClass) c.UA_NodeClass {
        return @intFromEnum(self);
    }

    pub fn fromC(value: c.UA_NodeClass) NodeClass {
        return switch (value) {
            c.UA_NODECLASS_OBJECT => .object,
            c.UA_NODECLASS_VARIABLE => .variable,
            c.UA_NODECLASS_METHOD => .method,
            c.UA_NODECLASS_OBJECTTYPE => .object_type,
            c.UA_NODECLASS_VARIABLETYPE => .variable_type,
            c.UA_NODECLASS_REFERENCETYPE => .reference_type,
            c.UA_NODECLASS_DATATYPE => .data_type,
            c.UA_NODECLASS_VIEW => .view,
            else => .unspecified,
        };
    }
};

/// ExpandedNodeId extends NodeId to include server index and namespace URI
/// Used for nodes that may exist on different servers or namespaces
pub const ExpandedNodeId = struct {
    node_id: NodeId,
    namespace_uri: []const u8 = "",
    server_index: u32 = 0,

    /// Create an ExpandedNodeId from a regular NodeId
    pub fn fromNodeId(node_id: NodeId) ExpandedNodeId {
        return .{ .node_id = node_id };
    }

    /// Convert from C API representation
    /// Note: The returned slices reference memory owned by the C struct.
    /// The caller must deep-copy if the data needs to outlive the C struct.
    pub fn fromC(value: c.UA_ExpandedNodeId) ExpandedNodeId {
        return .{
            .node_id = NodeId.fromC(value.nodeId),
            .namespace_uri = String.fromC(value.namespaceUri),
            .server_index = value.serverIndex,
        };
    }

    /// Convert to C API representation
    /// For namespace_uri, allocates temporary null-terminated string.
    /// Caller must call freeToC() with the same allocator to clean up.
    pub fn toC(self: ExpandedNodeId, allocator: std.mem.Allocator) !c.UA_ExpandedNodeId {
        // SAFETY: result fields are all initialized below before returning
        var result: c.UA_ExpandedNodeId = undefined;
        result.nodeId = try self.node_id.toC(allocator);
        result.serverIndex = self.server_index;

        if (self.namespace_uri.len > 0) {
            const buf = try allocator.alloc(u8, self.namespace_uri.len + 1);
            const null_terminated = try std.fmt.bufPrintZ(buf, "{s}", .{self.namespace_uri});
            result.namespaceUri.length = @intCast(self.namespace_uri.len);
            result.namespaceUri.data = @constCast(null_terminated.ptr);
        } else {
            result.namespaceUri.length = 0;
            result.namespaceUri.data = null;
        }

        return result;
    }

    /// Free memory allocated by toC()
    pub fn freeToC(self: ExpandedNodeId, c_expanded_node_id: c.UA_ExpandedNodeId, allocator: std.mem.Allocator) void {
        self.node_id.freeToC(c_expanded_node_id.nodeId, allocator);
        if (c_expanded_node_id.namespaceUri.data) |data| {
            const len = c_expanded_node_id.namespaceUri.length;
            allocator.free(data[0 .. len + 1]); // +1 for null terminator
        }
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

    const c_node_id = try node_id.toC(testing.allocator);
    defer node_id.freeToC(c_node_id, testing.allocator);
    const roundtrip = NodeId.fromC(c_node_id);
    try testing.expectEqual(node_id.numeric.namespace, roundtrip.numeric.namespace);
    try testing.expectEqual(node_id.numeric.identifier, roundtrip.numeric.identifier);
}

test "NodeId string creation and conversion" {
    const testing = std.testing;

    const node_id = NodeId.initString(2, "test.node");
    try testing.expectEqual(@as(u16, 2), node_id.string.namespace);
    try testing.expectEqualStrings("test.node", node_id.string.identifier);

    const c_node_id = try node_id.toC(testing.allocator);
    defer node_id.freeToC(c_node_id, testing.allocator);
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

    const c_qname = try qname.toC(testing.allocator);
    defer qname.freeToC(c_qname, testing.allocator);
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

test "BrowseDirection enum values" {
    const testing = std.testing;

    // Test enum values match C constants
    try testing.expectEqual(@as(u32, c.UA_BROWSEDIRECTION_FORWARD), @intFromEnum(BrowseDirection.forward));
    try testing.expectEqual(@as(u32, c.UA_BROWSEDIRECTION_INVERSE), @intFromEnum(BrowseDirection.inverse));
    try testing.expectEqual(@as(u32, c.UA_BROWSEDIRECTION_BOTH), @intFromEnum(BrowseDirection.both));
}

test "BrowseDirection conversion" {
    const testing = std.testing;

    // Test toC/fromC round-trip
    const directions = [_]BrowseDirection{ .forward, .inverse, .both };
    for (directions) |dir| {
        const c_dir = dir.toC();
        const roundtrip = BrowseDirection.fromC(c_dir);
        try testing.expectEqual(dir, roundtrip);
    }

    // Test fromC with invalid value defaults to forward
    const invalid_roundtrip = BrowseDirection.fromC(999);
    try testing.expectEqual(BrowseDirection.forward, invalid_roundtrip);
}

test "NodeClass enum values" {
    const testing = std.testing;

    // Test enum values match C constants
    try testing.expectEqual(@as(u32, c.UA_NODECLASS_OBJECT), @intFromEnum(NodeClass.object));
    try testing.expectEqual(@as(u32, c.UA_NODECLASS_VARIABLE), @intFromEnum(NodeClass.variable));
    try testing.expectEqual(@as(u32, c.UA_NODECLASS_METHOD), @intFromEnum(NodeClass.method));
}

test "NodeClass conversion" {
    const testing = std.testing;

    // Test toC/fromC round-trip
    const classes = [_]NodeClass{ .object, .variable, .method, .object_type, .variable_type };
    for (classes) |node_class| {
        const c_class = node_class.toC();
        const roundtrip = NodeClass.fromC(c_class);
        try testing.expectEqual(node_class, roundtrip);
    }

    // Test fromC with invalid value defaults to unspecified
    const invalid_roundtrip = NodeClass.fromC(999);
    try testing.expectEqual(NodeClass.unspecified, invalid_roundtrip);
}

test "ExpandedNodeId creation from NodeId" {
    const testing = std.testing;

    const node_id = NodeId.initNumeric(1, 42);
    const expanded = ExpandedNodeId.fromNodeId(node_id);

    try testing.expectEqual(@as(u16, 1), expanded.node_id.numeric.namespace);
    try testing.expectEqual(@as(u32, 42), expanded.node_id.numeric.identifier);
    try testing.expectEqual(@as(u32, 0), expanded.server_index);
    try testing.expectEqualStrings("", expanded.namespace_uri);
}

test "ExpandedNodeId conversion without namespace URI" {
    const testing = std.testing;

    const node_id = NodeId.initNumeric(2, 100);
    const expanded = ExpandedNodeId{
        .node_id = node_id,
        .server_index = 5,
    };

    const c_expanded = try expanded.toC(testing.allocator);
    defer expanded.freeToC(c_expanded, testing.allocator);

    try testing.expectEqual(@as(u32, 5), c_expanded.serverIndex);
    try testing.expectEqual(@as(usize, 0), c_expanded.namespaceUri.length);

    const roundtrip = ExpandedNodeId.fromC(c_expanded);
    try testing.expectEqual(expanded.server_index, roundtrip.server_index);
    try testing.expectEqual(expanded.node_id.numeric.namespace, roundtrip.node_id.numeric.namespace);
    try testing.expectEqual(expanded.node_id.numeric.identifier, roundtrip.node_id.numeric.identifier);
}

test "ExpandedNodeId conversion with namespace URI" {
    const testing = std.testing;

    const node_id = NodeId.initString(3, "test.node");
    const expanded = ExpandedNodeId{
        .node_id = node_id,
        .namespace_uri = "http://example.com/namespace",
        .server_index = 10,
    };

    const c_expanded = try expanded.toC(testing.allocator);
    defer expanded.freeToC(c_expanded, testing.allocator);

    try testing.expectEqual(@as(u32, 10), c_expanded.serverIndex);
    try testing.expect(c_expanded.namespaceUri.length > 0);

    const roundtrip = ExpandedNodeId.fromC(c_expanded);
    try testing.expectEqual(expanded.server_index, roundtrip.server_index);
    try testing.expectEqualStrings(expanded.namespace_uri, roundtrip.namespace_uri);
    try testing.expectEqualStrings(expanded.node_id.string.identifier, roundtrip.node_id.string.identifier);
}
