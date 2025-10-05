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
