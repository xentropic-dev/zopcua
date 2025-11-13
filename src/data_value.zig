const std = @import("std");
const c = @import("c.zig");
const Variant = @import("variant.zig").Variant;

/// DataValue represents an OPC UA data value with metadata including timestamps and status
pub const DataValue = struct {
    value: Variant,
    source_timestamp: ?i64, // Unix timestamp (seconds since 1970)
    server_timestamp: ?i64, // Unix timestamp (seconds since 1970)
    status_code: u32,

    /// Free allocated memory
    pub fn deinit(self: DataValue, allocator: std.mem.Allocator) void {
        self.value.deinit(allocator);
    }

    /// Convert OPC UA DateTime (100-nanosecond intervals since Jan 1, 1601) to Unix timestamp (seconds since Jan 1, 1970)
    /// Returns null if the OPC UA timestamp is 0 (no timestamp)
    pub fn opcuaDateTimeToUnix(opcua_datetime: i64) ?i64 {
        if (opcua_datetime == 0) return null;
        // OPC UA epoch is Jan 1, 1601
        // Unix epoch is Jan 1, 1970
        // Difference: 11644473600 seconds
        const unix_timestamp = @divFloor(opcua_datetime, 10_000_000) - 11644473600;
        return unix_timestamp;
    }

    /// Convert from C API representation
    pub fn fromC(value: c.UA_DataValue, allocator: std.mem.Allocator) !DataValue {
        const variant = try Variant.fromC(value.value, allocator);

        return .{
            .value = variant,
            .source_timestamp = opcuaDateTimeToUnix(value.sourceTimestamp),
            .server_timestamp = opcuaDateTimeToUnix(value.serverTimestamp),
            .status_code = value.status,
        };
    }
};

test "DataValue timestamp conversion" {
    const testing = std.testing;
    std.testing.refAllDecls(@This());

    // Test zero timestamp (no timestamp)
    try testing.expectEqual(@as(?i64, null), DataValue.opcuaDateTimeToUnix(0));

    // Test known timestamp: Jan 1, 2000 00:00:00 UTC
    // Unix timestamp: 946684800
    // OPC UA timestamp: (946684800 + 11644473600) * 10_000_000 = 125911584000000000
    const opcua_ts: i64 = 125911584000000000;
    const unix_ts = DataValue.opcuaDateTimeToUnix(opcua_ts);
    try testing.expectEqual(@as(?i64, 946684800), unix_ts);

    // Test another known timestamp: Jan 1, 2020 00:00:00 UTC
    // Unix timestamp: 1577836800
    // OPC UA timestamp: (1577836800 + 11644473600) * 10_000_000 = 132223104000000000
    const opcua_ts_2020: i64 = 132223104000000000;
    const unix_ts_2020 = DataValue.opcuaDateTimeToUnix(opcua_ts_2020);
    try testing.expectEqual(@as(?i64, 1577836800), unix_ts_2020);
}
