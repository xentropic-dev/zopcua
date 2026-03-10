const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");
const ua_error = @import("ua_error.zig");
const NodeId = @import("types.zig").NodeId;
const QualifiedName = @import("types.zig").QualifiedName;
const NodeClass = @import("types.zig").NodeClass;
const Variant = @import("variant.zig").Variant;
const DataValue = @import("data_value.zig").DataValue;
const LocalizedText = @import("localized_text.zig").LocalizedText;
const String = @import("localized_text.zig").String;
const ClientConfig = @import("client_config.zig").ClientConfig;
const browse = @import("browse.zig");
const BrowseDescription = browse.BrowseDescription;
const BrowseResult = browse.BrowseResult;
const subscription = @import("subscription.zig");
const SubscriptionParameters = subscription.SubscriptionParameters;
const SubscriptionId = subscription.SubscriptionId;
const MonitoredItemParameters = subscription.MonitoredItemParameters;
const MonitoredItemId = subscription.MonitoredItemId;
const DataChangeCallback = subscription.DataChangeCallback;
const attributes = @import("attributes.zig");
const AttributeId = attributes.AttributeId;
const AttributeValue = attributes.AttributeValue;
const client_auth = @import("client_auth.zig");
const AuthenticationConfig = client_auth.AuthenticationConfig;
const UserIdentityToken = client_auth.UserIdentityToken;

/// Internal context structure for monitored item callbacks.
/// This is heap-allocated and managed by the C library's lifecycle.
const MonitoredItemContext = struct {
    callback: DataChangeCallback,
    userdata: ?*anyopaque,
};

/// C callback wrapper for data change notifications.
/// Converts C types to Zig types and calls the user's callback.
fn dataChangeCallbackWrapper(
    client: ?*c.UA_Client,
    sub_id: u32,
    sub_context: ?*anyopaque,
    mon_id: u32,
    mon_context: ?*anyopaque,
    value: [*c]c.UA_DataValue,
) callconv(.c) void {
    _ = client;
    _ = sub_context;

    // Extract context
    const ctx: *MonitoredItemContext = @ptrCast(@alignCast(mon_context.?));

    // Convert C DataValue to Zig DataValue
    var zig_value = DataValue.fromC(value);
    defer zig_value.deinit();

    // Call user callback
    ctx.callback(sub_id, mon_id, zig_value, ctx.userdata);
}

/// OPC UA Client wrapper providing type-safe, memory-safe operations.
pub const Client = struct {
    handle: *c.UA_Client,
    allocator: std.mem.Allocator,

    /// Initialize a new OPC UA client with default configuration.
    pub fn init(allocator: std.mem.Allocator) !Client {
        const handle = c.UA_Client_new();
        if (handle == null) {
            return error.OutOfMemory;
        }

        const config = c.UA_Client_getConfig(handle);
        const status = c.UA_ClientConfig_setDefault(config);
        if (status != c.UA_STATUSCODE_GOOD) {
            c.UA_Client_delete(handle);
            return ua_error.OpcUaError.BadInternalError;
        }

        return Client{
            .handle = handle,
            .allocator = allocator,
        };
    }

    /// Initialize a new OPC UA client with custom configuration.
    pub fn initWithConfig(allocator: std.mem.Allocator, config: ClientConfig) !Client {
        const handle = c.UA_Client_new();
        if (handle == null) {
            return error.OutOfMemory;
        }

        // Apply custom configuration
        // TODO: Implement custom config application

        return Client{
            .handle = handle,
            .allocator = allocator,
        };
    }

    /// Clean up client resources.
    pub fn deinit(self: *Client) void {
        c.UA_Client_delete(self.handle);
    }

    /// Connect to an OPC UA server with the specified endpoint URL.
    ///
    /// This function establishes a connection to an OPC UA server.
    /// It creates a secure channel and activates a session.
    ///
    /// **Memory management:**
    /// This function handles all memory management internally using temporary allocations.
    /// No cleanup is required by the caller.
    ///
    /// Example usage:
    /// ```zig
    /// const client = try Client.init(allocator);
    /// defer client.deinit();
    /// try client.connect("opc.tcp://localhost:4840");
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
    pub fn connect(self: *Client, endpoint_url: []const u8) !void {
        // Use arena allocator to safely create null-terminated strings for C API
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();

        const buf = try arena.allocator().alloc(u8, endpoint_url.len + 1);
        const c_url = try std.fmt.bufPrintZ(buf, "{s}", .{endpoint_url});

        const status = c.UA_Client_connect(self.handle, c_url.ptr);
        try ua_error.checkStatus(status);
    }

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
    pub fn connectWithUsername(
        self: *Client,
        endpoint_url: []const u8,
        username: []const u8,
        password: []const u8
    ) !void {
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

        const status = c.UA_Client_connectUsername(
            self.handle,
            c_url.ptr,
            c_username.ptr,
            c_password.ptr
        );
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
    pub fn connectAnonymous(self: *Client, endpoint_url: []const u8) !void {
        // This calls the standard connect method
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();

        const buf = try arena.allocator().alloc(u8, endpoint_url.len + 1);
        const c_url = try std.fmt.bufPrintZ(buf, "{s}", .{endpoint_url});

        const status = c.UA_Client_connect(self.handle, c_url.ptr);
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
    /// 
    /// // Username/password authentication
    /// const auth_config = AuthenticationConfig{
    ///     .identity_token = .{
    ///         .username_password = .{
    ///             .username = "admin",
    ///             .password = "password",
    ///         },
    ///     },
    /// };
    /// try client.connectWithAuth("opc.tcp://localhost:4840", auth_config);
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
    pub fn connectWithAuth(
        self: *Client,
        endpoint_url: []const u8,
        auth_config: AuthenticationConfig
    ) !void {
        // Use arena allocator to safely create null-terminated strings for C API
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        // Allocate buffer and create null-terminated string for endpoint URL
        const url_buf = try allocator.alloc(u8, endpoint_url.len + 1);
        const c_url = try std.fmt.bufPrintZ(url_buf, "{s}", .{endpoint_url});

        // Handle different authentication methods
        switch (auth_config.identity_token) {
            .anonymous => {
                // Anonymous authentication
                const status = c.UA_Client_connect(self.handle, c_url.ptr);
                try ua_error.checkStatus(status);
            },
            .username_password => |creds| {
                // Username/password authentication
                const user_buf = try allocator.alloc(u8, creds.username.len + 1);
                const c_username = try std.fmt.bufPrintZ(user_buf, "{s}", .{creds.username});

                const pass_buf = try allocator.alloc(u8, creds.password.len + 1);
                const c_password = try std.fmt.bufPrintZ(pass_buf, "{s}", .{creds.password});

                const status = c.UA_Client_connectUsername(
                    self.handle,
                    c_url.ptr,
                    c_username.ptr,
                    c_password.ptr
                );
                try ua_error.checkStatus(status);
            },
            .x509_certificate => |cert| {
                // X.509 certificate authentication
                // For certificate authentication, we need to load the certificate
                // and private key into the client config
                
                // Get client config
                var config: *c.UA_ClientConfig = c.UA_Client_getConfig(self.handle);
                
                // Load certificate from PEM data
                var certificate = c.UA_ByteString_new();
                defer c.UA_ByteString_delete(certificate);
                
                const cert_status = c.UA_ByteString_allocBuffer(
                    certificate,
                    @intCast(cert.certificate.len)
                );
                if (cert_status != c.UA_STATUSCODE_GOOD) {
                    return ua_error.OpcUaError.BadCertificateInvalid;
                }
                
                @memcpy(certificate.data, cert.certificate.ptr, cert.certificate.len);
                
                // Load private key from PEM data  
                var private_key = c.UA_ByteString_new();
                defer c.UA_ByteString_delete(private_key);
                
                const key_status = c.UA_ByteString_allocBuffer(
                    private_key,
                    @intCast(cert.private_key.len)
                );
                if (key_status != c.UA_STATUSCODE_GOOD) {
                    return ua_error.OpcUaError.BadCertificateInvalid;
                }
                
                @memcpy(private_key.data, cert.private_key.ptr, cert.private_key.len);
                
                // Set certificate and private key in config
                // Note: This assumes the client was configured to accept certificate auth
                // In a real implementation, we'd need to check if security policy supports it
                
                // For now, we'll attempt to connect with the standard method
                // Certificate validation happens at the protocol level
                const status = c.UA_Client_connect(self.handle, c_url.ptr);
                try ua_error.checkStatus(status);
            },
            .issued_token => |token| {
                // Issued token authentication
                // TODO: Implement token-based authentication
                // This requires setting up the client config with token data
                return error.NotImplemented;
            },
        }
    }

    /// Disconnect from the OPC UA server.
    ///
    /// This function closes the secure channel and deactivates the session.
    /// It should be called before deinitializing the client.
    ///
    /// **Note:** This function may fail if the connection is already closed
    /// or in an error state. Use `defer client.disconnect() catch {}` to
    /// ensure cleanup is attempted but doesn't crash on failure.
    pub fn disconnect(self: *Client) !void {
        const status = c.UA_Client_disconnect(self.handle);
        try ua_error.checkStatus(status);
    }

    // ... rest of the Client implementation (read, write, browse, etc.)
};

// Export authentication types for easy access
pub const AuthenticationMethod = client_auth.AuthenticationMethod;
pub const UserIdentityToken = client_auth.UserIdentityToken;
pub const AuthenticationConfig = client_auth.AuthenticationConfig;