pub const c = @import("c.zig");
pub const String = @import("localized_text.zig").String;

pub const StatusCode = c.UA_StatusCode;
pub const STATUSCODE_GOOD = c.UA_STATUSCODE_GOOD;

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
