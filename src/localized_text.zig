const c = @import("c.zig");

pub const LocalizedText = struct {
    locale: []const u8 = "",
    text: []const u8 = "",

    /// Create a LocalizedText with locale and text
    pub fn init(locale: []const u8, text: []const u8) LocalizedText {
        return .{ .locale = locale, .text = text };
    }

    /// Create a LocalizedText with only text (no locale)
    pub fn initText(text: []const u8) LocalizedText {
        return .{ .text = text };
    }

    /// Convert from C API representation
    pub fn fromC(value: c.UA_LocalizedText) LocalizedText {
        return .{
            .locale = String.fromC(value.locale),
            .text = String.fromC(value.text),
        };
    }

    /// Convert to C API representation
    pub fn toC(self: LocalizedText) c.UA_LocalizedText {
        return .{
            .locale = String.toC(self.locale),
            .text = String.toC(self.text),
        };
    }
};

/// Wrapper for UA_String
pub const String = struct {
    /// Convert Zig string slice to C UA_String
    pub fn toC(str: []const u8) c.UA_String {
        return .{
            .length = str.len,
            .data = @constCast(str.ptr),
        };
    }

    /// Convert C UA_String to Zig string slice
    pub fn fromC(str: c.UA_String) []const u8 {
        if (str.length == 0 or str.data == null) return "";
        return str.data[0..str.length];
    }
};

const std = @import("std");

test "LocalizedText with locale and text" {
    const testing = std.testing;
    std.testing.refAllDecls(@This());

    const text = LocalizedText.init("en-US", "Hello World");
    try testing.expectEqualStrings("en-US", text.locale);
    try testing.expectEqualStrings("Hello World", text.text);
}

test "LocalizedText with text only" {
    const testing = std.testing;

    const text = LocalizedText.initText("Hello");
    try testing.expectEqualStrings("", text.locale);
    try testing.expectEqualStrings("Hello", text.text);
}

test "LocalizedText empty initialization" {
    const testing = std.testing;

    const text = LocalizedText{};
    try testing.expectEqualStrings("", text.locale);
    try testing.expectEqualStrings("", text.text);
}

test "LocalizedText C conversion roundtrip" {
    const testing = std.testing;

    const original = LocalizedText.init("de-DE", "Hallo Welt");
    const c_text = original.toC();
    const back = LocalizedText.fromC(c_text);

    try testing.expectEqualStrings(original.locale, back.locale);
    try testing.expectEqualStrings(original.text, back.text);
}

test "LocalizedText with special characters" {
    const testing = std.testing;

    const original = LocalizedText.init("zh-CN", "你好世界");
    const c_text = original.toC();
    const back = LocalizedText.fromC(c_text);

    try testing.expectEqualStrings(original.locale, back.locale);
    try testing.expectEqualStrings(original.text, back.text);
}

test "String toC conversion" {
    const testing = std.testing;

    const str = "Test String";
    const c_str = String.toC(str);

    try testing.expectEqual(str.len, c_str.length);
    try testing.expectEqualStrings(str, c_str.data[0..c_str.length]);
}

test "String fromC conversion" {
    const testing = std.testing;

    const original = "Test String";
    const c_str = c.UA_String{
        .length = original.len,
        .data = @constCast(original.ptr),
    };
    const result = String.fromC(c_str);

    try testing.expectEqualStrings(original, result);
}

test "String fromC with null data" {
    const testing = std.testing;

    const c_str = c.UA_String{ .length = 0, .data = null };
    const result = String.fromC(c_str);

    try testing.expectEqualStrings("", result);
}

test "String fromC with zero length" {
    const testing = std.testing;

    const dummy: [1]u8 = .{0};
    const c_str = c.UA_String{ .length = 0, .data = @constCast(&dummy) };
    const result = String.fromC(c_str);

    try testing.expectEqualStrings("", result);
}

test "String roundtrip conversion" {
    const testing = std.testing;

    const original = "Hello, OPC UA!";
    const c_str = String.toC(original);
    const back = String.fromC(c_str);

    try testing.expectEqualStrings(original, back);
}
