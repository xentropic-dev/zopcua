const std = @import("std");
const c = @import("c.zig");
const types = @import("types.zig");
const Variant = @import("variant.zig").Variant;

const NodeId = types.NodeId;

/// Subscription configuration parameters
pub const SubscriptionParameters = struct {
    /// Publishing interval in milliseconds
    publishing_interval: f64 = 500.0,
    /// Maximum number of notifications per publish
    max_notifications_per_publish: u32 = 0,
    /// Priority of the subscription (0-255, higher = more important)
    priority: u8 = 0,
    /// Lifetime count (how many publish intervals before timeout)
    lifetime_count: u32 = 10000,
    /// Max keep-alive count
    max_keep_alive_count: u32 = 10,
};

/// Subscription handle - opaque identifier returned by the server
pub const SubscriptionId = u32;

/// Monitored item handle - opaque identifier returned by the server
pub const MonitoredItemId = u32;

/// Monitoring mode for monitored items
pub const MonitoringMode = enum(u32) {
    disabled = c.UA_MONITORINGMODE_DISABLED,
    sampling = c.UA_MONITORINGMODE_SAMPLING,
    reporting = c.UA_MONITORINGMODE_REPORTING,

    pub fn toC(self: MonitoringMode) c.UA_MonitoringMode {
        return @intFromEnum(self);
    }

    pub fn fromC(value: c.UA_MonitoringMode) MonitoringMode {
        return switch (value) {
            c.UA_MONITORINGMODE_DISABLED => .disabled,
            c.UA_MONITORINGMODE_SAMPLING => .sampling,
            c.UA_MONITORINGMODE_REPORTING => .reporting,
            else => .reporting, // Default to reporting for invalid values
        };
    }
};

/// Monitored item configuration for data change notifications
pub const MonitoredItemParameters = struct {
    /// NodeId to monitor
    node_id: NodeId,
    /// Attribute to monitor (usually value attribute)
    attribute_id: u32 = c.UA_ATTRIBUTEID_VALUE,
    /// Sampling interval in milliseconds (0 = server default)
    sampling_interval: f64 = 0.0,
    /// Queue size for notifications
    queue_size: u32 = 1,
    /// Discard oldest notifications when queue is full
    discard_oldest: bool = true,
    /// Monitoring mode
    monitoring_mode: MonitoringMode = .reporting,
};

/// Callback function for data change notifications.
///
/// This callback is invoked when a monitored item's value changes on the server.
/// The variant parameter is only valid during the callback - if you need to keep
/// the data, make a copy using variant.clone().
///
/// **Parameters:**
/// - `userdata`: Optional user context pointer passed during monitored item creation
/// - `subscription_id`: The subscription that contains this monitored item
/// - `monitored_item_id`: The monitored item that triggered this notification
/// - `value`: The new value (valid only during callback)
///
/// **Example:**
/// ```zig
/// fn myCallback(
///     userdata: ?*anyopaque,
///     subscription_id: SubscriptionId,
///     monitored_item_id: MonitoredItemId,
///     value: *const Variant,
/// ) void {
///     const count = @ptrCast(*u32, @alignCast(@alignOf(u32), userdata.?));
///     count.* += 1;
///     std.debug.print("Value changed: {}\n", .{value});
/// }
/// ```
pub const DataChangeCallback = *const fn (
    userdata: ?*anyopaque,
    subscription_id: SubscriptionId,
    monitored_item_id: MonitoredItemId,
    value: *const Variant,
) void;

test "SubscriptionParameters defaults" {
    const testing = std.testing;
    std.testing.refAllDecls(@This());

    const params = SubscriptionParameters{};
    try testing.expectEqual(@as(f64, 500.0), params.publishing_interval);
    try testing.expectEqual(@as(u32, 0), params.max_notifications_per_publish);
    try testing.expectEqual(@as(u8, 0), params.priority);
    try testing.expectEqual(@as(u32, 10000), params.lifetime_count);
    try testing.expectEqual(@as(u32, 10), params.max_keep_alive_count);
}

test "MonitoringMode enum values" {
    const testing = std.testing;

    // Test enum values match C constants
    try testing.expectEqual(@as(u32, c.UA_MONITORINGMODE_DISABLED), @intFromEnum(MonitoringMode.disabled));
    try testing.expectEqual(@as(u32, c.UA_MONITORINGMODE_SAMPLING), @intFromEnum(MonitoringMode.sampling));
    try testing.expectEqual(@as(u32, c.UA_MONITORINGMODE_REPORTING), @intFromEnum(MonitoringMode.reporting));
}

test "MonitoringMode conversion" {
    const testing = std.testing;

    // Test toC/fromC round-trip
    const modes = [_]MonitoringMode{ .disabled, .sampling, .reporting };
    for (modes) |mode| {
        const c_mode = mode.toC();
        const roundtrip = MonitoringMode.fromC(c_mode);
        try testing.expectEqual(mode, roundtrip);
    }

    // Test fromC with invalid value defaults to reporting
    const invalid_roundtrip = MonitoringMode.fromC(999);
    try testing.expectEqual(MonitoringMode.reporting, invalid_roundtrip);
}

test "MonitoredItemParameters defaults" {
    const testing = std.testing;

    const node_id = NodeId.initNumeric(1, 1000);
    const params = MonitoredItemParameters{
        .node_id = node_id,
    };

    try testing.expectEqual(@as(u32, c.UA_ATTRIBUTEID_VALUE), params.attribute_id);
    try testing.expectEqual(@as(f64, 0.0), params.sampling_interval);
    try testing.expectEqual(@as(u32, 1), params.queue_size);
    try testing.expectEqual(true, params.discard_oldest);
    try testing.expectEqual(MonitoringMode.reporting, params.monitoring_mode);
}
