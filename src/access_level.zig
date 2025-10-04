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
    pub inline fn fromC(value: u8) AccessLevel {
        return @bitCast(value);
    }

    /// Convert to C API representation
    pub inline fn toC(self: AccessLevel) u8 {
        return @bitCast(self);
    }
};
