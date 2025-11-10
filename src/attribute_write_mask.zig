const c = @import("c.zig");

/// AttributeWriteMask controls which attributes can be written to a node
/// Each field represents a specific attribute that can be modified
pub const AttributeWriteMask = packed struct(u32) {
    /// AccessLevel attribute (UA_ATTRIBUTEWRITEMASK_ACCESSLEVEL = 1)
    access_level: bool = false,

    /// ArrayDimensions attribute (UA_ATTRIBUTEWRITEMASK_ARRAYDIMENSIONS = 2)
    array_dimensions: bool = false,

    /// BrowseName attribute (UA_ATTRIBUTEWRITEMASK_BROWSENAME = 4)
    browse_name: bool = false,

    /// ContainsNoLoops attribute (UA_ATTRIBUTEWRITEMASK_CONTAINSNOLOOPS = 8)
    contains_no_loops: bool = false,

    /// DataType attribute (UA_ATTRIBUTEWRITEMASK_DATATYPE = 16)
    data_type: bool = false,

    /// Description attribute (UA_ATTRIBUTEWRITEMASK_DESCRIPTION = 32)
    description: bool = false,

    /// DisplayName attribute (UA_ATTRIBUTEWRITEMASK_DISPLAYNAME = 64)
    display_name: bool = false,

    /// EventNotifier attribute (UA_ATTRIBUTEWRITEMASK_EVENTNOTIFIER = 128)
    event_notifier: bool = false,

    /// Executable attribute (UA_ATTRIBUTEWRITEMASK_EXECUTABLE = 256)
    executable: bool = false,

    /// Historizing attribute (UA_ATTRIBUTEWRITEMASK_HISTORIZING = 512)
    historizing: bool = false,

    /// InverseName attribute (UA_ATTRIBUTEWRITEMASK_INVERSENAME = 1024)
    inverse_name: bool = false,

    /// IsAbstract attribute (UA_ATTRIBUTEWRITEMASK_ISABSTRACT = 2048)
    is_abstract: bool = false,

    /// MinimumSamplingInterval attribute (UA_ATTRIBUTEWRITEMASK_MINIMUMSAMPLINGINTERVAL = 4096)
    minimum_sampling_interval: bool = false,

    /// NodeClass attribute (UA_ATTRIBUTEWRITEMASK_NODECLASS = 8192)
    node_class: bool = false,

    /// NodeId attribute (UA_ATTRIBUTEWRITEMASK_NODEID = 16384)
    node_id: bool = false,

    /// Symmetric attribute (UA_ATTRIBUTEWRITEMASK_SYMMETRIC = 32768)
    symmetric: bool = false,

    /// UserAccessLevel attribute (UA_ATTRIBUTEWRITEMASK_USERACCESSLEVEL = 65536)
    user_access_level: bool = false,

    /// UserExecutable attribute (UA_ATTRIBUTEWRITEMASK_USEREXECUTABLE = 131072)
    user_executable: bool = false,

    /// UserWriteMask attribute (UA_ATTRIBUTEWRITEMASK_USERWRITEMASK = 262144)
    user_write_mask: bool = false,

    /// ValueRank attribute (UA_ATTRIBUTEWRITEMASK_VALUERANK = 524288)
    value_rank: bool = false,

    /// WriteMask attribute (UA_ATTRIBUTEWRITEMASK_WRITEMASK = 1048576)
    write_mask: bool = false,

    /// ValueForVariableType attribute (UA_ATTRIBUTEWRITEMASK_VALUEFORVARIABLETYPE = 2097152)
    value_for_variable_type: bool = false,

    _padding: u10 = 0,

    /// No write permissions
    pub const none = AttributeWriteMask{};

    /// All attributes writable
    pub const all = AttributeWriteMask{
        .access_level = true,
        .array_dimensions = true,
        .browse_name = true,
        .contains_no_loops = true,
        .data_type = true,
        .description = true,
        .display_name = true,
        .event_notifier = true,
        .executable = true,
        .historizing = true,
        .inverse_name = true,
        .is_abstract = true,
        .minimum_sampling_interval = true,
        .node_class = true,
        .node_id = true,
        .symmetric = true,
        .user_access_level = true,
        .user_executable = true,
        .user_write_mask = true,
        .value_rank = true,
        .write_mask = true,
        .value_for_variable_type = true,
    };

    /// Convert from C API representation
    pub inline fn fromC(value: c.UA_UInt32) AttributeWriteMask {
        return @bitCast(value);
    }

    /// Convert to C API representation
    pub inline fn toC(self: AttributeWriteMask) c.UA_UInt32 {
        return @bitCast(self);
    }
};
