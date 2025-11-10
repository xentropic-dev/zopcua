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

const std = @import("std");

test "BrowseResultMask bitfield conversion roundtrip" {
    const testing = std.testing;
    std.testing.refAllDecls(@This());

    const mask = BrowseResultMask{
        .node_class = true,
        .browse_name = true,
        .display_name = true,
    };
    const c_mask = mask.toC();
    const back = BrowseResultMask.fromC(c_mask);

    try testing.expect(back.node_class);
    try testing.expect(back.browse_name);
    try testing.expect(back.display_name);
    try testing.expect(!back.reference_type_id);
}

test "BrowseResultMask all constant" {
    const testing = std.testing;

    const mask = BrowseResultMask.all;

    try testing.expect(mask.reference_type_id);
    try testing.expect(mask.is_forward);
    try testing.expect(mask.node_class);
    try testing.expect(mask.browse_name);
    try testing.expect(mask.display_name);
    try testing.expect(mask.type_definition);
}

test "BrowseResultMask none constant" {
    const testing = std.testing;

    const mask = BrowseResultMask.none;

    try testing.expect(!mask.reference_type_id);
    try testing.expect(!mask.is_forward);
    try testing.expect(!mask.node_class);
    try testing.expect(!mask.browse_name);
}

test "BrowseResultMask reference_type_info constant" {
    const testing = std.testing;

    const mask = BrowseResultMask.reference_type_info;

    try testing.expect(mask.reference_type_id);
    try testing.expect(mask.is_forward);
    try testing.expect(!mask.node_class);
    try testing.expect(!mask.browse_name);
}

test "BrowseResultMask target_info constant" {
    const testing = std.testing;

    const mask = BrowseResultMask.target_info;

    try testing.expect(!mask.reference_type_id);
    try testing.expect(!mask.is_forward);
    try testing.expect(mask.node_class);
    try testing.expect(mask.browse_name);
    try testing.expect(mask.display_name);
    try testing.expect(mask.type_definition);
}

test "BrowseResultMask all conversion preserves all bits" {
    const testing = std.testing;

    const original = BrowseResultMask.all;
    const c_mask = original.toC();
    const back = BrowseResultMask.fromC(c_mask);

    try testing.expect(back.reference_type_id == original.reference_type_id);
    try testing.expect(back.is_forward == original.is_forward);
    try testing.expect(back.node_class == original.node_class);
    try testing.expect(back.browse_name == original.browse_name);
    try testing.expect(back.display_name == original.display_name);
    try testing.expect(back.type_definition == original.type_definition);
}
