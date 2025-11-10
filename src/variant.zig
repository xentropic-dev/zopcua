const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");
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

    /// Convert to C API representation using open62541's variant initialization functions.
    /// This ensures proper initialization and compatibility with open62541's internal
    /// variant copying and manipulation logic.
    ///
    /// Note: The allocator is used for NodeId string conversions.
    /// open62541's UA_Variant_setScalarCopy and UA_Variant_setArrayCopy
    /// handle memory management internally for the variant data.
    pub fn toC(self: Variant, allocator: std.mem.Allocator) !c.UA_Variant {

        // SAFETY: result is initialized by UA_Variant_init or helper functions before any use
        var result: c.UA_Variant = undefined;

        switch (self) {
            .empty => {
                c.UA_Variant_init(&result);
            },

            // Scalars - use open62541's UA_Variant_setScalarCopy
            .boolean => |val| {
                const status = helpers.helper_variant_setScalarCopy(&result, &val, &c.UA_TYPES[c.UA_TYPES_BOOLEAN]);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .sbyte => |val| {
                const status = helpers.helper_variant_setScalarCopy(&result, &val, &c.UA_TYPES[c.UA_TYPES_SBYTE]);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .byte => |val| {
                const status = helpers.helper_variant_setScalarCopy(&result, &val, &c.UA_TYPES[c.UA_TYPES_BYTE]);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .int16 => |val| {
                const status = helpers.helper_variant_setScalarCopy(&result, &val, &c.UA_TYPES[c.UA_TYPES_INT16]);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .uint16 => |val| {
                const status = helpers.helper_variant_setScalarCopy(&result, &val, &c.UA_TYPES[c.UA_TYPES_UINT16]);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .int32 => |val| {
                const status = helpers.helper_variant_setScalarCopy(&result, &val, &c.UA_TYPES[c.UA_TYPES_INT32]);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .uint32 => |val| {
                const status = helpers.helper_variant_setScalarCopy(&result, &val, &c.UA_TYPES[c.UA_TYPES_UINT32]);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .int64 => |val| {
                const status = helpers.helper_variant_setScalarCopy(&result, &val, &c.UA_TYPES[c.UA_TYPES_INT64]);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .uint64 => |val| {
                const status = helpers.helper_variant_setScalarCopy(&result, &val, &c.UA_TYPES[c.UA_TYPES_UINT64]);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .float => |val| {
                const status = helpers.helper_variant_setScalarCopy(&result, &val, &c.UA_TYPES[c.UA_TYPES_FLOAT]);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .double => |val| {
                const status = helpers.helper_variant_setScalarCopy(&result, &val, &c.UA_TYPES[c.UA_TYPES_DOUBLE]);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .string => |val| {
                const c_string = String.toC(val);
                const status = helpers.helper_variant_setScalarCopy(&result, &c_string, &c.UA_TYPES[c.UA_TYPES_STRING]);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .date_time => |val| {
                const status = helpers.helper_variant_setScalarCopy(&result, &val, &c.UA_TYPES[c.UA_TYPES_DATETIME]);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .guid => |val| {
                const c_guid = val.toC();
                const status = helpers.helper_variant_setScalarCopy(&result, &c_guid, &c.UA_TYPES[c.UA_TYPES_GUID]);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .byte_string => |val| {
                const c_bytestring = String.toC(val);
                const bytestring_type = &c.UA_TYPES[c.UA_TYPES_BYTESTRING];
                const status = helpers.helper_variant_setScalarCopy(&result, &c_bytestring, bytestring_type);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .node_id => |val| {
                const c_nodeid = try val.toC(allocator);
                defer val.freeToC(allocator, c_nodeid);
                const status = helpers.helper_variant_setScalarCopy(&result, &c_nodeid, &c.UA_TYPES[c.UA_TYPES_NODEID]);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .status_code => |val| {
                const status = helpers.helper_variant_setScalarCopy(&result, &val, &c.UA_TYPES[c.UA_TYPES_STATUSCODE]);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .localized_text => |val| {
                const c_localizedtext = val.toC();
                const localizedtext_type = &c.UA_TYPES[c.UA_TYPES_LOCALIZEDTEXT];
                const status = helpers.helper_variant_setScalarCopy(&result, &c_localizedtext, localizedtext_type);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            // Arrays - use open62541's UA_Variant_setArrayCopy
            .boolean_array => |values| {
                const bool_type = &c.UA_TYPES[c.UA_TYPES_BOOLEAN];
                const status = helpers.helper_variant_setArrayCopy(&result, values.ptr, values.len, bool_type);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .sbyte_array => |values| {
                const sbyte_type = &c.UA_TYPES[c.UA_TYPES_SBYTE];
                const status = helpers.helper_variant_setArrayCopy(&result, values.ptr, values.len, sbyte_type);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .byte_array => |values| {
                const byte_type = &c.UA_TYPES[c.UA_TYPES_BYTE];
                const status = helpers.helper_variant_setArrayCopy(&result, values.ptr, values.len, byte_type);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .int16_array => |values| {
                const int16_type = &c.UA_TYPES[c.UA_TYPES_INT16];
                const status = helpers.helper_variant_setArrayCopy(&result, values.ptr, values.len, int16_type);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .uint16_array => |values| {
                const uint16_type = &c.UA_TYPES[c.UA_TYPES_UINT16];
                const status = helpers.helper_variant_setArrayCopy(&result, values.ptr, values.len, uint16_type);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .int32_array => |values| {
                const int32_type = &c.UA_TYPES[c.UA_TYPES_INT32];
                const status = helpers.helper_variant_setArrayCopy(&result, values.ptr, values.len, int32_type);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .uint32_array => |values| {
                const uint32_type = &c.UA_TYPES[c.UA_TYPES_UINT32];
                const status = helpers.helper_variant_setArrayCopy(&result, values.ptr, values.len, uint32_type);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .int64_array => |values| {
                const int64_type = &c.UA_TYPES[c.UA_TYPES_INT64];
                const status = helpers.helper_variant_setArrayCopy(&result, values.ptr, values.len, int64_type);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .uint64_array => |values| {
                const uint64_type = &c.UA_TYPES[c.UA_TYPES_UINT64];
                const status = helpers.helper_variant_setArrayCopy(&result, values.ptr, values.len, uint64_type);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .float_array => |values| {
                const float_type = &c.UA_TYPES[c.UA_TYPES_FLOAT];
                const status = helpers.helper_variant_setArrayCopy(&result, values.ptr, values.len, float_type);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .double_array => |values| {
                const double_type = &c.UA_TYPES[c.UA_TYPES_DOUBLE];
                const status = helpers.helper_variant_setArrayCopy(&result, values.ptr, values.len, double_type);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .string_array => |values| {
                // Need to convert each string to C format first
                // This is more complex - we need temporary storage
                // For now, fall back to manual construction
                c.UA_Variant_init(&result);
                result.type = &c.UA_TYPES[c.UA_TYPES_STRING];
                // TODO: This needs proper implementation with temp allocator
                result.arrayLength = values.len;
                return error.StringArrayNotYetSupported;
            },

            .date_time_array => |values| {
                const datetime_type = &c.UA_TYPES[c.UA_TYPES_DATETIME];
                const status = helpers.helper_variant_setArrayCopy(&result, values.ptr, values.len, datetime_type);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
            },

            .node_id_array => |values| {
                // Similar to string_array - needs conversion first
                c.UA_Variant_init(&result);
                result.type = &c.UA_TYPES[c.UA_TYPES_NODEID];
                result.arrayLength = values.len;
                return error.NodeIdArrayNotYetSupported;
            },

            .status_code_array => |values| {
                const statuscode_type = &c.UA_TYPES[c.UA_TYPES_STATUSCODE];
                const status = helpers.helper_variant_setArrayCopy(&result, values.ptr, values.len, statuscode_type);
                if (status != c.UA_STATUSCODE_GOOD) return error.VariantInitFailed;
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
                const src = LocalizedText.fromC(ptr.*);
                // Deep copy the locale and text strings
                const owned_locale = try allocator.dupe(u8, src.locale);
                const owned_text = try allocator.dupe(u8, src.text);
                break :blk .{ .localized_text = .{
                    .locale = owned_locale,
                    .text = owned_text,
                } };
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
            .localized_text => |lt| {
                allocator.free(lt.locale);
                allocator.free(lt.text);
            },

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
            .boolean,
            .sbyte,
            .byte,
            .int16,
            .uint16,
            .int32,
            .uint32,
            .int64,
            .uint64,
            .float,
            .double,
            .date_time,
            .guid,
            .node_id,
            .status_code,
            => {},
        }
    }

    /// Free memory allocated by toC()
    ///
    /// Since toC() now uses open62541's UA_Variant_setScalarCopy and UA_Variant_setArrayCopy,
    /// we must use open62541's UA_Variant_clear() to properly free the memory.
    pub fn freeCVariant(allocator: std.mem.Allocator, variant: c.UA_Variant) void {
        _ = allocator; // No longer used - open62541 manages memory
        c.UA_Variant_clear(@constCast(&variant));
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
    std.testing.refAllDecls(@This());
    const allocator = testing.allocator;

    const variant = Variant.scalar(i32, 42);
    try testing.expectEqual(@as(i32, 42), variant.int32);

    const c_variant = try variant.toC(allocator);
    defer Variant.freeCVariant(allocator, c_variant);

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
    defer Variant.freeCVariant(allocator, c_variant);

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
    defer Variant.freeCVariant(allocator, c_variant);

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
    defer Variant.freeCVariant(allocator, c_variant);

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
    defer Variant.freeCVariant(allocator, c_variant);

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
    defer Variant.freeCVariant(allocator, c_variant);

    const roundtrip = try Variant.fromC(c_variant, allocator);
    defer roundtrip.deinit(allocator);
    try testing.expectEqualSlices(f64, &values, roundtrip.double_array);
}

test "Variant empty" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const variant = Variant{ .empty = {} };
    const c_variant = try variant.toC(allocator);
    defer Variant.freeCVariant(allocator, c_variant);

    try testing.expect(c_variant.type == null or c_variant.data == null);
}

test "Variant scalar u32" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const variant = Variant.scalar(u32, 12345);
    try testing.expectEqual(@as(u32, 12345), variant.uint32);

    const c_variant = try variant.toC(allocator);
    defer Variant.freeCVariant(allocator, c_variant);

    const roundtrip = try Variant.fromC(c_variant, allocator);
    defer roundtrip.deinit(allocator);
    try testing.expectEqual(@as(u32, 12345), roundtrip.uint32);
}

test "Variant scalar i64" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const variant = Variant.scalar(i64, -9876543210);
    try testing.expectEqual(@as(i64, -9876543210), variant.int64);

    const c_variant = try variant.toC(allocator);
    defer Variant.freeCVariant(allocator, c_variant);

    const roundtrip = try Variant.fromC(c_variant, allocator);
    defer roundtrip.deinit(allocator);
    try testing.expectEqual(@as(i64, -9876543210), roundtrip.int64);
}

test "Variant scalar guid" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const guid = Guid{
        .data1 = 0x12345678,
        .data2 = 0x9ABC,
        .data3 = 0xDEF0,
        .data4 = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8 },
    };
    const variant = Variant{ .guid = guid };
    try testing.expectEqual(guid.data1, variant.guid.data1);

    const c_variant = try variant.toC(allocator);
    defer Variant.freeCVariant(allocator, c_variant);

    const roundtrip = try Variant.fromC(c_variant, allocator);
    defer roundtrip.deinit(allocator);
    try testing.expectEqual(guid.data1, roundtrip.guid.data1);
    try testing.expectEqualSlices(u8, &guid.data4, &roundtrip.guid.data4);
}

test "Variant scalar LocalizedText" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const localized = LocalizedText.init("en-US", "Temperature");
    const variant = Variant.scalar(LocalizedText, localized);
    try testing.expectEqualStrings("en-US", variant.localized_text.locale);
    try testing.expectEqualStrings("Temperature", variant.localized_text.text);

    const c_variant = try variant.toC(allocator);
    defer Variant.freeCVariant(allocator, c_variant);

    const roundtrip = try Variant.fromC(c_variant, allocator);
    defer roundtrip.deinit(allocator);
    try testing.expectEqualStrings("en-US", roundtrip.localized_text.locale);
    try testing.expectEqualStrings("Temperature", roundtrip.localized_text.text);
}

test "Variant scalar NodeId" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const node_id = NodeId.initNumeric(1, 1000);
    const variant = Variant.scalar(NodeId, node_id);
    try testing.expectEqual(@as(u16, 1), variant.node_id.numeric.namespace);
    try testing.expectEqual(@as(u32, 1000), variant.node_id.numeric.identifier);

    const c_variant = try variant.toC(allocator);
    defer Variant.freeCVariant(allocator, c_variant);

    const roundtrip = try Variant.fromC(c_variant, allocator);
    defer roundtrip.deinit(allocator);
    try testing.expectEqual(@as(u16, 1), roundtrip.node_id.numeric.namespace);
    try testing.expectEqual(@as(u32, 1000), roundtrip.node_id.numeric.identifier);
}

test "Variant array with zero elements" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const empty_array: [0]i32 = .{};
    const variant = Variant.array(i32, &empty_array);
    try testing.expectEqual(@as(usize, 0), variant.int32_array.len);

    const c_variant = try variant.toC(allocator);
    defer Variant.freeCVariant(allocator, c_variant);

    // Zero-length arrays may come back as empty variant from C
    // Don't try to round-trip as the C library may not handle this case consistently
    try testing.expect(c_variant.arrayLength == 0 or c_variant.data == null);
}

test "Variant dataTypeNodeId for scalar types" {
    const testing = std.testing;

    const int_variant = Variant.scalar(i32, 42);
    const int_type = int_variant.dataTypeNodeId();
    const expected_int_type: u32 = c.UA_TYPES[c.UA_TYPES_INT32].typeId.identifier.numeric;
    try testing.expectEqual(expected_int_type, int_type.numeric.identifier);

    const bool_variant = Variant.scalar(bool, true);
    const bool_type = bool_variant.dataTypeNodeId();
    const expected_bool_type: u32 = c.UA_TYPES[c.UA_TYPES_BOOLEAN].typeId.identifier.numeric;
    try testing.expectEqual(expected_bool_type, bool_type.numeric.identifier);

    const string_variant = Variant.scalar([]const u8, "test");
    const string_type = string_variant.dataTypeNodeId();
    const expected_string_type: u32 = c.UA_TYPES[c.UA_TYPES_STRING].typeId.identifier.numeric;
    try testing.expectEqual(expected_string_type, string_type.numeric.identifier);

    const double_variant = Variant.scalar(f64, 3.14);
    const double_type = double_variant.dataTypeNodeId();
    const expected_double_type: u32 = c.UA_TYPES[c.UA_TYPES_DOUBLE].typeId.identifier.numeric;
    try testing.expectEqual(expected_double_type, double_type.numeric.identifier);
}

test "Variant dataTypeNodeId for array types" {
    const testing = std.testing;

    const int_array = [_]i32{ 1, 2, 3 };
    const array_variant = Variant.array(i32, &int_array);
    const array_type = array_variant.dataTypeNodeId();
    const expected_array_type: u32 = c.UA_TYPES[c.UA_TYPES_INT32].typeId.identifier.numeric;
    try testing.expectEqual(expected_array_type, array_type.numeric.identifier);

    const bool_array = [_]bool{ true, false };
    const bool_variant = Variant.array(bool, &bool_array);
    const bool_type = bool_variant.dataTypeNodeId();
    const expected_bool_array_type: u32 = c.UA_TYPES[c.UA_TYPES_BOOLEAN].typeId.identifier.numeric;
    try testing.expectEqual(expected_bool_array_type, bool_type.numeric.identifier);
}

test "Variant dataTypeNodeId for empty variant" {
    const testing = std.testing;

    const empty_variant = Variant{ .empty = {} };
    const empty_type = empty_variant.dataTypeNodeId();
    try testing.expectEqual(NodeId.null_id.numeric.namespace, empty_type.numeric.namespace);
    try testing.expectEqual(NodeId.null_id.numeric.identifier, empty_type.numeric.identifier);
}
