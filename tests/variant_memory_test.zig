const std = @import("std");
const testing = std.testing;
const ua = @import("ua");

// Test that scalar variants with heap allocations are properly freed
test "Variant memory: String scalar lifecycle" {
    const allocator = testing.allocator;

    // Create a string variant from allocated data
    const test_string = try allocator.dupe(u8, "Test String Value");
    defer allocator.free(test_string);

    // Create a C variant and convert it
    const c_variant = try ua.Variant.scalar([]const u8, test_string).toC(allocator);
    defer ua.Variant.freeCVariant(c_variant, allocator);

    // Convert back from C
    const variant = try ua.Variant.fromC(c_variant, allocator);
    defer variant.deinit(allocator);

    // Verify the data is correct
    try testing.expectEqualStrings("Test String Value", variant.string);
}

test "Variant memory: ByteString scalar lifecycle" {
    const allocator = testing.allocator;

    const test_bytes = try allocator.dupe(u8, &[_]u8{ 0x01, 0x02, 0x03, 0x04, 0x05 });
    defer allocator.free(test_bytes);

    // ByteString is created with .byte_string, not .scalar()
    const test_variant = ua.Variant{ .byte_string = test_bytes };
    const c_variant = try test_variant.toC(allocator);
    defer ua.Variant.freeCVariant(c_variant, allocator);

    const variant = try ua.Variant.fromC(c_variant, allocator);
    defer variant.deinit(allocator);

    try testing.expectEqual(5, variant.byte_string.len);
}

test "Variant memory: LocalizedText scalar lifecycle" {
    const allocator = testing.allocator;

    // Create LocalizedText with string literals (no allocation needed for source)
    const localized_text = ua.LocalizedText.init("en-US", "Test Text");

    // Convert to C and back (this should allocate)
    const c_variant = try ua.Variant.scalar(ua.LocalizedText, localized_text).toC(allocator);
    defer ua.Variant.freeCVariant(c_variant, allocator);

    const variant = try ua.Variant.fromC(c_variant, allocator);
    defer variant.deinit(allocator);

    // Verify the data is correct
    try testing.expectEqualStrings("en-US", variant.localized_text.locale);
    try testing.expectEqualStrings("Test Text", variant.localized_text.text);
}

test "Variant memory: LocalizedText with empty strings" {
    const allocator = testing.allocator;

    const empty_text = ua.LocalizedText.init("", "");

    const c_variant = try ua.Variant.scalar(ua.LocalizedText, empty_text).toC(allocator);
    defer ua.Variant.freeCVariant(c_variant, allocator);

    const variant = try ua.Variant.fromC(c_variant, allocator);
    defer variant.deinit(allocator);

    try testing.expectEqual(0, variant.localized_text.locale.len);
    try testing.expectEqual(0, variant.localized_text.text.len);
}

test "Variant memory: Boolean array lifecycle" {
    const allocator = testing.allocator;

    const test_array = try allocator.dupe(bool, &[_]bool{ true, false, true, false });
    defer allocator.free(test_array);

    const c_variant = try ua.Variant.array(bool, test_array).toC(allocator);
    defer ua.Variant.freeCVariant(c_variant, allocator);

    const variant = try ua.Variant.fromC(c_variant, allocator);
    defer variant.deinit(allocator);

    try testing.expectEqual(4, variant.boolean_array.len);
    try testing.expect(variant.boolean_array[0]);
    try testing.expect(!variant.boolean_array[1]);
}

test "Variant memory: Int32 array lifecycle" {
    const allocator = testing.allocator;

    const test_array = try allocator.dupe(i32, &[_]i32{ 1, 2, 3, 4, 5 });
    defer allocator.free(test_array);

    const c_variant = try ua.Variant.array(i32, test_array).toC(allocator);
    defer ua.Variant.freeCVariant(c_variant, allocator);

    const variant = try ua.Variant.fromC(c_variant, allocator);
    defer variant.deinit(allocator);

    try testing.expectEqual(5, variant.int32_array.len);
    try testing.expectEqual(1, variant.int32_array[0]);
    try testing.expectEqual(5, variant.int32_array[4]);
}

// TODO: String array lifecycle test - string arrays not yet fully supported in toC()
// test "Variant memory: String array lifecycle" {
//     const allocator = testing.allocator;
//
//     const str1 = try allocator.dupe(u8, "First");
//     defer allocator.free(str1);
//     const str2 = try allocator.dupe(u8, "Second");
//     defer allocator.free(str2);
//     const str3 = try allocator.dupe(u8, "Third");
//     defer allocator.free(str3);
//
//     const test_array = try allocator.dupe([]const u8, &[_][]const u8{ str1, str2, str3 });
//     defer allocator.free(test_array);
//
//     const c_variant = try ua.Variant.array([]const u8, test_array).toC(allocator);
//     defer ua.Variant.freeCVariant(c_variant, allocator);
//
//     const variant = try ua.Variant.fromC(c_variant, allocator);
//     defer variant.deinit(allocator);
//
//     try testing.expectEqual(3, variant.string_array.len);
//     try testing.expectEqualStrings("First", variant.string_array[0]);
//     try testing.expectEqualStrings("Second", variant.string_array[1]);
//     try testing.expectEqualStrings("Third", variant.string_array[2]);
// }

test "Variant memory: Multiple scalar types in sequence" {
    const allocator = testing.allocator;

    // Test multiple variants created and destroyed in sequence
    // to ensure no accumulating leaks

    for (0..10) |_| {
        // String variant
        {
            const test_string = try allocator.dupe(u8, "Test");
            defer allocator.free(test_string);

            const c_variant = try ua.Variant.scalar([]const u8, test_string).toC(allocator);
            defer ua.Variant.freeCVariant(c_variant, allocator);

            const variant = try ua.Variant.fromC(c_variant, allocator);
            defer variant.deinit(allocator);
        }

        // LocalizedText variant
        {
            const localized_text = ua.LocalizedText.init("en", "Text");

            const c_variant = try ua.Variant.scalar(ua.LocalizedText, localized_text).toC(allocator);
            defer ua.Variant.freeCVariant(c_variant, allocator);

            const variant = try ua.Variant.fromC(c_variant, allocator);
            defer variant.deinit(allocator);
        }

        // ByteString variant
        {
            const test_bytes = try allocator.dupe(u8, &[_]u8{1, 2, 3});
            defer allocator.free(test_bytes);

            const test_variant = ua.Variant{ .byte_string = test_bytes };
            const c_variant = try test_variant.toC(allocator);
            defer ua.Variant.freeCVariant(c_variant, allocator);

            const variant = try ua.Variant.fromC(c_variant, allocator);
            defer variant.deinit(allocator);
        }
    }
}

test "Variant memory: Multiple array types in sequence" {
    const allocator = testing.allocator;

    for (0..10) |_| {
        // Boolean array
        {
            const test_array = try allocator.dupe(bool, &[_]bool{true, false});
            defer allocator.free(test_array);

            const c_variant = try ua.Variant.array(bool, test_array).toC(allocator);
            defer ua.Variant.freeCVariant(c_variant, allocator);

            const variant = try ua.Variant.fromC(c_variant, allocator);
            defer variant.deinit(allocator);
        }

        // Int32 array
        {
            const test_array = try allocator.dupe(i32, &[_]i32{1, 2, 3});
            defer allocator.free(test_array);

            const c_variant = try ua.Variant.array(i32, test_array).toC(allocator);
            defer ua.Variant.freeCVariant(c_variant, allocator);

            const variant = try ua.Variant.fromC(c_variant, allocator);
            defer variant.deinit(allocator);
        }

        // Double array
        {
            const test_array = try allocator.dupe(f64, &[_]f64{ 1.0, 2.0, 3.0 });
            defer allocator.free(test_array);

            const c_variant = try ua.Variant.array(f64, test_array).toC(allocator);
            defer ua.Variant.freeCVariant(c_variant, allocator);

            const variant = try ua.Variant.fromC(c_variant, allocator);
            defer variant.deinit(allocator);
        }
    }
}

test "Variant memory: Empty variant lifecycle" {
    const allocator = testing.allocator;

    const empty_variant = ua.Variant{ .empty = {} };
    const c_variant = try empty_variant.toC(allocator);
    defer ua.Variant.freeCVariant(c_variant, allocator);

    const variant = try ua.Variant.fromC(c_variant, allocator);
    defer variant.deinit(allocator);

    try testing.expect(variant == .empty);
}

test "Variant memory: Stack-only scalars don't leak" {
    const allocator = testing.allocator;

    // These types should not allocate any heap memory in fromC
    const test_cases = .{
        ua.Variant{ .boolean = true },
        ua.Variant{ .sbyte = -42 },
        ua.Variant{ .byte = 255 },
        ua.Variant{ .int16 = -1234 },
        ua.Variant{ .uint16 = 65000 },
        ua.Variant{ .int32 = -123456 },
        ua.Variant{ .uint32 = 4000000000 },
        ua.Variant{ .int64 = -9876543210 },
        ua.Variant{ .uint64 = 18446744073709551615 },
        ua.Variant{ .float = 3.14159 },
        ua.Variant{ .double = 2.718281828459045 },
        ua.Variant{ .date_time = 132845952000000000 },
        ua.Variant{ .status_code = 0x80000000 },
    };

    inline for (test_cases) |test_variant| {
        const c_variant = try test_variant.toC(allocator);
        defer ua.Variant.freeCVariant(c_variant, allocator);

        const variant = try ua.Variant.fromC(c_variant, allocator);
        defer variant.deinit(allocator);

        // No assertions needed - just ensuring no leaks
    }
}

test "Variant memory: NodeId scalar lifecycle" {
    const allocator = testing.allocator;

    const node_id = ua.NodeId.initNumeric(2, 1000);
    const test_variant = ua.Variant.scalar(ua.NodeId, node_id);

    const c_variant = try test_variant.toC(allocator);
    defer ua.Variant.freeCVariant(c_variant, allocator);

    const variant = try ua.Variant.fromC(c_variant, allocator);
    defer variant.deinit(allocator);

    try testing.expectEqual(2, variant.node_id.numeric.namespace);
    try testing.expectEqual(1000, variant.node_id.numeric.identifier);
}

test "Variant memory: Guid scalar lifecycle" {
    const allocator = testing.allocator;

    const guid = ua.Guid{
        .data1 = 0x12345678,
        .data2 = 0xabcd,
        .data3 = 0xef01,
        .data4 = [_]u8{ 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef, 0x01 },
    };
    const test_variant = ua.Variant{ .guid = guid };

    const c_variant = try test_variant.toC(allocator);
    defer ua.Variant.freeCVariant(c_variant, allocator);

    const variant = try ua.Variant.fromC(c_variant, allocator);
    defer variant.deinit(allocator);

    try testing.expectEqual(0x12345678, variant.guid.data1);
    try testing.expectEqual(0xabcd, variant.guid.data2);
}

test "Variant memory: Large string lifecycle" {
    const allocator = testing.allocator;

    // Create a large string to stress-test memory management
    const large_size = 10000;
    const large_string = try allocator.alloc(u8, large_size);
    defer allocator.free(large_string);

    // Fill with pattern
    for (large_string, 0..) |*c, i| {
        c.* = @intCast((i % 26) + 'a');
    }

    const c_variant = try ua.Variant.scalar([]const u8, large_string).toC(allocator);
    defer ua.Variant.freeCVariant(c_variant, allocator);

    const variant = try ua.Variant.fromC(c_variant, allocator);
    defer variant.deinit(allocator);

    try testing.expectEqual(large_size, variant.string.len);
    try testing.expectEqual('a', variant.string[0]);
    try testing.expectEqual('a', variant.string[26]);
}

test "Variant memory: Large array lifecycle" {
    const allocator = testing.allocator;

    // Create a large array to stress-test memory management
    const large_size = 10000;
    const large_array = try allocator.alloc(i32, large_size);
    defer allocator.free(large_array);

    for (large_array, 0..) |*val, i| {
        val.* = @intCast(i);
    }

    const c_variant = try ua.Variant.array(i32, large_array).toC(allocator);
    defer ua.Variant.freeCVariant(c_variant, allocator);

    const variant = try ua.Variant.fromC(c_variant, allocator);
    defer variant.deinit(allocator);

    try testing.expectEqual(large_size, variant.int32_array.len);
    try testing.expectEqual(0, variant.int32_array[0]);
    try testing.expectEqual(9999, variant.int32_array[9999]);
}

test "Variant memory: LocalizedText with long strings" {
    const allocator = testing.allocator;

    // Create long locale and text strings
    const long_locale = try allocator.alloc(u8, 100);
    defer allocator.free(long_locale);
    @memset(long_locale, 'L');

    const long_text = try allocator.alloc(u8, 1000);
    defer allocator.free(long_text);
    @memset(long_text, 'T');

    const localized_text = ua.LocalizedText.init(long_locale, long_text);

    const c_variant = try ua.Variant.scalar(ua.LocalizedText, localized_text).toC(allocator);
    defer ua.Variant.freeCVariant(c_variant, allocator);

    const variant = try ua.Variant.fromC(c_variant, allocator);
    defer variant.deinit(allocator);

    try testing.expectEqual(100, variant.localized_text.locale.len);
    try testing.expectEqual(1000, variant.localized_text.text.len);
}
