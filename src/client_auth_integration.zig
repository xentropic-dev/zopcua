const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");
const ua_error = @import("ua_error.zig");
const client_auth = @import("client_auth.zig");

/// Client with integrated authentication support.
/// This wrapper provides a more convenient API for authentication.
pub const ClientWithAuth = struct {
    client: *c.UA_Client,

    /// Initialize a new client with authentication support.
    pub fn init(client: *c.UA_Client) ClientWithAuth {
        return .{ .client = client };
    }

    /// Connect to an OPC UA server with username and password authentication.
    ///
    /// This function establishes a connection to an OPC UA server using
    /// username and password authentication.
    ///
    /// **Memory management:**
    /// This function handles all memory management internally using temporary allocations.
    /// No cleanup is required by the caller.
    ///
    /// Example usage:
    /// ```zig
    /// const client = try Client.init(allocator);
    /// defer client.deinit();
    /// const auth_client = ClientWithAuth.init(client.handle);
    /// try auth_client.connectWithUsername("opc.tcp://localhost:4840", "admin", "password");
    /// defer client.disconnect();
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
        const allocator = arena.allocator();

        // Allocate buffer and create null-terminated string for endpoint URL
        const url_buf = try allocator.alloc(u8, endpoint_url.len + 1);
        const c_url = try std.fmt.bufPrintZ(url_buf, "{s}", .{endpoint_url});

        // Allocate buffers and create null-terminated strings for credentials
        const user_buf = try allocator.alloc(u8, username.len + 1);
        const c_username = try std.fmt.bufPrintZ(user_buf, "{s}", .{username});

        const pass_buf = try allocator.alloc(u8, password.len + 1);
        const c_password = try std.fmt.bufPrintZ(pass_buf, "{s}", .{password});

        const status = c.UA_Client_connectUsername(self.client, c_url.ptr, c_username.ptr, c_password.ptr);
        try ua_error.checkStatus(status);
    }

    /// Connect to an OPC UA server with authentication configuration.
    ///
    /// This function establishes a connection to an OPC UA server using
    /// the specified authentication method and credentials.
    ///
    /// **Memory management:**
    /// This function handles all memory management internally using temporary allocations.
    /// No cleanup is required by the caller.
    ///
    /// Example usage:
    /// ```zig
    /// const client = try Client.init(allocator);
    /// defer client.deinit();
    /// const auth_client = ClientWithAuth.init(client.handle);
    ///
    /// // Username/password authentication
    /// const auth_config = client_auth.AuthenticationConfig{
    ///     .identity_token = .{
    ///         .username_password = .{
    ///             .username = "admin",
    ///             .password = "password",
    ///         },
    ///     },
    /// };
    /// try auth_client.connectWithAuth("opc.tcp://localhost:4840", auth_config);
    /// defer client.disconnect();
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
    pub fn connectWithAuth(self: *const @This(), endpoint_url: []const u8, auth_config: client_auth.AuthenticationConfig) !void {
        return client_auth.connectWithAuth(self.client, endpoint_url, auth_config);
    }

    /// Simplified function to connect anonymously.
    pub fn connectAnonymous(self: *const @This(), endpoint_url: []const u8) !void {
        return client_auth.connectAnonymous(self.client, endpoint_url);
    }
};
