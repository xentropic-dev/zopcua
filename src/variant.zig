const std = @import("std");
const c = @import("c.zig");
const types = @import("types.zig");
const localized_text = @import("localized_text.zig");

// Use NodeId from types.zig
const NodeId = types.NodeId;
const Guid = types.Guid;
const LocalizedText = localized_text.LocalizedText;
const String = localized_text.String;

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

        // arrayDimensions and arrayDimensionsSize remain 0 and NULL from zeroes for scalars
        // This is correct per OPC UA spec - arrays will override these in the switch statement

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
                // storageType remains 0 (UA_VARIANT_DATA) from zeroes
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

    /// Convert from C API representation, deep-copying all data
    ///
    /// This function allocates memory for all variant data using the provided allocator.
    /// The caller owns the returned Variant and must call deinit() to free the memory.
    ///
    /// The original C variant is not modified and remains the caller's responsibility
    /// to clean up (e.g., with UA_Variant_clear if it was allocated by the C library).
    pub fn fromC(value: c.UA_Variant, allocator: std.mem.Allocator) !Variant {
        if (value.type == null or value.data == null) return .empty;

        const type_index = getTypeIndex(value.type);
        const is_array = value.arrayLength > 0;

        if (is_array) {
            return fromCArray(value, type_index, allocator) catch .{ .raw = value };
        } else {
            return fromCScalar(value, type_index, allocator) catch .{ .raw = value };
        }
    }

    fn getTypeIndex(data_type: [*c]const c.UA_DataType) usize {
        const offset = @intFromPtr(data_type) - @intFromPtr(&c.UA_TYPES[0]);
        return offset / @sizeOf(c.UA_DataType);
    }

    fn fromCScalar(value: c.UA_Variant, type_index: usize, allocator: std.mem.Allocator) !Variant {
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
                const src = String.fromC(ptr.*);
                // Deep copy the string
                const owned = try allocator.dupe(u8, src);
                break :blk .{ .string = owned };
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
                const src = String.fromC(ptr.*);
                // Deep copy the byte string
                const owned = try allocator.dupe(u8, src);
                break :blk .{ .byte_string = owned };
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

    fn fromCArray(value: c.UA_Variant, type_index: usize, allocator: std.mem.Allocator) !Variant {
        return switch (type_index) {
            c.UA_TYPES_BOOLEAN => blk: {
                const ptr: [*]const c.UA_Boolean = @ptrCast(@alignCast(value.data));
                const src = ptr[0..value.arrayLength];
                // Deep copy the array
                const owned = try allocator.dupe(bool, src);
                break :blk .{ .boolean_array = owned };
            },
            c.UA_TYPES_SBYTE => blk: {
                const ptr: [*]const c.UA_SByte = @ptrCast(@alignCast(value.data));
                const src = ptr[0..value.arrayLength];
                const owned = try allocator.dupe(i8, src);
                break :blk .{ .sbyte_array = owned };
            },
            c.UA_TYPES_BYTE => blk: {
                const ptr: [*]const c.UA_Byte = @ptrCast(@alignCast(value.data));
                const src = ptr[0..value.arrayLength];
                const owned = try allocator.dupe(u8, src);
                break :blk .{ .byte_array = owned };
            },
            c.UA_TYPES_INT16 => blk: {
                const ptr: [*]const c.UA_Int16 = @ptrCast(@alignCast(value.data));
                const src = ptr[0..value.arrayLength];
                const owned = try allocator.dupe(i16, src);
                break :blk .{ .int16_array = owned };
            },
            c.UA_TYPES_UINT16 => blk: {
                const ptr: [*]const c.UA_UInt16 = @ptrCast(@alignCast(value.data));
                const src = ptr[0..value.arrayLength];
                const owned = try allocator.dupe(u16, src);
                break :blk .{ .uint16_array = owned };
            },
            c.UA_TYPES_INT32 => blk: {
                const ptr: [*]const c.UA_Int32 = @ptrCast(@alignCast(value.data));
                const src = ptr[0..value.arrayLength];
                const owned = try allocator.dupe(i32, src);
                break :blk .{ .int32_array = owned };
            },
            c.UA_TYPES_UINT32 => blk: {
                const ptr: [*]const c.UA_UInt32 = @ptrCast(@alignCast(value.data));
                const src = ptr[0..value.arrayLength];
                const owned = try allocator.dupe(u32, src);
                break :blk .{ .uint32_array = owned };
            },
            c.UA_TYPES_INT64 => blk: {
                const ptr: [*]const c.UA_Int64 = @ptrCast(@alignCast(value.data));
                const src = ptr[0..value.arrayLength];
                const owned = try allocator.dupe(i64, src);
                break :blk .{ .int64_array = owned };
            },
            c.UA_TYPES_UINT64 => blk: {
                const ptr: [*]const c.UA_UInt64 = @ptrCast(@alignCast(value.data));
                const src = ptr[0..value.arrayLength];
                const owned = try allocator.dupe(u64, src);
                break :blk .{ .uint64_array = owned };
            },
            c.UA_TYPES_FLOAT => blk: {
                const ptr: [*]const c.UA_Float = @ptrCast(@alignCast(value.data));
                const src = ptr[0..value.arrayLength];
                const owned = try allocator.dupe(f32, src);
                break :blk .{ .float_array = owned };
            },
            c.UA_TYPES_DOUBLE => blk: {
                const ptr: [*]const c.UA_Double = @ptrCast(@alignCast(value.data));
                const src = ptr[0..value.arrayLength];
                const owned = try allocator.dupe(f64, src);
                break :blk .{ .double_array = owned };
            },
            c.UA_TYPES_DATETIME => blk: {
                const ptr: [*]const c.UA_DateTime = @ptrCast(@alignCast(value.data));
                const src = ptr[0..value.arrayLength];
                const owned = try allocator.dupe(i64, src);
                break :blk .{ .date_time_array = owned };
            },
            c.UA_TYPES_STATUSCODE => blk: {
                const ptr: [*]const c.UA_StatusCode = @ptrCast(@alignCast(value.data));
                const src = ptr[0..value.arrayLength];
                const owned = try allocator.dupe(u32, src);
                break :blk .{ .status_code_array = owned };
            },
            // Note: String arrays and NodeId arrays need special handling
            // because we can't just slice them - we need to convert each element
            else => error.UnsupportedArrayType,
        };
    }

    /// Free memory allocated by fromC()
    ///
    /// Call this when done with a Variant created by fromC() to free the deep-copied data.
    /// Note: Do not call this for Variants created by scalar() or array() helpers unless
    /// the data was separately heap-allocated.
    pub fn deinit(self: Variant, allocator: std.mem.Allocator) void {
        switch (self) {
            .empty, .raw => {},

            // Scalars that own heap memory
            .string => |s| allocator.free(s),
            .byte_string => |s| allocator.free(s),

            // Arrays that own heap memory
            .boolean_array => |a| allocator.free(a),
            .sbyte_array => |a| allocator.free(a),
            .byte_array => |a| allocator.free(a),
            .int16_array => |a| allocator.free(a),
            .uint16_array => |a| allocator.free(a),
            .int32_array => |a| allocator.free(a),
            .uint32_array => |a| allocator.free(a),
            .int64_array => |a| allocator.free(a),
            .uint64_array => |a| allocator.free(a),
            .float_array => |a| allocator.free(a),
            .double_array => |a| allocator.free(a),
            .date_time_array => |a| allocator.free(a),
            .status_code_array => |a| allocator.free(a),
            .string_array => |a| allocator.free(a),
            .node_id_array => |a| allocator.free(a),

            // Scalars that don't own heap memory (stack values)
            .boolean, .sbyte, .byte, .int16, .uint16, .int32, .uint32,
            .int64, .uint64, .float, .double, .date_time, .guid,
            .node_id, .status_code, .localized_text => {},
        }
    }

    /// Free memory allocated by toC()
    pub fn freeCVariant(variant: c.UA_Variant, allocator: std.mem.Allocator) void {
        if (variant.data == null) return;

        const type_index = if (variant.type != null) getTypeIndex(variant.type) else return;

        if (variant.arrayLength > 0) {
            // Array cleanup - use the proper type for deallocation
            switch (type_index) {
                c.UA_TYPES_BOOLEAN => {
                    const ptr: [*]c.UA_Boolean = @ptrCast(@alignCast(variant.data));
                    allocator.free(ptr[0..variant.arrayLength]);
                },
                c.UA_TYPES_SBYTE => {
                    const ptr: [*]c.UA_SByte = @ptrCast(@alignCast(variant.data));
                    allocator.free(ptr[0..variant.arrayLength]);
                },
                c.UA_TYPES_BYTE => {
                    const ptr: [*]c.UA_Byte = @ptrCast(@alignCast(variant.data));
                    allocator.free(ptr[0..variant.arrayLength]);
                },
                c.UA_TYPES_INT16 => {
                    const ptr: [*]c.UA_Int16 = @ptrCast(@alignCast(variant.data));
                    allocator.free(ptr[0..variant.arrayLength]);
                },
                c.UA_TYPES_UINT16 => {
                    const ptr: [*]c.UA_UInt16 = @ptrCast(@alignCast(variant.data));
                    allocator.free(ptr[0..variant.arrayLength]);
                },
                c.UA_TYPES_INT32 => {
                    const ptr: [*]c.UA_Int32 = @ptrCast(@alignCast(variant.data));
                    allocator.free(ptr[0..variant.arrayLength]);
                },
                c.UA_TYPES_UINT32 => {
                    const ptr: [*]c.UA_UInt32 = @ptrCast(@alignCast(variant.data));
                    allocator.free(ptr[0..variant.arrayLength]);
                },
                c.UA_TYPES_INT64 => {
                    const ptr: [*]c.UA_Int64 = @ptrCast(@alignCast(variant.data));
                    allocator.free(ptr[0..variant.arrayLength]);
                },
                c.UA_TYPES_UINT64 => {
                    const ptr: [*]c.UA_UInt64 = @ptrCast(@alignCast(variant.data));
                    allocator.free(ptr[0..variant.arrayLength]);
                },
                c.UA_TYPES_FLOAT => {
                    const ptr: [*]c.UA_Float = @ptrCast(@alignCast(variant.data));
                    allocator.free(ptr[0..variant.arrayLength]);
                },
                c.UA_TYPES_DOUBLE => {
                    const ptr: [*]c.UA_Double = @ptrCast(@alignCast(variant.data));
                    allocator.free(ptr[0..variant.arrayLength]);
                },
                c.UA_TYPES_STRING => {
                    const ptr: [*]c.UA_String = @ptrCast(@alignCast(variant.data));
                    allocator.free(ptr[0..variant.arrayLength]);
                },
                c.UA_TYPES_DATETIME => {
                    const ptr: [*]c.UA_DateTime = @ptrCast(@alignCast(variant.data));
                    allocator.free(ptr[0..variant.arrayLength]);
                },
                c.UA_TYPES_NODEID => {
                    const ptr: [*]c.UA_NodeId = @ptrCast(@alignCast(variant.data));
                    allocator.free(ptr[0..variant.arrayLength]);
                },
                c.UA_TYPES_STATUSCODE => {
                    const ptr: [*]c.UA_StatusCode = @ptrCast(@alignCast(variant.data));
                    allocator.free(ptr[0..variant.arrayLength]);
                },
                else => {}, // Unknown type, skip cleanup
            }
        } else {
            // Scalar cleanup - use destroy() instead of free()
            switch (type_index) {
                c.UA_TYPES_BOOLEAN => {
                    const ptr: *c.UA_Boolean = @ptrCast(@alignCast(variant.data));
                    allocator.destroy(ptr);
                },
                c.UA_TYPES_SBYTE => {
                    const ptr: *c.UA_SByte = @ptrCast(@alignCast(variant.data));
                    allocator.destroy(ptr);
                },
                c.UA_TYPES_BYTE => {
                    const ptr: *c.UA_Byte = @ptrCast(@alignCast(variant.data));
                    allocator.destroy(ptr);
                },
                c.UA_TYPES_INT16 => {
                    const ptr: *c.UA_Int16 = @ptrCast(@alignCast(variant.data));
                    allocator.destroy(ptr);
                },
                c.UA_TYPES_UINT16 => {
                    const ptr: *c.UA_UInt16 = @ptrCast(@alignCast(variant.data));
                    allocator.destroy(ptr);
                },
                c.UA_TYPES_INT32 => {
                    const ptr: *c.UA_Int32 = @ptrCast(@alignCast(variant.data));
                    allocator.destroy(ptr);
                },
                c.UA_TYPES_UINT32 => {
                    const ptr: *c.UA_UInt32 = @ptrCast(@alignCast(variant.data));
                    allocator.destroy(ptr);
                },
                c.UA_TYPES_INT64 => {
                    const ptr: *c.UA_Int64 = @ptrCast(@alignCast(variant.data));
                    allocator.destroy(ptr);
                },
                c.UA_TYPES_UINT64 => {
                    const ptr: *c.UA_UInt64 = @ptrCast(@alignCast(variant.data));
                    allocator.destroy(ptr);
                },
                c.UA_TYPES_FLOAT => {
                    const ptr: *c.UA_Float = @ptrCast(@alignCast(variant.data));
                    allocator.destroy(ptr);
                },
                c.UA_TYPES_DOUBLE => {
                    const ptr: *c.UA_Double = @ptrCast(@alignCast(variant.data));
                    allocator.destroy(ptr);
                },
                c.UA_TYPES_STRING => {
                    const ptr: *c.UA_String = @ptrCast(@alignCast(variant.data));
                    allocator.destroy(ptr);
                },
                c.UA_TYPES_DATETIME => {
                    const ptr: *c.UA_DateTime = @ptrCast(@alignCast(variant.data));
                    allocator.destroy(ptr);
                },
                c.UA_TYPES_GUID => {
                    const ptr: *c.UA_Guid = @ptrCast(@alignCast(variant.data));
                    allocator.destroy(ptr);
                },
                c.UA_TYPES_BYTESTRING => {
                    const ptr: *c.UA_ByteString = @ptrCast(@alignCast(variant.data));
                    allocator.destroy(ptr);
                },
                c.UA_TYPES_NODEID => {
                    const ptr: *c.UA_NodeId = @ptrCast(@alignCast(variant.data));
                    allocator.destroy(ptr);
                },
                c.UA_TYPES_STATUSCODE => {
                    const ptr: *c.UA_StatusCode = @ptrCast(@alignCast(variant.data));
                    allocator.destroy(ptr);
                },
                c.UA_TYPES_LOCALIZEDTEXT => {
                    const ptr: *c.UA_LocalizedText = @ptrCast(@alignCast(variant.data));
                    allocator.destroy(ptr);
                },
                else => {}, // Unknown type, skip cleanup
            }
        }

        // Free array dimensions if present
        if (variant.arrayDimensions != null and variant.arrayDimensionsSize > 0) {
            allocator.free(variant.arrayDimensions[0..variant.arrayDimensionsSize]);
        }
    }
    pub fn dataTypeNodeId(self: Variant) NodeId {
        return switch (self) {
            .boolean, .boolean_array => NodeId.initNumeric(0, c.UA_TYPES[c.UA_TYPES_BOOLEAN].typeId.identifier.numeric),
            .int32, .int32_array => NodeId.initNumeric(0, c.UA_TYPES[c.UA_TYPES_INT32].typeId.identifier.numeric),
            .uint32, .uint32_array => NodeId.initNumeric(0, c.UA_TYPES[c.UA_TYPES_UINT32].typeId.identifier.numeric),
            .double, .double_array => NodeId.initNumeric(0, c.UA_TYPES[c.UA_TYPES_DOUBLE].typeId.identifier.numeric),
            .float, .float_array => NodeId.initNumeric(0, c.UA_TYPES[c.UA_TYPES_FLOAT].typeId.identifier.numeric),
            .string, .string_array => NodeId.initNumeric(0, c.UA_TYPES[c.UA_TYPES_STRING].typeId.identifier.numeric),
            .int64, .int64_array => NodeId.initNumeric(0, c.UA_TYPES[c.UA_TYPES_INT64].typeId.identifier.numeric),
            .uint64, .uint64_array => NodeId.initNumeric(0, c.UA_TYPES[c.UA_TYPES_UINT64].typeId.identifier.numeric),
            .byte, .byte_array => NodeId.initNumeric(0, c.UA_TYPES[c.UA_TYPES_BYTE].typeId.identifier.numeric),
            .sbyte, .sbyte_array => NodeId.initNumeric(0, c.UA_TYPES[c.UA_TYPES_SBYTE].typeId.identifier.numeric),
            .int16, .int16_array => NodeId.initNumeric(0, c.UA_TYPES[c.UA_TYPES_INT16].typeId.identifier.numeric),
            .uint16, .uint16_array => NodeId.initNumeric(0, c.UA_TYPES[c.UA_TYPES_UINT16].typeId.identifier.numeric),
            .date_time, .date_time_array => NodeId.initNumeric(
                0,
                c.UA_TYPES[c.UA_TYPES_DATETIME].typeId.identifier.numeric,
            ),
            .guid => NodeId.initNumeric(0, c.UA_TYPES[c.UA_TYPES_GUID].typeId.identifier.numeric),
            .byte_string => NodeId.initNumeric(0, c.UA_TYPES[c.UA_TYPES_BYTESTRING].typeId.identifier.numeric),
            .node_id, .node_id_array => NodeId.initNumeric(0, c.UA_TYPES[c.UA_TYPES_NODEID].typeId.identifier.numeric),
            .status_code, .status_code_array => NodeId.initNumeric(
                0,
                c.UA_TYPES[c.UA_TYPES_STATUSCODE].typeId.identifier.numeric,
            ),
            .localized_text => NodeId.initNumeric(0, c.UA_TYPES[c.UA_TYPES_LOCALIZEDTEXT].typeId.identifier.numeric),
            .empty, .raw => NodeId.null_id,
        };
    }
};

test "Variant scalar i32" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const variant = Variant.scalar(i32, 42);
    try testing.expectEqual(@as(i32, 42), variant.int32);

    const c_variant = try variant.toC(allocator);
    defer Variant.freeCVariant(c_variant, allocator);

    const roundtrip = try Variant.fromC(c_variant, allocator);
    defer roundtrip.deinit(allocator);
    try testing.expectEqual(@as(i32, 42), roundtrip.int32);
}

test "Variant scalar f64" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const variant = Variant.scalar(f64, 3.14159);
    try testing.expectEqual(@as(f64, 3.14159), variant.double);

    const c_variant = try variant.toC(allocator);
    defer Variant.freeCVariant(c_variant, allocator);

    const roundtrip = try Variant.fromC(c_variant, allocator);
    defer roundtrip.deinit(allocator);
    try testing.expectEqual(@as(f64, 3.14159), roundtrip.double);
}

test "Variant scalar bool" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const variant = Variant.scalar(bool, true);
    try testing.expectEqual(true, variant.boolean);

    const c_variant = try variant.toC(allocator);
    defer Variant.freeCVariant(c_variant, allocator);

    const roundtrip = try Variant.fromC(c_variant, allocator);
    defer roundtrip.deinit(allocator);
    try testing.expectEqual(true, roundtrip.boolean);
}

test "Variant scalar string" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const variant = Variant.scalar([]const u8, "Hello, OPC UA!");
    try testing.expectEqualStrings("Hello, OPC UA!", variant.string);

    const c_variant = try variant.toC(allocator);
    defer Variant.freeCVariant(c_variant, allocator);

    const roundtrip = try Variant.fromC(c_variant, allocator);
    defer roundtrip.deinit(allocator);
    try testing.expectEqualStrings("Hello, OPC UA!", roundtrip.string);
}

test "Variant array i32" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const values = [_]i32{ 1, 2, 3, 4, 5 };
    const variant = Variant.array(i32, &values);
    try testing.expectEqualSlices(i32, &values, variant.int32_array);

    const c_variant = try variant.toC(allocator);
    defer Variant.freeCVariant(c_variant, allocator);

    const roundtrip = try Variant.fromC(c_variant, allocator);
    defer roundtrip.deinit(allocator);
    try testing.expectEqualSlices(i32, &values, roundtrip.int32_array);
}

test "Variant array f64" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const values = [_]f64{ 1.1, 2.2, 3.3 };
    const variant = Variant.array(f64, &values);
    try testing.expectEqualSlices(f64, &values, variant.double_array);

    const c_variant = try variant.toC(allocator);
    defer Variant.freeCVariant(c_variant, allocator);

    const roundtrip = try Variant.fromC(c_variant, allocator);
    defer roundtrip.deinit(allocator);
    try testing.expectEqualSlices(f64, &values, roundtrip.double_array);
}

test "Variant empty" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const variant = Variant{ .empty = {} };
    const c_variant = try variant.toC(allocator);
    defer Variant.freeCVariant(c_variant, allocator);

    try testing.expect(c_variant.type == null or c_variant.data == null);
}
