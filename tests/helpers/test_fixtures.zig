const std = @import("std");
const ua = @import("ua");

/// Standard test node IDs used across tests
pub const TestNodeIds = struct {
    // Scalar types
    boolean: ua.NodeId,
    sbyte: ua.NodeId,
    byte: ua.NodeId,
    int16: ua.NodeId,
    uint16: ua.NodeId,
    int32: ua.NodeId,
    uint32: ua.NodeId,
    int64: ua.NodeId,
    uint64: ua.NodeId,
    float: ua.NodeId,
    double: ua.NodeId,
    string: ua.NodeId,
    date_time: ua.NodeId,
    guid: ua.NodeId,
    byte_string: ua.NodeId,
    node_id: ua.NodeId,
    status_code: ua.NodeId,
    localized_text: ua.NodeId,

    // Array types
    boolean_array: ua.NodeId,
    sbyte_array: ua.NodeId,
    byte_array: ua.NodeId,
    int16_array: ua.NodeId,
    uint16_array: ua.NodeId,
    int32_array: ua.NodeId,
    uint32_array: ua.NodeId,
    int64_array: ua.NodeId,
    uint64_array: ua.NodeId,
    float_array: ua.NodeId,
    double_array: ua.NodeId,
    date_time_array: ua.NodeId,
    status_code_array: ua.NodeId,

    // Special access types
    readonly: ua.NodeId,
    writeonly: ua.NodeId,
};

/// Test data for all Variant scalar types
pub const TestScalarData = struct {
    pub const boolean_value: bool = true;
    pub const sbyte_value: i8 = -42;
    pub const byte_value: u8 = 255;
    pub const int16_value: i16 = -1234;
    pub const uint16_value: u16 = 65000;
    pub const int32_value: i32 = -123456;
    pub const uint32_value: u32 = 4000000000;
    pub const int64_value: i64 = -9876543210;
    pub const uint64_value: u64 = 18446744073709551615;
    pub const float_value: f32 = 3.14159;
    pub const double_value: f64 = 2.718281828459045;
    pub const string_value: []const u8 = "Test String Value";
    pub const date_time_value: i64 = 132845952000000000; // 2023-01-01 00:00:00 UTC
    pub const byte_string_value: []const u8 = "Binary Data \x00\xFF\x42";
    pub const status_code_value: u32 = 0x00000000; // UA_STATUSCODE_GOOD

    pub fn guidValue() ua.Guid {
        return ua.Guid{
            .data1 = 0x12345678,
            .data2 = 0xABCD,
            .data3 = 0xEF01,
            .data4 = [_]u8{ 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF, 0x01 },
        };
    }

    pub fn nodeIdValue() ua.NodeId {
        return ua.NodeId.initNumeric(1, 1000);
    }

    pub fn localizedTextValue() ua.LocalizedText {
        return ua.LocalizedText.init("en-US", "Localized Test Text");
    }
};

/// Test data for all Variant array types
pub const TestArrayData = struct {
    pub const boolean_array = [_]bool{ true, false, true, false, true };
    pub const sbyte_array = [_]i8{ -128, -64, 0, 64, 127 };
    pub const byte_array = [_]u8{ 0, 64, 128, 192, 255 };
    pub const int16_array = [_]i16{ -32768, -16384, 0, 16384, 32767 };
    pub const uint16_array = [_]u16{ 0, 16384, 32768, 49152, 65535 };
    pub const int32_array = [_]i32{ -2147483648, -1000000, 0, 1000000, 2147483647 };
    pub const uint32_array = [_]u32{ 0, 1000000, 2147483648, 3000000000, 4294967295 };
    pub const int64_array = [_]i64{ -9223372036854775808, -1000000000, 0, 1000000000, 9223372036854775807 };
    pub const uint64_array = [_]u64{ 0, 1000000000, 9223372036854775808, 15000000000000000000, 18446744073709551615 };
    pub const float_array = [_]f32{ -3.14, -1.0, 0.0, 1.0, 3.14 };
    pub const double_array = [_]f64{ -2.718281828, -1.414213562, 0.0, 1.414213562, 2.718281828 };
    pub const date_time_array = [_]i64{ 132845952000000000, 132845952000000001, 132845952000000002 };
    pub const status_code_array = [_]u32{ 0x00000000, 0x80000000, 0x00FF0000 };

    // Empty arrays for testing edge cases
    pub const empty_int32_array = [_]i32{};
    pub const empty_double_array = [_]f64{};
    pub const empty_bool_array = [_]bool{};

    // Large arrays for performance testing
    pub fn largeInt32Array(allocator: std.mem.Allocator, size: usize) ![]i32 {
        const array = try allocator.alloc(i32, size);
        for (array, 0..) |*item, i| {
            item.* = @intCast(i);
        }
        return array;
    }

    pub fn largeDoubleArray(allocator: std.mem.Allocator, size: usize) ![]f64 {
        const array = try allocator.alloc(f64, size);
        for (array, 0..) |*item, i| {
            item.* = @as(f64, @floatFromInt(i)) * 0.1;
        }
        return array;
    }
};

/// Setup all standard test nodes on a server
pub fn setupStandardNodes(server: *ua.Server, allocator: std.mem.Allocator) !TestNodeIds {
    const parent = ua.StandardNodeId.objects_folder;
    const ref_type = ua.ReferenceType.organizes;
    const base_type = ua.StandardNodeId.base_data_variable_type;

    // Scalar nodes
    const boolean = try server.addVariableNode(
        ua.NodeId.initString(1, "test.boolean"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestBoolean"),
        base_type,
        .{
            .value = ua.Variant.scalar(bool, TestScalarData.boolean_value),
            .display_name = ua.LocalizedText.init("en-US", "Test Boolean"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    const sbyte = try server.addVariableNode(
        ua.NodeId.initString(1, "test.sbyte"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestSByte"),
        base_type,
        .{
            .value = ua.Variant.scalar(i8, TestScalarData.sbyte_value),
            .display_name = ua.LocalizedText.init("en-US", "Test SByte"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    const byte = try server.addVariableNode(
        ua.NodeId.initString(1, "test.byte"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestByte"),
        base_type,
        .{
            .value = ua.Variant.scalar(u8, TestScalarData.byte_value),
            .display_name = ua.LocalizedText.init("en-US", "Test Byte"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    const int16 = try server.addVariableNode(
        ua.NodeId.initString(1, "test.int16"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestInt16"),
        base_type,
        .{
            .value = ua.Variant.scalar(i16, TestScalarData.int16_value),
            .display_name = ua.LocalizedText.init("en-US", "Test Int16"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    const uint16 = try server.addVariableNode(
        ua.NodeId.initString(1, "test.uint16"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestUInt16"),
        base_type,
        .{
            .value = ua.Variant.scalar(u16, TestScalarData.uint16_value),
            .display_name = ua.LocalizedText.init("en-US", "Test UInt16"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    const int32 = try server.addVariableNode(
        ua.NodeId.initString(1, "test.int32"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestInt32"),
        base_type,
        .{
            .value = ua.Variant.scalar(i32, TestScalarData.int32_value),
            .display_name = ua.LocalizedText.init("en-US", "Test Int32"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    const uint32 = try server.addVariableNode(
        ua.NodeId.initString(1, "test.uint32"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestUInt32"),
        base_type,
        .{
            .value = ua.Variant.scalar(u32, TestScalarData.uint32_value),
            .display_name = ua.LocalizedText.init("en-US", "Test UInt32"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    const int64 = try server.addVariableNode(
        ua.NodeId.initString(1, "test.int64"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestInt64"),
        base_type,
        .{
            .value = ua.Variant.scalar(i64, TestScalarData.int64_value),
            .display_name = ua.LocalizedText.init("en-US", "Test Int64"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    const uint64 = try server.addVariableNode(
        ua.NodeId.initString(1, "test.uint64"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestUInt64"),
        base_type,
        .{
            .value = ua.Variant.scalar(u64, TestScalarData.uint64_value),
            .display_name = ua.LocalizedText.init("en-US", "Test UInt64"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    const float = try server.addVariableNode(
        ua.NodeId.initString(1, "test.float"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestFloat"),
        base_type,
        .{
            .value = ua.Variant.scalar(f32, TestScalarData.float_value),
            .display_name = ua.LocalizedText.init("en-US", "Test Float"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    const double = try server.addVariableNode(
        ua.NodeId.initString(1, "test.double"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestDouble"),
        base_type,
        .{
            .value = ua.Variant.scalar(f64, TestScalarData.double_value),
            .display_name = ua.LocalizedText.init("en-US", "Test Double"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    const string = try server.addVariableNode(
        ua.NodeId.initString(1, "test.string"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestString"),
        base_type,
        .{
            .value = ua.Variant.scalar([]const u8, TestScalarData.string_value),
            .display_name = ua.LocalizedText.init("en-US", "Test String"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    const date_time = try server.addVariableNode(
        ua.NodeId.initString(1, "test.datetime"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestDateTime"),
        base_type,
        .{
            .value = ua.Variant{ .date_time = TestScalarData.date_time_value },
            .display_name = ua.LocalizedText.init("en-US", "Test DateTime"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    const guid = try server.addVariableNode(
        ua.NodeId.initString(1, "test.guid"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestGuid"),
        base_type,
        .{
            .value = ua.Variant{ .guid = TestScalarData.guidValue() },
            .display_name = ua.LocalizedText.init("en-US", "Test Guid"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    const byte_string = try server.addVariableNode(
        ua.NodeId.initString(1, "test.bytestring"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestByteString"),
        base_type,
        .{
            .value = ua.Variant{ .byte_string = TestScalarData.byte_string_value },
            .display_name = ua.LocalizedText.init("en-US", "Test ByteString"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    const node_id = try server.addVariableNode(
        ua.NodeId.initString(1, "test.nodeid"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestNodeId"),
        base_type,
        .{
            .value = ua.Variant.scalar(ua.NodeId, TestScalarData.nodeIdValue()),
            .display_name = ua.LocalizedText.init("en-US", "Test NodeId"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    const status_code = try server.addVariableNode(
        ua.NodeId.initString(1, "test.statuscode"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestStatusCode"),
        base_type,
        .{
            .value = ua.Variant{ .status_code = TestScalarData.status_code_value },
            .display_name = ua.LocalizedText.init("en-US", "Test StatusCode"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    const localized_text = try server.addVariableNode(
        ua.NodeId.initString(1, "test.localizedtext"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestLocalizedText"),
        base_type,
        .{
            .value = ua.Variant.scalar(ua.LocalizedText, TestScalarData.localizedTextValue()),
            .display_name = ua.LocalizedText.init("en-US", "Test LocalizedText"),
            .access_level = .{ .read = true, .write = true },
        },
        allocator,
    );

    // Array nodes
    const boolean_array = try server.addVariableNode(
        ua.NodeId.initString(1, "test.boolean_array"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestBooleanArray"),
        base_type,
        .{
            .value = ua.Variant.array(bool, &TestArrayData.boolean_array),
            .display_name = ua.LocalizedText.init("en-US", "Test Boolean Array"),
            .access_level = .{ .read = true, .write = true },
            .value_rank = 1,
            .array_dimensions = &[_]u32{TestArrayData.boolean_array.len},
        },
        allocator,
    );

    const sbyte_array = try server.addVariableNode(
        ua.NodeId.initString(1, "test.sbyte_array"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestSByteArray"),
        base_type,
        .{
            .value = ua.Variant.array(i8, &TestArrayData.sbyte_array),
            .display_name = ua.LocalizedText.init("en-US", "Test SByte Array"),
            .access_level = .{ .read = true, .write = true },
            .value_rank = 1,
            .array_dimensions = &[_]u32{TestArrayData.sbyte_array.len},
        },
        allocator,
    );

    const byte_array = try server.addVariableNode(
        ua.NodeId.initString(1, "test.byte_array"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestByteArray"),
        base_type,
        .{
            .value = ua.Variant.array(u8, &TestArrayData.byte_array),
            .display_name = ua.LocalizedText.init("en-US", "Test Byte Array"),
            .access_level = .{ .read = true, .write = true },
            .value_rank = 1,
            .array_dimensions = &[_]u32{TestArrayData.byte_array.len},
        },
        allocator,
    );

    const int16_array = try server.addVariableNode(
        ua.NodeId.initString(1, "test.int16_array"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestInt16Array"),
        base_type,
        .{
            .value = ua.Variant.array(i16, &TestArrayData.int16_array),
            .display_name = ua.LocalizedText.init("en-US", "Test Int16 Array"),
            .access_level = .{ .read = true, .write = true },
            .value_rank = 1,
            .array_dimensions = &[_]u32{TestArrayData.int16_array.len},
        },
        allocator,
    );

    const uint16_array = try server.addVariableNode(
        ua.NodeId.initString(1, "test.uint16_array"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestUInt16Array"),
        base_type,
        .{
            .value = ua.Variant.array(u16, &TestArrayData.uint16_array),
            .display_name = ua.LocalizedText.init("en-US", "Test UInt16 Array"),
            .access_level = .{ .read = true, .write = true },
            .value_rank = 1,
            .array_dimensions = &[_]u32{TestArrayData.uint16_array.len},
        },
        allocator,
    );

    const int32_array = try server.addVariableNode(
        ua.NodeId.initString(1, "test.int32_array"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestInt32Array"),
        base_type,
        .{
            .value = ua.Variant.array(i32, &TestArrayData.int32_array),
            .display_name = ua.LocalizedText.init("en-US", "Test Int32 Array"),
            .access_level = .{ .read = true, .write = true },
            .value_rank = 1,
            .array_dimensions = &[_]u32{TestArrayData.int32_array.len},
        },
        allocator,
    );

    const uint32_array = try server.addVariableNode(
        ua.NodeId.initString(1, "test.uint32_array"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestUInt32Array"),
        base_type,
        .{
            .value = ua.Variant.array(u32, &TestArrayData.uint32_array),
            .display_name = ua.LocalizedText.init("en-US", "Test UInt32 Array"),
            .access_level = .{ .read = true, .write = true },
            .value_rank = 1,
            .array_dimensions = &[_]u32{TestArrayData.uint32_array.len},
        },
        allocator,
    );

    const int64_array = try server.addVariableNode(
        ua.NodeId.initString(1, "test.int64_array"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestInt64Array"),
        base_type,
        .{
            .value = ua.Variant.array(i64, &TestArrayData.int64_array),
            .display_name = ua.LocalizedText.init("en-US", "Test Int64 Array"),
            .access_level = .{ .read = true, .write = true },
            .value_rank = 1,
            .array_dimensions = &[_]u32{TestArrayData.int64_array.len},
        },
        allocator,
    );

    const uint64_array = try server.addVariableNode(
        ua.NodeId.initString(1, "test.uint64_array"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestUInt64Array"),
        base_type,
        .{
            .value = ua.Variant.array(u64, &TestArrayData.uint64_array),
            .display_name = ua.LocalizedText.init("en-US", "Test UInt64 Array"),
            .access_level = .{ .read = true, .write = true },
            .value_rank = 1,
            .array_dimensions = &[_]u32{TestArrayData.uint64_array.len},
        },
        allocator,
    );

    const float_array = try server.addVariableNode(
        ua.NodeId.initString(1, "test.float_array"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestFloatArray"),
        base_type,
        .{
            .value = ua.Variant.array(f32, &TestArrayData.float_array),
            .display_name = ua.LocalizedText.init("en-US", "Test Float Array"),
            .access_level = .{ .read = true, .write = true },
            .value_rank = 1,
            .array_dimensions = &[_]u32{TestArrayData.float_array.len},
        },
        allocator,
    );

    const double_array = try server.addVariableNode(
        ua.NodeId.initString(1, "test.double_array"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestDoubleArray"),
        base_type,
        .{
            .value = ua.Variant.array(f64, &TestArrayData.double_array),
            .display_name = ua.LocalizedText.init("en-US", "Test Double Array"),
            .access_level = .{ .read = true, .write = true },
            .value_rank = 1,
            .array_dimensions = &[_]u32{TestArrayData.double_array.len},
        },
        allocator,
    );

    const date_time_array = try server.addVariableNode(
        ua.NodeId.initString(1, "test.datetime_array"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestDateTimeArray"),
        base_type,
        .{
            .value = ua.Variant{ .date_time_array = &TestArrayData.date_time_array },
            .display_name = ua.LocalizedText.init("en-US", "Test DateTime Array"),
            .access_level = .{ .read = true, .write = true },
            .value_rank = 1,
            .array_dimensions = &[_]u32{TestArrayData.date_time_array.len},
        },
        allocator,
    );

    const status_code_array = try server.addVariableNode(
        ua.NodeId.initString(1, "test.statuscode_array"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestStatusCodeArray"),
        base_type,
        .{
            .value = ua.Variant{ .status_code_array = &TestArrayData.status_code_array },
            .display_name = ua.LocalizedText.init("en-US", "Test StatusCode Array"),
            .access_level = .{ .read = true, .write = true },
            .value_rank = 1,
            .array_dimensions = &[_]u32{TestArrayData.status_code_array.len},
        },
        allocator,
    );

    // Special access nodes
    const readonly = try server.addVariableNode(
        ua.NodeId.initString(1, "test.readonly"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestReadOnly"),
        base_type,
        .{
            .value = ua.Variant.scalar(i32, 999),
            .display_name = ua.LocalizedText.init("en-US", "Test Read Only"),
            .access_level = .{ .read = true, .write = false },
        },
        allocator,
    );

    const writeonly = try server.addVariableNode(
        ua.NodeId.initString(1, "test.writeonly"),
        parent,
        ref_type,
        ua.QualifiedName.init(1, "TestWriteOnly"),
        base_type,
        .{
            .value = ua.Variant.scalar(i32, 888),
            .display_name = ua.LocalizedText.init("en-US", "Test Write Only"),
            .access_level = .{ .read = false, .write = true },
        },
        allocator,
    );

    return TestNodeIds{
        // Scalars
        .boolean = boolean,
        .sbyte = sbyte,
        .byte = byte,
        .int16 = int16,
        .uint16 = uint16,
        .int32 = int32,
        .uint32 = uint32,
        .int64 = int64,
        .uint64 = uint64,
        .float = float,
        .double = double,
        .string = string,
        .date_time = date_time,
        .guid = guid,
        .byte_string = byte_string,
        .node_id = node_id,
        .status_code = status_code,
        .localized_text = localized_text,

        // Arrays
        .boolean_array = boolean_array,
        .sbyte_array = sbyte_array,
        .byte_array = byte_array,
        .int16_array = int16_array,
        .uint16_array = uint16_array,
        .int32_array = int32_array,
        .uint32_array = uint32_array,
        .int64_array = int64_array,
        .uint64_array = uint64_array,
        .float_array = float_array,
        .double_array = double_array,
        .date_time_array = date_time_array,
        .status_code_array = status_code_array,

        // Special
        .readonly = readonly,
        .writeonly = writeonly,
    };
}
