const std = @import("std");
const c = @import("c.zig");
pub const EventNotifier = @import("event_notifier.zig").EventNotifier;
pub const AttributeWriteMask = @import("attribute_write_mask.zig").AttributeWriteMask;
const LocalizedText = @import("localized_text.zig").LocalizedText;

/// Attributes for an OPC UA Object Node
pub const ObjectAttributes = struct {
    specified_attributes: u32 = 0,
    display_name: LocalizedText = .{},
    description: LocalizedText = .{},
    write_mask: AttributeWriteMask = .none,
    user_write_mask: AttributeWriteMask = .none,
    event_notifier: EventNotifier = .none,

    /// Convert to C API representation
    pub fn toC(self: ObjectAttributes) c.UA_ObjectAttributes {
        var result = std.mem.zeroes(c.UA_ObjectAttributes);
        result.specifiedAttributes = self.specified_attributes;
        result.displayName = self.display_name.toC();
        result.description = self.description.toC();
        result.writeMask = self.write_mask.toC();
        result.userWriteMask = self.user_write_mask.toC();
        result.eventNotifier = self.event_notifier.toC();
        return result;
    }

    /// Convert from C API representation
    pub fn fromC(value: c.UA_ObjectAttributes) ObjectAttributes {
        return .{
            .specified_attributes = value.specifiedAttributes,
            .display_name = LocalizedText.fromC(value.displayName),
            .description = LocalizedText.fromC(value.description),
            .write_mask = AttributeWriteMask.fromC(value.writeMask),
            .user_write_mask = AttributeWriteMask.fromC(value.userWriteMask),
            .event_notifier = EventNotifier.fromC(value.eventNotifier),
        };
    }
};

// ============================================================================
// Tests
// ============================================================================

test "ObjectAttributes default values" {
    const testing = std.testing;
    std.testing.refAllDecls(@This());

    const attrs = ObjectAttributes{};
    try testing.expectEqual(@as(u32, 0), attrs.specified_attributes);
    try testing.expectEqual(EventNotifier.none, attrs.event_notifier);
    try testing.expectEqual(AttributeWriteMask.none, attrs.write_mask);
    try testing.expectEqual(AttributeWriteMask.none, attrs.user_write_mask);
}

test "ObjectAttributes with values" {
    const testing = std.testing;

    const attrs = ObjectAttributes{
        .display_name = LocalizedText.init("en-US", "Test Object"),
        .description = LocalizedText.initText("A test object"),
        .event_notifier = .{ .subscribe_to_events = true },
    };

    try testing.expectEqualStrings("Test Object", attrs.display_name.text);
    try testing.expectEqualStrings("A test object", attrs.description.text);
    try testing.expectEqual(true, attrs.event_notifier.subscribe_to_events);

    const c_attrs = attrs.toC();
    try testing.expectEqual(@as(u8, c.UA_EVENTNOTIFIERTYPE_SUBSCRIBETOEVENTS), c_attrs.eventNotifier);
}

test "ObjectAttributes toC conversion" {
    const testing = std.testing;

    const attrs = ObjectAttributes{
        .display_name = LocalizedText.init("en-US", "Sensors"),
        .description = LocalizedText.initText("Sensor group"),
        .event_notifier = .{ .history_read = true },
        .write_mask = .{ .display_name = true },
    };

    const c_attrs = attrs.toC();

    try testing.expectEqual(@as(u8, c.UA_EVENTNOTIFIERTYPE_HISTORYREAD), c_attrs.eventNotifier);

    // Verify displayName was converted
    try testing.expect(c_attrs.displayName.text.length > 0);
}

test "ObjectAttributes roundtrip conversion" {
    const testing = std.testing;

    const original = ObjectAttributes{
        .specified_attributes = 0xFF,
        .display_name = LocalizedText.init("en-US", "Test"),
        .description = LocalizedText.initText("Description"),
        .event_notifier = .{ .subscribe_to_events = true, .history_write = true },
    };

    const c_attrs = original.toC();
    const roundtrip = ObjectAttributes.fromC(c_attrs);

    try testing.expectEqual(original.specified_attributes, roundtrip.specified_attributes);
    try testing.expectEqual(original.event_notifier.subscribe_to_events, roundtrip.event_notifier.subscribe_to_events);
    try testing.expectEqual(original.event_notifier.history_write, roundtrip.event_notifier.history_write);
}
