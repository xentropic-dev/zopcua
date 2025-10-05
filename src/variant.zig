const std = @import("std");
const c = @import("c.zig");
const LocalizedText = @import("localized_text.zig").LocalizedText;
const String = @import("localized_text.zig").String;

/// OPC UA Variant - can hold different types of data
pub const Variant = union(enum) {
    empty: void,

    // Scalar types
    boolean: bool,
    sbyte: i8,
    byte: u8,
    int16: i16,
    uint16: u16,
    int32: i32,
    uint32: u32,
    int64: i64,
    uint64: u64,
    float: f32,
    double: f64,
    string: []const u8,
    date_time: i64,
    guid: Guid,
    byte_string: []const u8,
    node_id: NodeId,
    status_code: u32,
    localized_text: LocalizedText,

    // Array types
    boolean_array: []const bool,
    sbyte_array: []const i8,
    byte_array: []const u8,
    int16_array: []const i16,
    uint16_array: []const u16,
    int32_array: []const i32,
    uint32_array: []const u32,
    int64_array: []const i64,
    uint64_array: []const u64,
    float_array: []const f32,
    double_array: []const f64,
    string_array: []const []const u8,
    date_time_array: []const i64,
    node_id_array: []const NodeId,
    status_code_array: []const u32,

    // For complex types or types not covered above
    raw: c.UA_Variant,

    /// Create a scalar variant
    pub fn scalar(comptime T: type, value: T) Variant {
        return switch (T) {
            bool => .{ .boolean = value },
            i8 => .{ .sbyte = value },
            u8 => .{ .byte = value },
            i16 => .{ .int16 = value },
            u16 => .{ .uint16 = value },
            i32 => .{ .int32 = value },
            u32 => .{ .uint32 = value },
            i64 => .{ .int64 = value },
            u64 => .{ .uint64 = value },
            f32 => .{ .float = value },
            f64 => .{ .double = value },
            []const u8 => .{ .string = value },
            LocalizedText => .{ .localized_text = value },
            NodeId => .{ .node_id = value },
            else => @compileError("Unsupported scalar type: " ++ @typeName(T)),
        };
    }

    /// Create an array variant
    pub fn array(comptime T: type, values: []const T) Variant {
        return switch (T) {
            bool => .{ .boolean_array = values },
            i8 => .{ .sbyte_array = values },
            u8 => .{ .byte_array = values },
            i16 => .{ .int16_array = values },
            u16 => .{ .uint16_array = values },
            i32 => .{ .int32_array = values },
            u32 => .{ .uint32_array = values },
            i64 => .{ .int64_array = values },
            u64 => .{ .uint64_array = values },
            f32 => .{ .float_array = values },
            f64 => .{ .double_array = values },
            []const u8 => .{ .string_array = values },
            NodeId => .{ .node_id_array = values },
            else => @compileError("Unsupported array type: " ++ @typeName(T)),
        };
    }

    /// Convert to C API representation
    pub fn toC(self: Variant, allocator: std.mem.Allocator) !c.UA_Variant {
        var result = std.mem.zeroes(c.UA_Variant);

        switch (self) {
            .empty => {},

            .boolean => |val| {
                result.type = &c.UA_TYPES[c.UA_TYPES_BOOLEAN];
                const data = try allocator.create(c.UA_Boolean);
                data.* = val;
                result.data = data;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .sbyte => |val| {
                result.type = &c.UA_TYPES[c.UA_TYPES_SBYTE];
                const data = try allocator.create(c.UA_SByte);
                data.* = val;
                result.data = data;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .byte => |val| {
                result.type = &c.UA_TYPES[c.UA_TYPES_BYTE];
                const data = try allocator.create(c.UA_Byte);
                data.* = val;
                result.data = data;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .int16 => |val| {
                result.type = &c.UA_TYPES[c.UA_TYPES_INT16];
                const data = try allocator.create(c.UA_Int16);
                data.* = val;
                result.data = data;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .uint16 => |val| {
                result.type = &c.UA_TYPES[c.UA_TYPES_UINT16];
                const data = try allocator.create(c.UA_UInt16);
                data.* = val;
                result.data = data;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .int32 => |val| {
                result.type = &c.UA_TYPES[c.UA_TYPES_INT32];
                const data = try allocator.create(c.UA_Int32);
                data.* = val;
                result.data = data;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .uint32 => |val| {
                result.type = &c.UA_TYPES[c.UA_TYPES_UINT32];
                const data = try allocator.create(c.UA_UInt32);
                data.* = val;
                result.data = data;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .int64 => |val| {
                result.type = &c.UA_TYPES[c.UA_TYPES_INT64];
                const data = try allocator.create(c.UA_Int64);
                data.* = val;
                result.data = data;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .uint64 => |val| {
                result.type = &c.UA_TYPES[c.UA_TYPES_UINT64];
                const data = try allocator.create(c.UA_UInt64);
                data.* = val;
                result.data = data;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .float => |val| {
                result.type = &c.UA_TYPES[c.UA_TYPES_FLOAT];
                const data = try allocator.create(c.UA_Float);
                data.* = val;
                result.data = data;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .double => |val| {
                result.type = &c.UA_TYPES[c.UA_TYPES_DOUBLE];
                const data = try allocator.create(c.UA_Double);
                data.* = val;
                result.data = data;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .string => |val| {
                result.type = &c.UA_TYPES[c.UA_TYPES_STRING];
                const data = try allocator.create(c.UA_String);
                data.* = String.toC(val);
                result.data = data;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .date_time => |val| {
                result.type = &c.UA_TYPES[c.UA_TYPES_DATETIME];
                const data = try allocator.create(c.UA_DateTime);
                data.* = val;
                result.data = data;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .guid => |val| {
                result.type = &c.UA_TYPES[c.UA_TYPES_GUID];
                const data = try allocator.create(c.UA_Guid);
                data.* = val.toC();
                result.data = data;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .byte_string => |val| {
                result.type = &c.UA_TYPES[c.UA_TYPES_BYTESTRING];
                const data = try allocator.create(c.UA_ByteString);
                data.* = String.toC(val);
                result.data = data;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .node_id => |val| {
                result.type = &c.UA_TYPES[c.UA_TYPES_NODEID];
                const data = try allocator.create(c.UA_NodeId);
                data.* = val.toC();
                result.data = data;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .status_code => |val| {
                result.type = &c.UA_TYPES[c.UA_TYPES_STATUSCODE];
                const data = try allocator.create(c.UA_StatusCode);
                data.* = val;
                result.data = data;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .localized_text => |val| {
                result.type = &c.UA_TYPES[c.UA_TYPES_LOCALIZEDTEXT];
                const data = try allocator.create(c.UA_LocalizedText);
                data.* = val.toC();
                result.data = data;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            // Arrays
            .boolean_array => |values| {
                result.type = &c.UA_TYPES[c.UA_TYPES_BOOLEAN];
                const data = try allocator.alloc(c.UA_Boolean, values.len);
                @memcpy(data, values);
                result.data = data.ptr;
                result.arrayLength = values.len;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .sbyte_array => |values| {
                result.type = &c.UA_TYPES[c.UA_TYPES_SBYTE];
                const data = try allocator.alloc(c.UA_SByte, values.len);
                @memcpy(data, values);
                result.data = data.ptr;
                result.arrayLength = values.len;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .byte_array => |values| {
                result.type = &c.UA_TYPES[c.UA_TYPES_BYTE];
                const data = try allocator.alloc(c.UA_Byte, values.len);
                @memcpy(data, values);
                result.data = data.ptr;
                result.arrayLength = values.len;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .int16_array => |values| {
                result.type = &c.UA_TYPES[c.UA_TYPES_INT16];
                const data = try allocator.alloc(c.UA_Int16, values.len);
                @memcpy(data, values);
                result.data = data.ptr;
                result.arrayLength = values.len;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .uint16_array => |values| {
                result.type = &c.UA_TYPES[c.UA_TYPES_UINT16];
                const data = try allocator.alloc(c.UA_UInt16, values.len);
                @memcpy(data, values);
                result.data = data.ptr;
                result.arrayLength = values.len;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .int32_array => |values| {
                result.type = &c.UA_TYPES[c.UA_TYPES_INT32];
                const data = try allocator.alloc(c.UA_Int32, values.len);
                @memcpy(data, values);
                result.data = data.ptr;
                result.arrayLength = values.len;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .uint32_array => |values| {
                result.type = &c.UA_TYPES[c.UA_TYPES_UINT32];
                const data = try allocator.alloc(c.UA_UInt32, values.len);
                @memcpy(data, values);
                result.data = data.ptr;
                result.arrayLength = values.len;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .int64_array => |values| {
                result.type = &c.UA_TYPES[c.UA_TYPES_INT64];
                const data = try allocator.alloc(c.UA_Int64, values.len);
                @memcpy(data, values);
                result.data = data.ptr;
                result.arrayLength = values.len;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .uint64_array => |values| {
                result.type = &c.UA_TYPES[c.UA_TYPES_UINT64];
                const data = try allocator.alloc(c.UA_UInt64, values.len);
                @memcpy(data, values);
                result.data = data.ptr;
                result.arrayLength = values.len;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .float_array => |values| {
                result.type = &c.UA_TYPES[c.UA_TYPES_FLOAT];
                const data = try allocator.alloc(c.UA_Float, values.len);
                @memcpy(data, values);
                result.data = data.ptr;
                result.arrayLength = values.len;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .double_array => |values| {
                result.type = &c.UA_TYPES[c.UA_TYPES_DOUBLE];
                const data = try allocator.alloc(c.UA_Double, values.len);
                @memcpy(data, values);
                result.data = data.ptr;
                result.arrayLength = values.len;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .string_array => |values| {
                result.type = &c.UA_TYPES[c.UA_TYPES_STRING];
                const data = try allocator.alloc(c.UA_String, values.len);
                for (values, 0..) |str, i| {
                    data[i] = String.toC(str);
                }
                result.data = data.ptr;
                result.arrayLength = values.len;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .date_time_array => |values| {
                result.type = &c.UA_TYPES[c.UA_TYPES_DATETIME];
                const data = try allocator.alloc(c.UA_DateTime, values.len);
                @memcpy(data, values);
                result.data = data.ptr;
                result.arrayLength = values.len;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .node_id_array => |values| {
                result.type = &c.UA_TYPES[c.UA_TYPES_NODEID];
                const data = try allocator.alloc(c.UA_NodeId, values.len);
                for (values, 0..) |node_id, i| {
                    data[i] = node_id.toC();
                }
                result.data = data.ptr;
                result.arrayLength = values.len;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .status_code_array => |values| {
                result.type = &c.UA_TYPES[c.UA_TYPES_STATUSCODE];
                const data = try allocator.alloc(c.UA_StatusCode, values.len);
                @memcpy(data, values);
                result.data = data.ptr;
                result.arrayLength = values.len;
                result.storageType = c.UA_VARIANT_DATA_NODELETE;
            },

            .raw => |val| result = val,
        }

        return result;
    }

    /// Convert from C API representation
    pub fn fromC(value: c.UA_Variant) Variant {
        if (value.type == null or value.data == null) return .empty;

        const type_index = getTypeIndex(value.type);
        const is_array = value.arrayLength > 0;

        if (is_array) {
            return fromCArray(value, type_index) catch .{ .raw = value };
        } else {
            return fromCScalar(value, type_index) catch .{ .raw = value };
        }
    }

    fn getTypeIndex(data_type: [*c]const c.UA_DataType) usize {
        const offset = @intFromPtr(data_type) - @intFromPtr(&c.UA_TYPES[0]);
        return offset / @sizeOf(c.UA_DataType);
    }

    fn fromCScalar(value: c.UA_Variant, type_index: usize) !Variant {
        return switch (type_index) {
            c.UA_TYPES_BOOLEAN => blk: {
                const ptr: *const c.UA_Boolean = @ptrCast(@alignCast(value.data));
                break :blk .{ .boolean = ptr.* };
            },
            c.UA_TYPES_SBYTE => blk: {
                const ptr: *const c.UA_SByte = @ptrCast(@alignCast(value.data));
                break :blk .{ .sbyte = ptr.* };
            },
            c.UA_TYPES_BYTE => blk: {
                const ptr: *const c.UA_Byte = @ptrCast(@alignCast(value.data));
                break :blk .{ .byte = ptr.* };
            },
            c.UA_TYPES_INT16 => blk: {
                const ptr: *const c.UA_Int16 = @ptrCast(@alignCast(value.data));
                break :blk .{ .int16 = ptr.* };
            },
            c.UA_TYPES_UINT16 => blk: {
                const ptr: *const c.UA_UInt16 = @ptrCast(@alignCast(value.data));
                break :blk .{ .uint16 = ptr.* };
            },
            c.UA_TYPES_INT32 => blk: {
                const ptr: *const c.UA_Int32 = @ptrCast(@alignCast(value.data));
                break :blk .{ .int32 = ptr.* };
            },
            c.UA_TYPES_UINT32 => blk: {
                const ptr: *const c.UA_UInt32 = @ptrCast(@alignCast(value.data));
                break :blk .{ .uint32 = ptr.* };
            },
            c.UA_TYPES_INT64 => blk: {
                const ptr: *const c.UA_Int64 = @ptrCast(@alignCast(value.data));
                break :blk .{ .int64 = ptr.* };
            },
            c.UA_TYPES_UINT64 => blk: {
                const ptr: *const c.UA_UInt64 = @ptrCast(@alignCast(value.data));
                break :blk .{ .uint64 = ptr.* };
            },
            c.UA_TYPES_FLOAT => blk: {
                const ptr: *const c.UA_Float = @ptrCast(@alignCast(value.data));
                break :blk .{ .float = ptr.* };
            },
            c.UA_TYPES_DOUBLE => blk: {
                const ptr: *const c.UA_Double = @ptrCast(@alignCast(value.data));
                break :blk .{ .double = ptr.* };
            },
            c.UA_TYPES_STRING => blk: {
                const ptr: *const c.UA_String = @ptrCast(@alignCast(value.data));
                break :blk .{ .string = String.fromC(ptr.*) };
            },
            c.UA_TYPES_DATETIME => blk: {
                const ptr: *const c.UA_DateTime = @ptrCast(@alignCast(value.data));
                break :blk .{ .date_time = ptr.* };
            },
            c.UA_TYPES_GUID => blk: {
                const ptr: *const c.UA_Guid = @ptrCast(@alignCast(value.data));
                break :blk .{ .guid = Guid.fromC(ptr.*) };
            },
            c.UA_TYPES_BYTESTRING => blk: {
                const ptr: *const c.UA_ByteString = @ptrCast(@alignCast(value.data));
                break :blk .{ .byte_string = String.fromC(ptr.*) };
            },
            c.UA_TYPES_NODEID => blk: {
                const ptr: *const c.UA_NodeId = @ptrCast(@alignCast(value.data));
                break :blk .{ .node_id = NodeId.fromC(ptr.*) };
            },
            c.UA_TYPES_STATUSCODE => blk: {
                const ptr: *const c.UA_StatusCode = @ptrCast(@alignCast(value.data));
                break :blk .{ .status_code = ptr.* };
            },
            c.UA_TYPES_LOCALIZEDTEXT => blk: {
                const ptr: *const c.UA_LocalizedText = @ptrCast(@alignCast(value.data));
                break :blk .{ .localized_text = LocalizedText.fromC(ptr.*) };
            },
            else => error.UnsupportedType,
        };
    }

    fn fromCArray(value: c.UA_Variant, type_index: usize) !Variant {
        return switch (type_index) {
            c.UA_TYPES_BOOLEAN => blk: {
                const ptr: [*]const c.UA_Boolean = @ptrCast(@alignCast(value.data));
                break :blk .{ .boolean_array = ptr[0..value.arrayLength] };
            },
            c.UA_TYPES_SBYTE => blk: {
                const ptr: [*]const c.UA_SByte = @ptrCast(@alignCast(value.data));
                break :blk .{ .sbyte_array = ptr[0..value.arrayLength] };
            },
            c.UA_TYPES_BYTE => blk: {
                const ptr: [*]const c.UA_Byte = @ptrCast(@alignCast(value.data));
                break :blk .{ .byte_array = ptr[0..value.arrayLength] };
            },
            c.UA_TYPES_INT16 => blk: {
                const ptr: [*]const c.UA_Int16 = @ptrCast(@alignCast(value.data));
                break :blk .{ .int16_array = ptr[0..value.arrayLength] };
            },
            c.UA_TYPES_UINT16 => blk: {
                const ptr: [*]const c.UA_UInt16 = @ptrCast(@alignCast(value.data));
                break :blk .{ .uint16_array = ptr[0..value.arrayLength] };
            },
            c.UA_TYPES_INT32 => blk: {
                const ptr: [*]const c.UA_Int32 = @ptrCast(@alignCast(value.data));
                break :blk .{ .int32_array = ptr[0..value.arrayLength] };
            },
            c.UA_TYPES_UINT32 => blk: {
                const ptr: [*]const c.UA_UInt32 = @ptrCast(@alignCast(value.data));
                break :blk .{ .uint32_array = ptr[0..value.arrayLength] };
            },
            c.UA_TYPES_INT64 => blk: {
                const ptr: [*]const c.UA_Int64 = @ptrCast(@alignCast(value.data));
                break :blk .{ .int64_array = ptr[0..value.arrayLength] };
            },
            c.UA_TYPES_UINT64 => blk: {
                const ptr: [*]const c.UA_UInt64 = @ptrCast(@alignCast(value.data));
                break :blk .{ .uint64_array = ptr[0..value.arrayLength] };
            },
            c.UA_TYPES_FLOAT => blk: {
                const ptr: [*]const c.UA_Float = @ptrCast(@alignCast(value.data));
                break :blk .{ .float_array = ptr[0..value.arrayLength] };
            },
            c.UA_TYPES_DOUBLE => blk: {
                const ptr: [*]const c.UA_Double = @ptrCast(@alignCast(value.data));
                break :blk .{ .double_array = ptr[0..value.arrayLength] };
            },
            c.UA_TYPES_DATETIME => blk: {
                const ptr: [*]const c.UA_DateTime = @ptrCast(@alignCast(value.data));
                break :blk .{ .date_time_array = ptr[0..value.arrayLength] };
            },
            c.UA_TYPES_STATUSCODE => blk: {
                const ptr: [*]const c.UA_StatusCode = @ptrCast(@alignCast(value.data));
                break :blk .{ .status_code_array = ptr[0..value.arrayLength] };
            },
            // Note: String arrays and NodeId arrays need special handling
            // because we can't just slice them - we need to convert each element
            else => error.UnsupportedArrayType,
        };
    }

    /// Free memory allocated by toC()
    pub fn freeCVariant(variant: c.UA_Variant, allocator: std.mem.Allocator) void {
        if (variant.data == null) return;

        const type_index = if (variant.type != null) getTypeIndex(variant.type) else return;

        if (variant.arrayLength > 0) {
            // Array cleanup
            switch (type_index) {
                c.UA_TYPES_STRING => {
                    const ptr: [*]c.UA_String = @ptrCast(@alignCast(variant.data));
                    allocator.free(ptr[0..variant.arrayLength]);
                },
                c.UA_TYPES_NODEID => {
                    const ptr: [*]c.UA_NodeId = @ptrCast(@alignCast(variant.data));
                    allocator.free(ptr[0..variant.arrayLength]);
                },
                else => {
                    // For simple types, we can calculate the size
                    const elem_size = variant.type.*.memSize;
                    const ptr: [*]u8 = @ptrCast(variant.data);
                    allocator.free(ptr[0 .. variant.arrayLength * elem_size]);
                },
            }
        } else {
            // Scalar cleanup - just free the single allocated element
            const elem_size = variant.type.*.memSize;
            const ptr: [*]u8 = @ptrCast(variant.data);
            allocator.free(ptr[0..elem_size]);
        }

        // Free array dimensions if present
        if (variant.arrayDimensionsSize > 0 and variant.arrayDimensions != null) {
            allocator.free(variant.arrayDimensions[0..variant.arrayDimensionsSize]);
        }
    }
};

/// GUID wrapper
pub const Guid = struct {
    data1: u32,
    data2: u16,
    data3: u16,
    data4: [8]u8,

    pub fn fromC(value: c.UA_Guid) Guid {
        return .{
            .data1 = value.data1,
            .data2 = value.data2,
            .data3 = value.data3,
            .data4 = value.data4,
        };
    }

    pub fn toC(self: Guid) c.UA_Guid {
        return .{
            .data1 = self.data1,
            .data2 = self.data2,
            .data3 = self.data3,
            .data4 = self.data4,
        };
    }
};

/// NodeId wrapper (simplified - you'll need to expand this based on your needs)
pub const NodeId = union(enum) {
    numeric: struct {
        namespace_index: u16,
        identifier: u32,
    },
    string: struct {
        namespace_index: u16,
        identifier: []const u8,
    },
    guid: struct {
        namespace_index: u16,
        identifier: Guid,
    },
    byte_string: struct {
        namespace_index: u16,
        identifier: []const u8,
    },

    pub fn fromC(value: c.UA_NodeId) NodeId {
        return switch (value.identifierType) {
            c.UA_NODEIDTYPE_NUMERIC => .{
                .numeric = .{
                    .namespace_index = value.namespaceIndex,
                    .identifier = value.identifier.numeric,
                },
            },
            c.UA_NODEIDTYPE_STRING => .{
                .string = .{
                    .namespace_index = value.namespaceIndex,
                    .identifier = String.fromC(value.identifier.string),
                },
            },
            c.UA_NODEIDTYPE_GUID => .{
                .guid = .{
                    .namespace_index = value.namespaceIndex,
                    .identifier = Guid.fromC(value.identifier.guid),
                },
            },
            c.UA_NODEIDTYPE_BYTESTRING => .{
                .byte_string = .{
                    .namespace_index = value.namespaceIndex,
                    .identifier = String.fromC(value.identifier.byteString),
                },
            },
            else => .{ .numeric = .{ .namespace_index = 0, .identifier = 0 } },
        };
    }

    pub fn toC(self: NodeId) c.UA_NodeId {
        var result: c.UA_NodeId = undefined;
        switch (self) {
            .numeric => |n| {
                result.namespaceIndex = n.namespace_index;
                result.identifierType = c.UA_NODEIDTYPE_NUMERIC;
                result.identifier.numeric = n.identifier;
            },
            .string => |s| {
                result.namespaceIndex = s.namespace_index;
                result.identifierType = c.UA_NODEIDTYPE_STRING;
                result.identifier.string = String.toC(s.identifier);
            },
            .guid => |g| {
                result.namespaceIndex = g.namespace_index;
                result.identifierType = c.UA_NODEIDTYPE_GUID;
                result.identifier.guid = g.identifier.toC();
            },
            .byte_string => |b| {
                result.namespaceIndex = b.namespace_index;
                result.identifierType = c.UA_NODEIDTYPE_BYTESTRING;
                result.identifier.byteString = String.toC(b.identifier);
            },
        }
        return result;
    }
};
