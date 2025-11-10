const c = @import("c.zig");

/// NodeClassMask allows filtering browse results by node class
/// Each field represents a specific node class that can be included in results
pub const NodeClassMask = packed struct(u32) {
    /// Include Object nodes (UA_NODECLASS_OBJECT = 1)
    object: bool = false,

    /// Include Variable nodes (UA_NODECLASS_VARIABLE = 2)
    variable: bool = false,

    /// Include Method nodes (UA_NODECLASS_METHOD = 4)
    method: bool = false,

    /// Include ObjectType nodes (UA_NODECLASS_OBJECTTYPE = 8)
    object_type: bool = false,

    /// Include VariableType nodes (UA_NODECLASS_VARIABLETYPE = 16)
    variable_type: bool = false,

    /// Include ReferenceType nodes (UA_NODECLASS_REFERENCETYPE = 32)
    reference_type: bool = false,

    /// Include DataType nodes (UA_NODECLASS_DATATYPE = 64)
    data_type: bool = false,

    /// Include View nodes (UA_NODECLASS_VIEW = 128)
    view: bool = false,

    _padding: u24 = 0,

    /// No filtering - include all node classes
    pub const all = NodeClassMask{
        .object = true,
        .variable = true,
        .method = true,
        .object_type = true,
        .variable_type = true,
        .reference_type = true,
        .data_type = true,
        .view = true,
    };

    /// No node classes (effectively filters out everything)
    pub const none = NodeClassMask{};

    /// Only Object nodes
    pub const objects_only = NodeClassMask{ .object = true };

    /// Only Variable nodes
    pub const variables_only = NodeClassMask{ .variable = true };

    /// Objects and Variables (most common use case)
    pub const objects_and_variables = NodeClassMask{
        .object = true,
        .variable = true,
    };

    /// Convert from C API representation
    pub inline fn fromC(value: c.UA_UInt32) NodeClassMask {
        return @bitCast(value);
    }

    /// Convert to C API representation
    pub inline fn toC(self: NodeClassMask) c.UA_UInt32 {
        return @bitCast(self);
    }
};

const std = @import("std");

test "NodeClassMask bitfield conversion roundtrip" {
    const testing = std.testing;
    std.testing.refAllDecls(@This());

    const mask = NodeClassMask{
        .object = true,
        .variable = true,
    };
    const c_mask = mask.toC();
    const back = NodeClassMask.fromC(c_mask);

    try testing.expect(back.object);
    try testing.expect(back.variable);
    try testing.expect(!back.method);
}

test "NodeClassMask all constant" {
    const testing = std.testing;

    const mask = NodeClassMask.all;

    try testing.expect(mask.object);
    try testing.expect(mask.variable);
    try testing.expect(mask.method);
    try testing.expect(mask.object_type);
    try testing.expect(mask.variable_type);
    try testing.expect(mask.reference_type);
    try testing.expect(mask.data_type);
    try testing.expect(mask.view);
}

test "NodeClassMask none constant" {
    const testing = std.testing;

    const mask = NodeClassMask.none;

    try testing.expect(!mask.object);
    try testing.expect(!mask.variable);
    try testing.expect(!mask.method);
}

test "NodeClassMask objects_only constant" {
    const testing = std.testing;

    const mask = NodeClassMask.objects_only;

    try testing.expect(mask.object);
    try testing.expect(!mask.variable);
    try testing.expect(!mask.method);
}

test "NodeClassMask variables_only constant" {
    const testing = std.testing;

    const mask = NodeClassMask.variables_only;

    try testing.expect(!mask.object);
    try testing.expect(mask.variable);
    try testing.expect(!mask.method);
}

test "NodeClassMask objects_and_variables constant" {
    const testing = std.testing;

    const mask = NodeClassMask.objects_and_variables;

    try testing.expect(mask.object);
    try testing.expect(mask.variable);
    try testing.expect(!mask.method);
    try testing.expect(!mask.object_type);
}

test "NodeClassMask all conversion preserves all bits" {
    const testing = std.testing;

    const original = NodeClassMask.all;
    const c_mask = original.toC();
    const back = NodeClassMask.fromC(c_mask);

    try testing.expect(back.object == original.object);
    try testing.expect(back.variable == original.variable);
    try testing.expect(back.method == original.method);
    try testing.expect(back.object_type == original.object_type);
    try testing.expect(back.variable_type == original.variable_type);
    try testing.expect(back.reference_type == original.reference_type);
    try testing.expect(back.data_type == original.data_type);
    try testing.expect(back.view == original.view);
}
