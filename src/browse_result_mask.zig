const c = @import("c.zig");

/// BrowseResultMask controls which fields are returned in ReferenceDescription
/// Each field represents a specific piece of information that can be included
pub const BrowseResultMask = packed struct(u32) {
    /// Include ReferenceTypeId (UA_BROWSERESULTMASK_REFERENCETYPEID = 1)
    reference_type_id: bool = false,

    /// Include IsForward flag (UA_BROWSERESULTMASK_ISFORWARD = 2)
    is_forward: bool = false,

    /// Include NodeClass (UA_BROWSERESULTMASK_NODECLASS = 4)
    node_class: bool = false,

    /// Include BrowseName (UA_BROWSERESULTMASK_BROWSENAME = 8)
    browse_name: bool = false,

    /// Include DisplayName (UA_BROWSERESULTMASK_DISPLAYNAME = 16)
    display_name: bool = false,

    /// Include TypeDefinition (UA_BROWSERESULTMASK_TYPEDEFINITION = 32)
    type_definition: bool = false,

    _padding: u26 = 0,

    /// All fields (UA_BROWSERESULTMASK_ALL = 63 = 0x3F)
    pub const all = BrowseResultMask{
        .reference_type_id = true,
        .is_forward = true,
        .node_class = true,
        .browse_name = true,
        .display_name = true,
        .type_definition = true,
    };

    /// No fields
    pub const none = BrowseResultMask{};

    /// Reference type information only (UA_BROWSERESULTMASK_REFERENCETYPEINFO = 3)
    pub const reference_type_info = BrowseResultMask{
        .reference_type_id = true,
        .is_forward = true,
    };

    /// Target node information only (UA_BROWSERESULTMASK_TARGETINFO = 60)
    pub const target_info = BrowseResultMask{
        .node_class = true,
        .browse_name = true,
        .display_name = true,
        .type_definition = true,
    };

    /// Convert from C API representation
    pub inline fn fromC(value: c.UA_UInt32) BrowseResultMask {
        return @bitCast(value);
    }

    /// Convert to C API representation
    pub inline fn toC(self: BrowseResultMask) c.UA_UInt32 {
        return @bitCast(self);
    }
};
