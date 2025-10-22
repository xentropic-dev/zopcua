//! This module provides helpers for open62541
//! Due to the library's use of bit fields in certain structs, we need to wrap
//! some function calls in C code first before exposing them to Zig, as Zig
//! does not support bit fields directly.
// zlint-disable
const c = @import("c.zig");

const ServerResult = extern struct {
    status: c.UA_StatusCode,
    server: ?*c.UA_Server,
};

const ClientResult = extern struct {
    status: c.UA_StatusCode,
    client: ?*c.UA_Client,
};

// I'm actually not sure this was necessary now.
pub extern fn UA_Server_newDefaultWithStatus() ServerResult;
pub extern fn UA_Client_newDefaultWithStatus() ClientResult;
