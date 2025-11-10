const std = @import("std");
const c = @import("c.zig");
const types = @import("types.zig");
const LocalizedText = @import("localized_text.zig").LocalizedText;
pub const NodeClassMask = @import("node_class_mask.zig").NodeClassMask;
pub const BrowseResultMask = @import("browse_result_mask.zig").BrowseResultMask;

const NodeId = types.NodeId;
const ExpandedNodeId = types.ExpandedNodeId;
const QualifiedName = types.QualifiedName;
const BrowseDirection = types.BrowseDirection;
const NodeClass = types.NodeClass;

/// BrowseDescription defines the parameters for browsing nodes
pub const BrowseDescription = struct {
    /// The node to browse
    node_id: NodeId,
    /// The direction to follow references
    browse_direction: BrowseDirection = .forward,
    /// The type of references to follow (null_id = all types)
    reference_type_id: NodeId = NodeId.null_id,
    /// Whether to include subtypes of the reference type
    include_subtypes: bool = true,
    /// Mask of node classes to return (all = all classes)
    node_class_mask: NodeClassMask = .all,
    /// Mask of fields to return in ReferenceDescription (all = all fields)
    result_mask: BrowseResultMask = .all,

    /// Convert to C API representation
    pub fn toC(self: BrowseDescription, allocator: std.mem.Allocator) !c.UA_BrowseDescription {
        // SAFETY: result fields are all initialized below before returning
        var result: c.UA_BrowseDescription = undefined;

        result.nodeId = try self.node_id.toC(allocator);
        result.browseDirection = self.browse_direction.toC();
        result.referenceTypeId = try self.reference_type_id.toC(allocator);
        result.includeSubtypes = self.include_subtypes;
        result.nodeClassMask = self.node_class_mask.toC();
        result.resultMask = self.result_mask.toC();

        return result;
    }

    /// Free memory allocated by toC()
    pub fn freeToC(self: BrowseDescription, allocator: std.mem.Allocator, c_desc: c.UA_BrowseDescription) void {
        self.node_id.freeToC(allocator, c_desc.nodeId);
        self.reference_type_id.freeToC(allocator, c_desc.referenceTypeId);
    }
};

/// ReferenceDescription describes a reference from a browsed node
pub const ReferenceDescription = struct {
    /// The type of reference
    reference_type_id: NodeId,
    /// True if the reference is in the forward direction
    is_forward: bool,
    /// The target node
    node_id: ExpandedNodeId,
    /// The browse name of the target node
    browse_name: QualifiedName,
    /// The display name of the target node
    display_name: LocalizedText,
    /// The node class of the target node
    node_class: NodeClass,
    /// The type definition of the target node
    type_definition: ExpandedNodeId,

    /// Free all allocated memory
    pub fn deinit(self: *ReferenceDescription, allocator: std.mem.Allocator) void {
        // Free browse_name if it contains allocated memory
        if (self.browse_name.name.len > 0) {
            allocator.free(self.browse_name.name);
        }
        // Free display_name fields
        if (self.display_name.locale.len > 0) {
            allocator.free(self.display_name.locale);
        }
        if (self.display_name.text.len > 0) {
            allocator.free(self.display_name.text);
        }
        // Free node_id namespace_uri if present
        if (self.node_id.namespace_uri.len > 0) {
            allocator.free(self.node_id.namespace_uri);
        }
        // Free node_id.node_id string identifiers
        switch (self.node_id.node_id) {
            .string => |s| if (s.identifier.len > 0) allocator.free(s.identifier),
            .byte_string => |b| if (b.identifier.len > 0) allocator.free(b.identifier),
            else => {},
        }
        // Free reference_type_id string identifiers
        switch (self.reference_type_id) {
            .string => |s| if (s.identifier.len > 0) allocator.free(s.identifier),
            .byte_string => |b| if (b.identifier.len > 0) allocator.free(b.identifier),
            else => {},
        }
        // Free type_definition namespace_uri if present
        if (self.type_definition.namespace_uri.len > 0) {
            allocator.free(self.type_definition.namespace_uri);
        }
        // Free type_definition.node_id string identifiers
        switch (self.type_definition.node_id) {
            .string => |s| if (s.identifier.len > 0) allocator.free(s.identifier),
            .byte_string => |b| if (b.identifier.len > 0) allocator.free(b.identifier),
            else => {},
        }
    }

    /// Convert from C API representation (deep-copies all data)
    pub fn fromC(value: c.UA_ReferenceDescription, allocator: std.mem.Allocator) !ReferenceDescription {
        // Deep-copy browse name
        const browse_name_copy = try allocator.dupe(u8, QualifiedName.fromC(value.browseName).name);

        // Deep-copy display name
        const display_name_c = LocalizedText.fromC(value.displayName);
        const display_name = LocalizedText{
            .locale = if (display_name_c.locale.len > 0) try allocator.dupe(u8, display_name_c.locale) else "",
            .text = if (display_name_c.text.len > 0) try allocator.dupe(u8, display_name_c.text) else "",
        };

        // Deep-copy node_id with namespace URI
        var node_id = ExpandedNodeId.fromC(value.nodeId);
        if (node_id.namespace_uri.len > 0) {
            node_id.namespace_uri = try allocator.dupe(u8, node_id.namespace_uri);
        }
        // Deep-copy node_id identifier if string-based
        switch (node_id.node_id) {
            .string => |*s| {
                if (s.identifier.len > 0) {
                    s.identifier = try allocator.dupe(u8, s.identifier);
                }
            },
            .byte_string => |*b| {
                if (b.identifier.len > 0) {
                    b.identifier = try allocator.dupe(u8, b.identifier);
                }
            },
            else => {},
        }

        // Deep-copy reference_type_id
        var reference_type_id = NodeId.fromC(value.referenceTypeId);
        switch (reference_type_id) {
            .string => |*s| {
                if (s.identifier.len > 0) {
                    s.identifier = try allocator.dupe(u8, s.identifier);
                }
            },
            .byte_string => |*b| {
                if (b.identifier.len > 0) {
                    b.identifier = try allocator.dupe(u8, b.identifier);
                }
            },
            else => {},
        }

        // Deep-copy type_definition with namespace URI
        var type_definition = ExpandedNodeId.fromC(value.typeDefinition);
        if (type_definition.namespace_uri.len > 0) {
            type_definition.namespace_uri = try allocator.dupe(u8, type_definition.namespace_uri);
        }
        // Deep-copy type_definition identifier if string-based
        switch (type_definition.node_id) {
            .string => |*s| {
                if (s.identifier.len > 0) {
                    s.identifier = try allocator.dupe(u8, s.identifier);
                }
            },
            .byte_string => |*b| {
                if (b.identifier.len > 0) {
                    b.identifier = try allocator.dupe(u8, b.identifier);
                }
            },
            else => {},
        }

        return .{
            .reference_type_id = reference_type_id,
            .is_forward = value.isForward,
            .node_id = node_id,
            .browse_name = .{
                .namespace_index = value.browseName.namespaceIndex,
                .name = browse_name_copy,
            },
            .display_name = display_name,
            .node_class = NodeClass.fromC(value.nodeClass),
            .type_definition = type_definition,
        };
    }
};

/// BrowseResult contains the results from a browse operation
pub const BrowseResult = struct {
    /// Status code for the browse operation
    status_code: c.UA_StatusCode,
    /// Continuation point for retrieving more results (null if complete)
    continuation_point: ?[]const u8,
    /// Array of references found
    references: []ReferenceDescription,

    /// Free all allocated memory
    pub fn deinit(self: *BrowseResult, allocator: std.mem.Allocator) void {
        // Free continuation point
        if (self.continuation_point) |cp| {
            allocator.free(cp);
        }
        // Free each reference description
        for (self.references) |*ref| {
            ref.deinit(allocator);
        }
        // Free references array
        allocator.free(self.references);
    }

    /// Convert from C API representation (deep-copies all data)
    pub fn fromC(value: c.UA_BrowseResult, allocator: std.mem.Allocator) !BrowseResult {
        // Deep-copy continuation point if present
        var continuation_point: ?[]const u8 = null;
        if (value.continuationPoint.length > 0 and value.continuationPoint.data != null) {
            const cp_slice = value.continuationPoint.data[0..value.continuationPoint.length];
            continuation_point = try allocator.dupe(u8, cp_slice);
        }

        // Deep-copy references array
        const references = try allocator.alloc(ReferenceDescription, value.referencesSize);
        errdefer allocator.free(references);

        for (references, 0..) |*ref, i| {
            ref.* = try ReferenceDescription.fromC(value.references[i], allocator);
        }

        return .{
            .status_code = value.statusCode,
            .continuation_point = continuation_point,
            .references = references,
        };
    }
};

// ============================================================================
// Unit Tests
// ============================================================================

test "BrowseDescription default values" {
    const testing = std.testing;
    std.testing.refAllDecls(@This());

    const node_id = NodeId.initNumeric(0, 85); // Objects folder
    const desc = BrowseDescription{
        .node_id = node_id,
    };

    try testing.expectEqual(BrowseDirection.forward, desc.browse_direction);
    try testing.expect(desc.include_subtypes);
    try testing.expectEqual(NodeClassMask.all, desc.node_class_mask);
    try testing.expectEqual(BrowseResultMask.all, desc.result_mask);
}

test "BrowseDescription toC/freeToC" {
    const testing = std.testing;

    const node_id = NodeId.initNumeric(1, 42);
    const ref_type = NodeId.initNumeric(0, c.UA_NS0ID_ORGANIZES);

    const desc = BrowseDescription{
        .node_id = node_id,
        .browse_direction = .both,
        .reference_type_id = ref_type,
        .include_subtypes = false,
        .node_class_mask = .variables_only,
        .result_mask = .{
            .reference_type_id = true,
            .is_forward = true,
            .node_class = true,
            .browse_name = true,
            .display_name = true,
        },
    };

    const c_desc = try desc.toC(testing.allocator);
    defer desc.freeToC(testing.allocator, c_desc);

    try testing.expectEqual(@as(u32, c.UA_BROWSEDIRECTION_BOTH), c_desc.browseDirection);
    try testing.expectEqual(false, c_desc.includeSubtypes);
    try testing.expectEqual(@as(u32, c.UA_NODECLASS_VARIABLE), c_desc.nodeClassMask);
    try testing.expectEqual(@as(u32, 0x1F), c_desc.resultMask);
}

test "ReferenceDescription fromC and deinit" {
    const testing = std.testing;

    // Create a C ReferenceDescription
    var c_ref: c.UA_ReferenceDescription = undefined;
    c.UA_ReferenceDescription_init(&c_ref);

    c_ref.referenceTypeId = c.UA_NODEID_NUMERIC(0, c.UA_NS0ID_ORGANIZES);
    c_ref.isForward = true;
    c_ref.nodeId.nodeId = c.UA_NODEID_NUMERIC(1, 100);
    c_ref.nodeId.serverIndex = 0;
    c_ref.nodeId.namespaceUri = .{ .length = 0, .data = null };
    c_ref.browseName = c.UA_QUALIFIEDNAME(1, @ptrCast(@constCast("TestNode")));
    c_ref.displayName = c.UA_LOCALIZEDTEXT(@ptrCast(@constCast("en")), @ptrCast(@constCast("Test Node")));
    c_ref.nodeClass = c.UA_NODECLASS_VARIABLE;
    c_ref.typeDefinition.nodeId = c.UA_NODEID_NUMERIC(0, c.UA_NS0ID_BASEDATAVARIABLETYPE);
    c_ref.typeDefinition.serverIndex = 0;
    c_ref.typeDefinition.namespaceUri = .{ .length = 0, .data = null };

    var ref = try ReferenceDescription.fromC(c_ref, testing.allocator);
    defer ref.deinit(testing.allocator);

    try testing.expectEqual(true, ref.is_forward);
    try testing.expectEqual(NodeClass.variable, ref.node_class);
    try testing.expectEqualStrings("TestNode", ref.browse_name.name);
}

test "BrowseResult fromC and deinit with empty results" {
    const testing = std.testing;

    // Create a C BrowseResult with no references
    var c_result: c.UA_BrowseResult = undefined;
    c.UA_BrowseResult_init(&c_result);

    c_result.statusCode = c.UA_STATUSCODE_GOOD;
    c_result.continuationPoint = .{ .length = 0, .data = null };
    c_result.referencesSize = 0;
    c_result.references = null;

    var result = try BrowseResult.fromC(c_result, testing.allocator);
    defer result.deinit(testing.allocator);

    try testing.expectEqual(@as(c.UA_StatusCode, c.UA_STATUSCODE_GOOD), result.status_code);
    try testing.expectEqual(@as(?[]const u8, null), result.continuation_point);
    try testing.expectEqual(@as(usize, 0), result.references.len);
}

test "BrowseResult fromC with continuation point" {
    const testing = std.testing;

    // Create a C BrowseResult with a continuation point
    var c_result: c.UA_BrowseResult = undefined;
    c.UA_BrowseResult_init(&c_result);

    c_result.statusCode = c.UA_STATUSCODE_GOOD;
    const cp_data = "continuation123";
    c_result.continuationPoint.length = cp_data.len;
    c_result.continuationPoint.data = @ptrCast(@constCast(cp_data.ptr));
    c_result.referencesSize = 0;
    c_result.references = null;

    var result = try BrowseResult.fromC(c_result, testing.allocator);
    defer result.deinit(testing.allocator);

    try testing.expectEqual(@as(c.UA_StatusCode, c.UA_STATUSCODE_GOOD), result.status_code);
    try testing.expect(result.continuation_point != null);
    try testing.expectEqualStrings(cp_data, result.continuation_point.?);
}
