// This file contains authentication integration for the Client struct
// It should be imported and the methods added to the Client struct

const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");
const ua_error = @import("ua_error.zig");

/// Authentication methods to add to the Client struct
pub const ClientAuthMethods = struct {
    handle: *c.UA_Client,

    /// Connect to an OPC UA server with username and password authentication.
    ///
    /// This function establishes a connection to an OPC UA server using
    /// username/password authentication. It creates a secure channel and
    /// activates a session with the provided credentials.
    ///
    /// **Memory management:**
    /// This function handles all memory management internally using temporary allocations.
    /// No cleanup is required by the caller.
    ///
    /// Example usage:
    /// ```zig
    /// const client = try Client.init(allocator);
    /// defer client.deinit();
    /// try client.connectWithUsername("opc.tcp://localhost:4840", "admin", "password");
    /// defer client.disconnect();
    /// // ... do work ...
    /// ```
    ///
    /// **Errors:**
    /// Returns errors from `ua_error.OpcUaError` including common ones like:
    /// - `BadTcpEndpointUrlInvalid` - The endpoint URL format is invalid
    /// - `BadConnectionRejected` - The server rejected the connection
    /// - `BadTimeout` - Connection attempt timed out
    /// - `BadCommunicationError` - Network communication error
    /// - `BadSecurityChecksFailed` - Security checks failed
    /// - `BadUserAccessDenied` - Invalid username or password
    /// - `BadCertificateInvalid` - Certificate validation failed
    pub fn connectWithUsername(self: *const @This(), endpoint_url: []const u8, username: []const u8, password: []const u8) !void {
        // Use arena allocator to safely create null-terminated strings for C API
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();

        // Allocate buffers and create null-terminated strings
        const url_buf = try arena.allocator().alloc(u8, endpoint_url.len + 1);
        const c_url = try std.fmt.bufPrintZ(url_buf, "{s}", .{endpoint_url});

        const user_buf = try arena.allocator().alloc(u8, username.len + 1);
        const c_username = try std.fmt.bufPrintZ(user_buf, "{s}", .{username});

        const pass_buf = try arena.allocator().alloc(u8, password.len + 1);
        const c_password = try std.fmt.bufPrintZ(pass_buf, "{s}", .{password});

        const status = c.UA_Client_connectUsername(self.handle, c_url.ptr, c_username.ptr, c_password.ptr);
        try ua_error.checkStatus(status);
    }

    /// Connect to an OPC UA server with anonymous authentication (no credentials).
    ///
    /// This function establishes a connection to an OPC UA server using
    /// anonymous authentication. This is equivalent to the standard `connect()`
    /// method but explicitly indicates anonymous access.
    ///
    /// **Memory management:**
    /// This function handles all memory management internally using temporary allocations.
    /// No cleanup is required by the caller.
    ///
    /// Example usage:
    /// ```zig
    /// const client = try Client.init(allocator);
    /// defer client.deinit();
    /// try client.connectAnonymous("opc.tcp://localhost:4840");
    /// defer client.disconnect();
    /// // ... do work ...
    /// ```
    ///
    /// **Errors:**
    /// Returns errors from `ua_error.OpcUaError` including common ones like:
    /// - `BadTcpEndpointUrlInvalid` - The endpoint URL format is invalid
    /// - `BadConnectionRejected` - The server rejected the connection
    /// - `BadTimeout` - Connection attempt timed out
    /// - `BadCommunicationError` - Network communication error
    /// - `BadSecurityChecksFailed` - Security checks failed
    /// - `BadCertificateInvalid` - Certificate validation failed
    pub fn connectAnonymous(self: *const @This(), endpoint_url: []const u8) !void {
        // This calls the standard connect method
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();

        const buf = try arena.allocator().alloc(u8, endpoint_url.len + 1);
        const c_url = try std.fmt.bufPrintZ(buf, "{s}", .{endpoint_url});

        const status = c.UA_Client_connect(self.handle, c_url.ptr);
        try ua_error.checkStatus(status);
    }
};