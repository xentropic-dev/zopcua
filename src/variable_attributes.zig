const std = @import("std");
const c = @import("c.zig");
const AccessLevel = @import("access_level.zig").AccessLevel;
const LocalizedText = @import("localized_text.zig").LocalizedText;
const Variant = @import("variant.zig").Variant;
const NodeId = @import("types.zig").NodeId;

pub const VariableAttributes = struct {
    specified_attributes: u32 = 0,
    display_name: LocalizedText = .{},
    description: LocalizedText = .{},
    write_mask: u32 = 0,
    user_write_mask: u32 = 0,
    value: Variant = .empty,
    data_type: NodeId = .null_id,
    value_rank: i32 = -1,
    array_dimensions: []const u32 = &.{},
    access_level: AccessLevel = .{},
    user_access_level: AccessLevel = .{},
    minimum_sampling_interval: f64 = 0.0,
    historizing: bool = false,

    /// Convert to C API representation
    pub fn toC(self: VariableAttributes, allocator: std.mem.Allocator) !c.UA_VariableAttributes {
        var result = std.mem.zeroes(c.UA_VariableAttributes);
        result.specifiedAttributes = self.specified_attributes;
        result.displayName = self.display_name.toC();
        result.description = self.description.toC();
        result.writeMask = self.write_mask;
        result.userWriteMask = self.user_write_mask;
        result.value = try self.value.toC(allocator);
        result.valueRank = self.value_rank;
        result.accessLevel = self.access_level.toC();
        result.userAccessLevel = self.user_access_level.toC();
        result.minimumSamplingInterval = self.minimum_sampling_interval;
        result.historizing = self.historizing;

        // Auto-infer data_type from variant if not explicitly set
        const data_type = switch (self.data_type) {
            .numeric => |n| if (n.namespace == 0 and n.identifier == 0)
                self.value.dataTypeNodeId()
            else
                self.data_type,
            else => self.data_type,
        };
        result.dataType = data_type.toC();

        // Handle array dimensions
        if (self.array_dimensions.len > 0) {
            const dims = try allocator.alloc(c.UA_UInt32, self.array_dimensions.len);
            @memcpy(dims, self.array_dimensions);
            result.arrayDimensions = dims.ptr;
            result.arrayDimensionsSize = dims.len;
        }

        return result;
    }

    /// Convert from C API representation
    pub fn fromC(value: c.UA_VariableAttributes) VariableAttributes {
        return .{
            .specified_attributes = value.specifiedAttributes,
            .display_name = LocalizedText.fromC(value.displayName),
            .description = LocalizedText.fromC(value.description),
            .write_mask = value.writeMask,
            .user_write_mask = value.userWriteMask,
            .value = Variant.fromC(value.value),
            .data_type = NodeId.fromC(value.dataType),
            .value_rank = value.valueRank,
            .array_dimensions = if (value.arrayDimensionsSize > 0)
                value.arrayDimensions[0..value.arrayDimensionsSize]
            else
                &.{},
            .access_level = AccessLevel.fromC(value.accessLevel),
            .user_access_level = AccessLevel.fromC(value.userAccessLevel),
            .minimum_sampling_interval = value.minimumSamplingInterval,
            .historizing = value.historizing,
        };
    }
};

test "AccessLevel none" {
    const testing = std.testing;

    const access = AccessLevel.none;
    try testing.expectEqual(false, access.read);
    try testing.expectEqual(false, access.write);

    const c_access = access.toC();
    try testing.expectEqual(@as(u8, 0), c_access);
}

test "AccessLevel read_only" {
    const testing = std.testing;

    const access = AccessLevel.read_only;
    try testing.expectEqual(true, access.read);
    try testing.expectEqual(false, access.write);

    const c_access = access.toC();
    const roundtrip = AccessLevel.fromC(c_access);
    try testing.expectEqual(access.read, roundtrip.read);
    try testing.expectEqual(access.write, roundtrip.write);
}

test "AccessLevel read_write" {
    const testing = std.testing;

    const access = AccessLevel.read_write;
    try testing.expectEqual(true, access.read);
    try testing.expectEqual(true, access.write);

    const c_access = access.toC();
    const roundtrip = AccessLevel.fromC(c_access);
    try testing.expectEqual(access.read, roundtrip.read);
    try testing.expectEqual(access.write, roundtrip.write);
}

test "AccessLevel custom permissions" {
    const testing = std.testing;

    const access = AccessLevel{
        .read = true,
        .write = true,
        .history_read = true,
        .timestamp_write = true,
    };

    try testing.expectEqual(true, access.read);
    try testing.expectEqual(true, access.write);
    try testing.expectEqual(true, access.history_read);
    try testing.expectEqual(true, access.timestamp_write);
    try testing.expectEqual(false, access.semantic_change);

    const c_access = access.toC();
    const roundtrip = AccessLevel.fromC(c_access);
    try testing.expectEqual(access.read, roundtrip.read);
    try testing.expectEqual(access.write, roundtrip.write);
    try testing.expectEqual(access.history_read, roundtrip.history_read);
    try testing.expectEqual(access.timestamp_write, roundtrip.timestamp_write);
}

test "VariableAttributes default values" {
    const testing = std.testing;

    const attrs = VariableAttributes{};
    try testing.expectEqual(@as(u32, 0), attrs.specified_attributes);
    try testing.expectEqual(@as(i32, -1), attrs.value_rank);
    try testing.expectEqual(@as(f64, 0.0), attrs.minimum_sampling_interval);
    try testing.expectEqual(false, attrs.historizing);
}

test "VariableAttributes with values" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const attrs = VariableAttributes{
        .value = Variant.scalar(i32, 42),
        .display_name = LocalizedText.init("en-US", "Test Variable"),
        .description = LocalizedText.initText("A test variable"),
        .access_level = .{ .read = true, .write = true },
        .value_rank = -1,
    };

    try testing.expectEqual(@as(i32, 42), attrs.value.int32);
    try testing.expectEqualStrings("Test Variable", attrs.display_name.text);
    try testing.expectEqualStrings("A test variable", attrs.description.text);
    try testing.expectEqual(true, attrs.access_level.read);
    try testing.expectEqual(true, attrs.access_level.write);

    const c_attrs = try attrs.toC(allocator);
    defer {
        Variant.freeCVariant(c_attrs.value, allocator);
        if (c_attrs.arrayDimensionsSize > 0) {
            allocator.free(c_attrs.arrayDimensions[0..c_attrs.arrayDimensionsSize]);
        }
    }

    try testing.expectEqual(@as(i32, -1), c_attrs.valueRank);
}

test "VariableAttributes auto data type inference" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const attrs = VariableAttributes{
        .value = Variant.scalar(f64, 3.14),
        .display_name = LocalizedText.initText("Pi"),
    };

    const c_attrs = try attrs.toC(allocator);
    defer {
        Variant.freeCVariant(c_attrs.value, allocator);
    }

    // Data type should be auto-inferred to UA_TYPES_DOUBLE
    try testing.expect(c_attrs.dataType.namespaceIndex == 0);
}
