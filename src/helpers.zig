//! This module provides helpers for open62541
//! Due to the library's use of bit fields in certain structs, we need to wrap
//! some function calls in C code first before exposing them to Zig, as Zig
//! does not support bit fields directly.
const c = @import("c.zig");

const ServerResult = extern struct {
    status: c.UA_StatusCode,
    server: ?*c.UA_Server,
};

pub extern fn UA_Server_newDefaultWithStatus() ServerResult;
