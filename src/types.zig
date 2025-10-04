pub const c = @import("c.zig");

pub const StatusCode = c.UA_StatusCode;
pub const STATUSCODE_GOOD = c.UA_STATUSCODE_GOOD;

pub const NodeId = struct {
    namespace: u16,
    identifier: u32,
    
    pub fn numeric(ns: u16, id: u32) NodeId {
        return .{ .namespace = ns, .identifier = id };
    }
    
    pub fn toC(self: NodeId) c.UA_NodeId {
        return c.UA_NODEID_NUMERIC(self.namespace, self.identifier);
    }
};

pub const DataType = enum {
    string,
    int64,
    int32,
    float,
    double,
    boolean,
};

pub const Value = union(DataType) {
    string: []const u8,
    int64: i64,
    int32: i32,
    float: f32,
    double: f64,
    boolean: bool,
};
