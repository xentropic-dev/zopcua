const c = @import("c.zig");
/// Access Level Masks
/// The access level to a node is given by the following boolean fields.
/// Each field represents a specific access permission that can be granted.
pub const AccessLevel = packed struct(u8) {
    /// Current read access
    read: bool = false,

    /// Current write access
    write: bool = false,

    /// History read access
    history_read: bool = false,

    /// History write access
    history_write: bool = false,

    /// Semantic change access (ability to change the meaning of the node)
    semantic_change: bool = false,

    /// Status write access (ability to write status codes)
    status_write: bool = false,

    /// Timestamp write access (ability to write timestamps)
    timestamp_write: bool = false,

    _padding: u1 = 0,

    /// No access permissions
    pub const none = AccessLevel{};

    /// Read-only access
    pub const read_only = AccessLevel{ .read = true };

    /// Read and write access
    pub const read_write = AccessLevel{ .read = true, .write = true };

    /// Convert from C API representation
    pub inline fn fromC(value: c.UA_Byte) AccessLevel {
        return @bitCast(value);
    }

    /// Convert to C API representation
    pub inline fn toC(self: AccessLevel) c.UA_Byte {
        return @bitCast(self);
    }
};

const std = @import("std");

test "AccessLevel bitfield conversion roundtrip" {
    const testing = std.testing;
    std.testing.refAllDecls(@This());

    const level = AccessLevel{ .read = true, .write = true };
    const c_level = level.toC();
    const back = AccessLevel.fromC(c_level);

    try testing.expect(back.read == true);
    try testing.expect(back.write == true);
    try testing.expect(back.history_read == false);
    try testing.expect(back.history_write == false);
}

test "AccessLevel all flags set" {
    const testing = std.testing;

    const level = AccessLevel{
        .read = true,
        .write = true,
        .history_read = true,
        .history_write = true,
        .semantic_change = true,
        .status_write = true,
        .timestamp_write = true,
    };

    const c_level = level.toC();
    const back = AccessLevel.fromC(c_level);

    try testing.expect(back.read);
    try testing.expect(back.write);
    try testing.expect(back.history_read);
    try testing.expect(back.history_write);
    try testing.expect(back.semantic_change);
    try testing.expect(back.status_write);
    try testing.expect(back.timestamp_write);
}

test "AccessLevel predefined constants" {
    const testing = std.testing;

    // none
    try testing.expect(AccessLevel.none.read == false);
    try testing.expect(AccessLevel.none.write == false);

    // read_only
    try testing.expect(AccessLevel.read_only.read == true);
    try testing.expect(AccessLevel.read_only.write == false);

    // read_write
    try testing.expect(AccessLevel.read_write.read == true);
    try testing.expect(AccessLevel.read_write.write == true);
}

test "AccessLevel default initialization" {
    const testing = std.testing;

    const level = AccessLevel{};
    try testing.expect(level.read == false);
    try testing.expect(level.write == false);
    try testing.expect(level.history_read == false);
}
