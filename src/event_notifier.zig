const std = @import("std");
const c = @import("c.zig");

/// EventNotifier indicates if the node can be used to subscribe to events or to
/// read/write the historical events.
pub const EventNotifier = packed struct {
    /// Subscribe to events
    subscribe_to_events: bool = false,
    /// Reserved bit (unused)
    _reserved1: bool = false,
    /// Read historical events
    history_read: bool = false,
    /// Write historical events
    history_write: bool = false,
    /// Reserved bits (unused)
    _reserved2: u4 = 0,

    /// No event notifier capabilities
    pub const none = EventNotifier{};

    /// Convert to C API representation
    pub fn toC(self: EventNotifier) u8 {
        return @bitCast(self);
    }

    /// Convert from C API representation
    pub fn fromC(value: u8) EventNotifier {
        return @bitCast(value);
    }
};

// ============================================================================
// Tests
// ============================================================================

test "EventNotifier none" {
    const testing = std.testing;
    std.testing.refAllDecls(@This());

    const notifier = EventNotifier.none;
    try testing.expectEqual(false, notifier.subscribe_to_events);
    try testing.expectEqual(false, notifier.history_read);
    try testing.expectEqual(false, notifier.history_write);

    const c_notifier = notifier.toC();
    try testing.expectEqual(@as(u8, 0), c_notifier);
}

test "EventNotifier subscribe_to_events" {
    const testing = std.testing;

    const notifier = EventNotifier{ .subscribe_to_events = true };
    try testing.expectEqual(true, notifier.subscribe_to_events);

    const c_notifier = notifier.toC();
    try testing.expectEqual(@as(u8, c.UA_EVENTNOTIFIERTYPE_SUBSCRIBETOEVENTS), c_notifier);

    const roundtrip = EventNotifier.fromC(c_notifier);
    try testing.expectEqual(notifier.subscribe_to_events, roundtrip.subscribe_to_events);
}

test "EventNotifier history_read" {
    const testing = std.testing;

    const notifier = EventNotifier{ .history_read = true };
    try testing.expectEqual(true, notifier.history_read);

    const c_notifier = notifier.toC();
    try testing.expectEqual(@as(u8, c.UA_EVENTNOTIFIERTYPE_HISTORYREAD), c_notifier);

    const roundtrip = EventNotifier.fromC(c_notifier);
    try testing.expectEqual(notifier.history_read, roundtrip.history_read);
}

test "EventNotifier history_write" {
    const testing = std.testing;

    const notifier = EventNotifier{ .history_write = true };
    try testing.expectEqual(true, notifier.history_write);

    const c_notifier = notifier.toC();
    try testing.expectEqual(@as(u8, c.UA_EVENTNOTIFIERTYPE_HISTORYWRITE), c_notifier);

    const roundtrip = EventNotifier.fromC(c_notifier);
    try testing.expectEqual(notifier.history_write, roundtrip.history_write);
}

test "EventNotifier combined flags" {
    const testing = std.testing;

    const notifier = EventNotifier{
        .subscribe_to_events = true,
        .history_read = true,
    };

    try testing.expectEqual(true, notifier.subscribe_to_events);
    try testing.expectEqual(true, notifier.history_read);
    try testing.expectEqual(false, notifier.history_write);

    const c_notifier = notifier.toC();
    const expected = c.UA_EVENTNOTIFIERTYPE_SUBSCRIBETOEVENTS | c.UA_EVENTNOTIFIERTYPE_HISTORYREAD;
    try testing.expectEqual(@as(u8, expected), c_notifier);

    const roundtrip = EventNotifier.fromC(c_notifier);
    try testing.expectEqual(notifier.subscribe_to_events, roundtrip.subscribe_to_events);
    try testing.expectEqual(notifier.history_read, roundtrip.history_read);
    try testing.expectEqual(notifier.history_write, roundtrip.history_write);
}

test "EventNotifier roundtrip conversion" {
    const testing = std.testing;

    const notifier = EventNotifier{
        .subscribe_to_events = true,
        .history_read = false,
        .history_write = true,
    };

    const c_notifier = notifier.toC();
    const roundtrip = EventNotifier.fromC(c_notifier);

    try testing.expectEqual(notifier.subscribe_to_events, roundtrip.subscribe_to_events);
    try testing.expectEqual(notifier.history_read, roundtrip.history_read);
    try testing.expectEqual(notifier.history_write, roundtrip.history_write);
}
