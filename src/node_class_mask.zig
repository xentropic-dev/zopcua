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
