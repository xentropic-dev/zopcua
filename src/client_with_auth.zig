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

    // Convert UA_DataValue to Variant (temporary, valid only during callback)
    // Use c_allocator since this is managed by C library lifecycle
    const variant = Variant.fromC(value.*.value, std.heap.c_allocator) catch {
        // If conversion fails, skip this notification
        return;
    };
    defer variant.deinit(std.heap.c_allocator);

    // Call user's callback
    ctx.callback(ctx.userdata, sub_id, mon_id, &variant);
}

/// C delete callback wrapper - frees the context when monitored item is deleted.
fn deleteMonitoredItemCallbackWrapper(
    client: ?*c.UA_Client,
    sub_id: u32,
    sub_context: ?*anyopaque,
    mon_id: u32,
    mon_context: ?*anyopaque,
) callconv(.c) void {
    _ = client;
    _ = sub_id;
    _ = sub_context;
    _ = mon_id;

    if (mon_context) |ctx_ptr| {
        const ctx: *MonitoredItemContext = @ptrCast(@alignCast(ctx_ptr));
        std.heap.c_allocator.destroy(ctx);
    }
}

/// Errors that can occur when reading an attribute from a node
pub const ReadAttributeError = error{
    /// The client is not connected to a server
    ServerNotConnected,
    /// The session has been closed
    SessionClosed,
    /// The read operation timed out
    Timeout,
    /// Network communication error occurred
    CommunicationError,
    /// The specified node does not exist on the server
    NodeIdUnknown,
    /// The node ID format is invalid
    NodeIdInvalid,
    /// The attribute ID is invalid
    AttributeIdInvalid,
    /// The node does not allow read access
    NotReadable,
    /// The current user does not have permission to read this node
    UserAccessDenied,
    /// Invalid index range specified
    IndexRangeInvalid,
    /// No data exists in the specified index range
    IndexRangeNoData,
    /// The data encoding is invalid
    DataEncodingInvalid,
    /// The data encoding is not supported
    DataEncodingUnsupported,
    /// The requested data was not found
    NotFound,
    /// The node has been deleted
    ObjectDeleted,
    /// The service is not supported
    ServiceUnsupported,
    /// Insufficient memory to complete the operation
    OutOfMemory,
    /// An internal server error occurred
    InternalError,
    /// The security checks failed
    SecurityChecksFailed,
    /// An unexpected error occurred (catch-all for unknown status codes)
    UnexpectedError,
};

/// Errors that can occur when browsing nodes
pub const BrowseError = error{
    /// The client is not connected to a server
    ServerNotConnected,
    /// The session has been closed
    SessionClosed,
    /// The browse operation timed out
    Timeout,
    /// Network communication error occurred
    CommunicationError,
    /// The specified node does not exist on the server
    NodeIdUnknown,
    /// The node ID format is invalid
    NodeIdInvalid,
    /// The browse direction is invalid
    BrowseDirectionInvalid,
    /// The reference type ID is invalid
    ReferenceTypeIdInvalid,
    /// The current user does not have permission to browse this node
    UserAccessDenied,
    /// The node has been deleted
    ObjectDeleted,
    /// The requested node was not found
    NotFound,
    /// The continuation point is invalid or expired
    ContinuationPointInvalid,
    /// No continuation point available
    NoContinuationPoint,
    /// Insufficient memory to complete the operation
    OutOfMemory,
    /// An internal server error occurred
    InternalError,
    /// The service is not supported
    ServiceUnsupported,
    /// The security checks failed
    SecurityChecksFailed,
    /// An unexpected error occurred (catch-all for unknown status codes)
    UnexpectedError,
};

/// Errors that can occur when writing an attribute to a node
pub const WriteAttributeError = error{
    /// The client is not connected to a server
    ServerNotConnected,
    /// The session has been closed
    SessionClosed,
    /// The write operation timed out
    Timeout,
    /// Network communication error occurred
    CommunicationError,
    /// The specified node does not exist on the server
    NodeIdUnknown,
    /// The node ID format is invalid
    NodeIdInvalid,
    /// The attribute ID is invalid
    AttributeIdInvalid,
    /// The node does not allow write access
    NotWritable,
    /// The current user does not have permission to write to this node
    UserAccessDenied,
    /// The node has been deleted
    ObjectDeleted,
    /// The requested node was not found
    NotFound,
    /// Value type doesn't match node's declared data type
    TypeMismatch,
    /// Invalid index range specified
    IndexRangeInvalid,
    /// No data exists in the specified index range
    IndexRangeNoData,
    /// The data encoding is invalid
    DataEncodingInvalid,
    /// The data encoding is not supported
    DataEncodingUnsupported,
    /// Value is outside the allowed range for this node
    OutOfRange,
    /// Insufficient memory to complete the operation
    OutOfMemory,
    /// An internal server error occurred
    InternalError,
    /// The service is not supported
    ServiceUnsupported,
    /// The security checks failed
    SecurityChecksFailed,
    /// An unexpected error occurred (catch-all for unknown status codes)
    UnexpectedError,
};

/// Errors that can occur during namespace operations
pub const NamespaceError = error{
    /// The namespace URI is invalid or empty
    InvalidNamespaceUri,
    /// The namespace was not found on the server
    NamespaceNotFound,
    /// The client is not connected to a server
    ServerNotConnected,
    /// The session has been closed
    SessionClosed,
    /// The operation timed out
    Timeout,
    /// Network communication error occurred
    CommunicationError,
    /// Insufficient memory to complete the operation
    OutOfMemory,
    /// An internal error occurred
    InternalError,
    /// The service is not supported
    ServiceUnsupported,
    /// An unexpected error occurred
    UnexpectedError,
};

/// Errors that can occur during subscription operations
pub const SubscriptionError = error{
    /// The client is not connected to a server
    ServerNotConnected,
    /// The session has been closed
    SessionClosed,
    /// The operation timed out
    Timeout,
    /// Network communication error occurred
    CommunicationError,
    /// Invalid subscription parameters
    InvalidParameters,
    /// Subscription not found
    SubscriptionNotFound,
    /// Too many subscriptions
    TooManySubscriptions,
    /// Insufficient memory to complete the operation
    OutOfMemory,
    /// An internal server error occurred
    InternalError,
    /// The service is not supported
    ServiceUnsupported,
    /// The security checks failed
    SecurityChecksFailed,
    /// An unexpected error occurred
    UnexpectedError,
};

/// Errors that can occur during monitored item operations
pub const MonitoredItemError = error{
    /// The client is not connected to a server
    ServerNotConnected,
    /// The session has been closed
    SessionClosed,
    /// The operation timed out
    Timeout,
    /// Network communication error occurred
    CommunicationError,
    /// The specified node does not exist on the server
    NodeIdUnknown,
    /// The node ID format is invalid
    NodeIdInvalid,
    /// Invalid monitored item parameters
    InvalidParameters,
    /// Monitored item not found
    MonitoredItemNotFound,
    /// Subscription ID is invalid
    SubscriptionIdInvalid,
    /// Attribute is not supported for monitoring
    AttributeNotSupported,
    /// Too many monitored items
    TooManyMonitoredItems,
    /// Insufficient memory to complete the operation
    OutOfMemory,
    /// An internal server error occurred
    InternalError,
    /// The service is not supported
    ServiceUnsupported,
    /// The security checks failed
    SecurityChecksFailed,
    /// An unexpected error occurred
    UnexpectedError,
};

pub const Client = struct {
    handle: *c.UA_Client,

    /// Create a new client with a custom configuration.
    ///
    /// This allows full control over client settings including timeouts, security,
    /// and other options. The client is created but not connected.
    ///
    /// Example usage:
    /// ```zig
    /// var client = try Client.initWithConfig(.{ .timeout = 10000 });
    /// defer client.deinit();
    /// try client.connect("opc.tcp://localhost:4840");
    /// // ... do work ...
    /// client.disconnect();
    /// ```
    ///
    /// **Errors:**
    /// - `BadOutOfMemory` - Memory allocation failed during initialization
    /// - `BadInternalError` - Client creation or configuration failed
    pub fn initWithConfig(config: ClientConfig) !Client {
        // SAFETY: Immediately initialized to zero bytes by @memset on next line
        var c_config: c.UA_ClientConfig = undefined;
        @memset(std.mem.asBytes(&c_config), 0);

        // Use arena allocator for temporary C conversions
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();

        // Apply Zig config to C config
        try config.applyToC(arena.allocator(), &c_config);

        // Create client with the configured settings
        const client = c.UA_Client_newWithConfig(&c_config);
        if (client == null) return error.BadInternalError;

        return .{ .handle = client.? };
    }

    /// Create a new client with a default configuration that adds plugins for
    /// networking, security, logging and so on. The default configuration can
    /// be used as the starting point to adjust the client configuration to
    /// individual needs.
    ///
    /// The client is created but not connected. Call `connect()` to establish a connection.
    ///
    /// Typical usage:
    /// ```zig
    /// var client = try Client.init();
    /// defer client.deinit();
    /// try client.connect("opc.tcp://localhost:4840");
    /// // ... do work ...
    /// client.disconnect();
    /// ```
    ///
    /// **Errors:**
    /// - `BadOutOfMemory` - Memory allocation failed during client creation
    /// - `BadInternalError` - Internal error during client initialization (config setup
    ///   failed or client creation failed)
    pub fn init() !Client {
        // Use default configuration
        return initWithConfig(.{});
    }

    /// Free the client resources.
    ///
    /// This should be called when the client is no longer needed to prevent memory leaks.
    /// The client must be disconnected before calling this function, or it will be
    /// disconnected automatically.
    pub fn deinit(self: Client) void {
        c.UA_Client_delete(self.handle);
    }

    /// Connect to the specified OPC UA server endpoint.
    ///
    /// This function establishes a SecureChannel and creates a Session with the server.
    /// The endpoint URL must be in the format: `opc.tcp://hostname:port[/path]`
    ///
    /// Example usage:
    /// ```zig
    /// var client = try Client.init();
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
    ///
    /// TODO: Unroll checkStatus and return explicit connect-specific errors instead
    /// of the full OpcUaError set. This would provide better type safety and clearer
    /// error handling for connection operations.
    pub fn connect(self: Client, endpoint_url: []const u8) !void {
        // Use arena allocator to safely create null-terminated string for C API
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();

        // Allocate buffer and create null-terminated string
        const buf = try arena.allocator().alloc(u8, endpoint_url.len + 1);
        const c_url = try std.fmt.bufPrintZ(buf, "{s}", .{endpoint_url});

        const status = c.UA_Client_connect(self.handle, c_url.ptr);
        try ua_error.checkStatus(status);
    }

    /// Connect to an OPC UA server with authentication.
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
    pub fn connectWithAuth(self: Client, endpoint_url: []const u8, auth_config: AuthenticationConfig) !void {
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

                const status = c.UA_Client_connectUsername(self.handle, c_url.ptr, c_username.ptr, c_password.ptr);
                try ua_error.checkStatus(status);
            },
            .x509_certificate => |cert| {
                // X.509 certificate authentication
                // TODO: Implement certificate-based authentication
                // This requires setting up the client config with certificate and private key
                return error.NotImplemented;
            },
            .issued_token => |token| {
                // Issued token authentication
                // TODO: Implement token-based authentication
                return error.NotImplemented;
            },
        }
    }

    /// Simplified function to connect with username and password
    pub fn connectWithUsername(self: Client, endpoint_url: []const u8, username: []const u8, password: []const u8) !void {
        const auth_config = AuthenticationConfig{
            .identity_token = .{
                .username_password = .{
                    .username = username,
                    .password = password,
                },
            },
        };
        return self.connectWithAuth(endpoint_url, auth_config);
    }

    /// Simplified function to connect anonymously
    pub fn connectAnonymous(self: Client, endpoint_url: []const u8) !void {
        const auth_config = AuthenticationConfig{
            .identity_token = .anonymous,
        };
        return self.connectWithAuth(endpoint_url, auth_config);
    }

    /// Disconnect from the OPC UA server.
    ///
    /// This function closes the Session and SecureChannel with the server.
    /// It's safe to call this even if not connected.
    ///
    /// **Errors:**
    /// Returns errors from `ua_error.OpcUaError` if the disconnect operation fails.
    ///
    /// TODO: Unroll checkStatus and return explicit disconnect-specific errors instead
    /// of the full OpcUaError set. This would provide better type safety and clearer
    /// error handling for disconnect operations.
    pub fn disconnect(self: Client) !void {
        const status = c.UA_Client_disconnect(self.handle);
        try ua_error.checkStatus(status);
    }

    // ... rest of the existing Client methods would go here ...
    // For brevity, I'm including just the authentication methods
    // The full file would include all existing Client methods
};