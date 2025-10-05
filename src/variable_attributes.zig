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
        result.dataType = self.data_type.toC();
        result.valueRank = self.value_rank;
        result.accessLevel = self.access_level.toC();
        result.userAccessLevel = self.user_access_level.toC();
        result.minimumSamplingInterval = self.minimum_sampling_interval;
        result.historizing = self.historizing;

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
