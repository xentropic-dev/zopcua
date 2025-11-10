const std = @import("std");
const ua = @import("ua");

/// Assert that two Variants are equal
pub fn expectVariantEqual(expected: ua.Variant, actual: ua.Variant) !void {
    const tag_expected = @tagName(expected);
    const tag_actual = @tagName(actual);

    if (!std.mem.eql(u8, tag_expected, tag_actual)) {
        std.debug.print("Variant types don't match: expected {s}, got {s}\n", .{ tag_expected, tag_actual });
        return error.TestExpectedEqual;
    }

    switch (expected) {
        .empty => {},
        .boolean => |exp| try std.testing.expectEqual(exp, actual.boolean),
        .sbyte => |exp| try std.testing.expectEqual(exp, actual.sbyte),
        .byte => |exp| try std.testing.expectEqual(exp, actual.byte),
        .int16 => |exp| try std.testing.expectEqual(exp, actual.int16),
        .uint16 => |exp| try std.testing.expectEqual(exp, actual.uint16),
        .int32 => |exp| try std.testing.expectEqual(exp, actual.int32),
        .uint32 => |exp| try std.testing.expectEqual(exp, actual.uint32),
        .int64 => |exp| try std.testing.expectEqual(exp, actual.int64),
        .uint64 => |exp| try std.testing.expectEqual(exp, actual.uint64),
        .float => |exp| try std.testing.expectApproxEqRel(exp, actual.float, 0.0001),
        .double => |exp| try std.testing.expectApproxEqRel(exp, actual.double, 0.000001),
        .string => |exp| try std.testing.expectEqualStrings(exp, actual.string),
        .date_time => |exp| try std.testing.expectEqual(exp, actual.date_time),
        .guid => |exp| {
            try std.testing.expectEqual(exp.data1, actual.guid.data1);
            try std.testing.expectEqual(exp.data2, actual.guid.data2);
            try std.testing.expectEqual(exp.data3, actual.guid.data3);
            try std.testing.expectEqualSlices(u8, &exp.data4, &actual.guid.data4);
        },
        .byte_string => |exp| try std.testing.expectEqualSlices(u8, exp, actual.byte_string),
        .node_id => |exp| try expectNodeIdEqual(exp, actual.node_id),
        .status_code => |exp| try std.testing.expectEqual(exp, actual.status_code),
        .localized_text => |exp| {
            try std.testing.expectEqualStrings(exp.locale, actual.localized_text.locale);
            try std.testing.expectEqualStrings(exp.text, actual.localized_text.text);
        },

        // Arrays
        .boolean_array => |exp| try std.testing.expectEqualSlices(bool, exp, actual.boolean_array),
        .sbyte_array => |exp| try std.testing.expectEqualSlices(i8, exp, actual.sbyte_array),
        .byte_array => |exp| try std.testing.expectEqualSlices(u8, exp, actual.byte_array),
        .int16_array => |exp| try std.testing.expectEqualSlices(i16, exp, actual.int16_array),
        .uint16_array => |exp| try std.testing.expectEqualSlices(u16, exp, actual.uint16_array),
        .int32_array => |exp| try std.testing.expectEqualSlices(i32, exp, actual.int32_array),
        .uint32_array => |exp| try std.testing.expectEqualSlices(u32, exp, actual.uint32_array),
        .int64_array => |exp| try std.testing.expectEqualSlices(i64, exp, actual.int64_array),
        .uint64_array => |exp| try std.testing.expectEqualSlices(u64, exp, actual.uint64_array),
        .float_array => |exp| try expectFloatArrayEqual(exp, actual.float_array),
        .double_array => |exp| try expectDoubleArrayEqual(exp, actual.double_array),
        .string_array => |exp| try expectStringArrayEqual(exp, actual.string_array),
        .date_time_array => |exp| try std.testing.expectEqualSlices(i64, exp, actual.date_time_array),
        .node_id_array => |exp| try expectNodeIdArrayEqual(exp, actual.node_id_array),
        .status_code_array => |exp| try std.testing.expectEqualSlices(u32, exp, actual.status_code_array),

        .raw => return error.CannotCompareRawVariants,
    }
}

/// Assert that two NodeIds are equal
pub fn expectNodeIdEqual(expected: ua.NodeId, actual: ua.NodeId) !void {
    const tag_expected = @tagName(expected);
    const tag_actual = @tagName(actual);

    if (!std.mem.eql(u8, tag_expected, tag_actual)) {
        std.debug.print("NodeId types don't match: expected {s}, got {s}\n", .{ tag_expected, tag_actual });
        return error.TestExpectedEqual;
    }

    switch (expected) {
        .numeric => |exp| {
            try std.testing.expectEqual(exp.namespace, actual.numeric.namespace);
            try std.testing.expectEqual(exp.identifier, actual.numeric.identifier);
        },
        .string => |exp| {
            try std.testing.expectEqual(exp.namespace, actual.string.namespace);
            try std.testing.expectEqualStrings(exp.identifier, actual.string.identifier);
        },
        .guid => |exp| {
            try std.testing.expectEqual(exp.namespace, actual.guid.namespace);
            try std.testing.expectEqual(exp.identifier.data1, actual.guid.identifier.data1);
            try std.testing.expectEqual(exp.identifier.data2, actual.guid.identifier.data2);
            try std.testing.expectEqual(exp.identifier.data3, actual.guid.identifier.data3);
            try std.testing.expectEqualSlices(u8, &exp.identifier.data4, &actual.guid.identifier.data4);
        },
        .byte_string => |exp| {
            try std.testing.expectEqual(exp.namespace, actual.byte_string.namespace);
            try std.testing.expectEqualSlices(u8, exp.identifier, actual.byte_string.identifier);
        },
    }
}

/// Assert that a node exists by attempting to read it
pub fn expectNodeExists(client: *ua.Client, node_id: ua.NodeId, allocator: std.mem.Allocator) !void {
    const variant = client.readValueAttribute(allocator, node_id) catch |err| {
        std.debug.print("Node does not exist or cannot be read: {}\n", .{err});
        return error.NodeDoesNotExist;
    };
    defer variant.deinit(allocator);
}

/// Assert that reading a node returns a specific error
pub fn expectReadError(
    client: *ua.Client,
    node_id: ua.NodeId,
    expected_error: ua.client.ReadAttributeError,
    allocator: std.mem.Allocator,
) !void {
    const result = client.readValueAttribute(allocator, node_id);
    if (result) |variant| {
        variant.deinit(allocator);
        std.debug.print("Expected error {}, but read succeeded\n", .{expected_error});
        return error.TestUnexpectedResult;
    } else |err| {
        try std.testing.expectEqual(expected_error, err);
    }
}

/// Assert that writing a value returns a specific error
pub fn expectWriteError(
    client: *ua.Client,
    node_id: ua.NodeId,
    value: ua.Variant,
    expected_error: ua.client.WriteAttributeError,
) !void {
    const result = client.writeValueAttribute(node_id, value);
    if (result) {
        std.debug.print("Expected error {}, but write succeeded\n", .{expected_error});
        return error.TestUnexpectedResult;
    } else |err| {
        try std.testing.expectEqual(expected_error, err);
    }
}

/// Helper to compare float arrays with tolerance
fn expectFloatArrayEqual(expected: []const f32, actual: []const f32) !void {
    try std.testing.expectEqual(expected.len, actual.len);
    for (expected, actual) |exp, act| {
        try std.testing.expectApproxEqRel(exp, act, 0.0001);
    }
}

/// Helper to compare double arrays with tolerance
fn expectDoubleArrayEqual(expected: []const f64, actual: []const f64) !void {
    try std.testing.expectEqual(expected.len, actual.len);
    for (expected, actual) |exp, act| {
        try std.testing.expectApproxEqRel(exp, act, 0.000001);
    }
}

/// Helper to compare string arrays
fn expectStringArrayEqual(expected: []const []const u8, actual: []const []const u8) !void {
    try std.testing.expectEqual(expected.len, actual.len);
    for (expected, actual) |exp, act| {
        try std.testing.expectEqualStrings(exp, act);
    }
}

/// Helper to compare NodeId arrays
fn expectNodeIdArrayEqual(expected: []const ua.NodeId, actual: []const ua.NodeId) !void {
    try std.testing.expectEqual(expected.len, actual.len);
    for (expected, actual) |exp, act| {
        try expectNodeIdEqual(exp, act);
    }
}
