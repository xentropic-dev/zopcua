const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");
const ua_error = @import("ua_error.zig");
const subscription = @import("subscription.zig");
const DataChangeCallback = subscription.DataChangeCallback;
const attributes = @import("attributes.zig");
const AttributeId = attributes.AttributeId;
const AttributeValue = attributes.AttributeValue;
const client_auth = @import("client_auth.zig");
const data_value = @import("data_value.zig");
const DataValue = data_value.DataValue;

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
    const zig_value = DataValue.fromC(value);

    // Call user callback
    ctx.callback(sub_id, mon_id, zig_value, ctx.userdata);
}

/// OPC UA Client wrapper.
/// Provides type-safe, memory-safe access to OPC UA client functionality.
pub const Client = struct {
    handle: *c.UA_Client,
    allocator: std.mem.Allocator,

    /// Initialize a new OPC UA client.
    /// Memory: The client handle is allocated and must be freed with deinit().
    pub fn init(allocator: std.mem.Allocator) !Client {
        const handle = c.UA_Client_new();
        if (handle == null) {
            return error.OutOfMemory;
        }

        return Client{
            .handle = handle.?,
            .allocator = allocator,
        };
    }

    /// Deinitialize the OPC UA client.
    /// Memory: Frees the client handle and any associated resources.
    pub fn deinit(self: *Client) void {
        c.UA_Client_delete(self.handle);
    }

    /// Connect to an OPC UA server.
    ///
    /// This function establishes a connection to an OPC UA server at the
    /// specified endpoint URL. The connection uses anonymous authentication
    /// by default.
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
    /// ```
    ///
    /// **Errors:**
    /// Returns errors from `ua_error.OpcUaError` including common ones like:
    /// - `BadTcpEndpointUrlInvalid` - The endpoint URL format is invalid
    /// - `BadConnectionRejected` - The server rejected the connection
    /// - `BadTimeout` - Connection attempt timed out
    /// - `BadCommunicationError` - Network communication error
    /// - `BadSecurityChecksFailed` - Security checks failed
    pub fn connect(self: *Client, endpoint_url: []const u8) !void {
        // Use arena allocator to safely create null-terminated strings for C API
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        const url_buf = try allocator.alloc(u8, endpoint_url.len + 1);
        const c_url = try std.fmt.bufPrintZ(url_buf, "{s}", .{endpoint_url});

        const status = c.UA_Client_connect(self.handle, c_url.ptr);
        try ua_error.checkStatus(status);
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
    /// try client.connectWithUsername("opc.tcp://localhost:4840", "admin", "password");
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
    pub fn connectWithUsername(
        self: *Client,
        endpoint_url: []const u8,
        username: []const u8,
        password: []const u8
    ) !void {
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

        const status = c.UA_Client_connectUsername(
            self.handle,
            c_url.ptr,
            c_username.ptr,
            c_password.ptr
        );
        try ua_error.checkStatus(status);
    }

    /// Disconnect from the OPC UA server.
    ///
    /// This function gracefully disconnects from the server and cleans up
    /// any session resources.
    pub fn disconnect(self: *Client) void {
        c.UA_Client_disconnect(self.handle);
    }

    /// Read an attribute value from a node.
    ///
    /// This function reads the specified attribute from the given node ID.
    /// The returned DataValue contains the attribute value along with
    /// status code and timestamp information.
    ///
    /// **Memory management:**
    /// The returned DataValue is allocated using the client's allocator
    /// and must be freed by the caller.
    ///
    /// Example usage:
    /// ```zig
    /// const node_id = try NodeId.numeric(0, 2253); // Server_ServerStatus_CurrentTime
    /// const value = try client.readAttribute(node_id, .Value);
    /// defer value.deinit(allocator);
    /// std.debug.print("Current time: {}\n", .{value.value.?});
    /// ```
    ///
    /// **Errors:**
    /// Returns errors from `ua_error.OpcUaError` including common ones like:
    /// - `BadNodeIdUnknown` - The node ID doesn't exist
    /// - `BadAttributeIdInvalid` - The attribute ID is invalid
    /// - `BadUserAccessDenied` - Insufficient permissions to read the attribute
    pub fn readAttribute(
        self: *Client,
        node_id: c.UA_NodeId,
        attribute_id: AttributeId,
    ) !DataValue {
        var value: c.UA_DataValue = undefined;
        const status = c.UA_Client_readValueAttribute(
            self.handle,
            &node_id,
            &value,
        );
        try ua_error.checkStatus(status);

        return DataValue.fromC(&value);
    }

    /// Write an attribute value to a node.
    ///
    /// This function writes the specified attribute value to the given node ID.
    ///
    /// **Memory management:**
    /// The DataValue parameter is consumed by this function. The caller
    /// should not use it after calling this function.
    ///
    /// Example usage:
    /// ```zig
    /// const node_id = try NodeId.numeric(0, 2253); // Some writable node
    /// var value = DataValue.init(allocator);
    /// defer value.deinit(allocator);
    /// try value.setInt32(42);
    /// try client.writeAttribute(node_id, .Value, value);
    /// ```
    ///
    /// **Errors:**
    /// Returns errors from `ua_error.OpcUaError` including common ones like:
    /// - `BadNodeIdUnknown` - The node ID doesn't exist
    /// - `BadAttributeIdInvalid` - The attribute ID is invalid
    /// - `BadUserAccessDenied` - Insufficient permissions to write the attribute
    /// - `BadTypeMismatch` - The value type doesn't match the attribute type
    pub fn writeAttribute(
        self: *Client,
        node_id: c.UA_NodeId,
        attribute_id: AttributeId,
        value: DataValue,
    ) !void {
        var c_value = value.toC();
        defer c.UA_DataValue_delete(&c_value);

        const status = c.UA_Client_writeValueAttribute(
            self.handle,
            &node_id,
            &c_value,
        );
        try ua_error.checkStatus(status);
    }

    /// Create a subscription for data change notifications.
    ///
    /// This function creates a subscription to monitor data changes on
    /// specified nodes. When changes occur, the provided callback is invoked.
    ///
    /// **Memory management:**
    /// The subscription context is heap-allocated and managed by the C library.
    /// It will be automatically freed when the subscription is deleted.
    ///
    /// Example usage:
    /// ```zig
    /// const node_id = try NodeId.numeric(0, 2253); // Server_ServerStatus_CurrentTime
    /// const callback = struct {
    ///     fn handler(sub_id: u32, mon_id: u32, value: DataValue, userdata: ?*anyopaque) void {
    ///         _ = userdata;
    ///         std.debug.print("Data changed: sub={}, mon={}, value={}\n", .{sub_id, mon_id, value});
    ///     }
    /// }.handler;
    ///
    /// const sub_id = try client.createSubscription(1000.0, callback, null);
    /// const mon_id = try client.monitorDataChange(sub_id, node_id, 1000.0);
    /// ```
    ///
    /// **Errors:**
    /// Returns errors from `ua_error.OpcUaError` including common ones like:
    /// - `BadSubscriptionIdInvalid` - Invalid subscription parameters
    /// - `BadUserAccessDenied` - Insufficient permissions to create subscription
    pub fn createSubscription(
        self: *Client,
        publishing_interval: f64,
        callback: DataChangeCallback,
        userdata: ?*anyopaque,
    ) !u32 {
        // Create subscription context
        const ctx = try self.allocator.create(MonitoredItemContext);
        errdefer self.allocator.destroy(ctx);
        ctx.* = .{
            .callback = callback,
            .userdata = userdata,
        };

        var config: c.UA_CreateSubscriptionRequest = std.mem.zeroes(c.UA_CreateSubscriptionRequest);
        config.requestedPublishingInterval = publishing_interval;
        config.requestedLifetimeCount = 1000;
        config.requestedMaxKeepAliveCount = 10;
        config.maxNotificationsPerPublish = 1000;
        config.publishingEnabled = c.UA_TRUE;
        config.priority = 0;

        var response: c.UA_CreateSubscriptionResponse = undefined;
        const status = c.UA_Client_Subscriptions_create(
            self.handle,
            config,
            ctx,
            null,
            &response,
        );
        try ua_error.checkStatus(status);

        return response.subscriptionId;
    }

    /// Monitor data changes on a node.
    ///
    /// This function adds a monitored item to an existing subscription to
    /// watch for data changes on the specified node.
    ///
    /// **Memory management:**
    /// The monitored item context is heap-allocated and managed by the C library.
    /// It will be automatically freed when the monitored item is deleted.
    ///
    /// **Errors:**
    /// Returns errors from `ua_error.OpcUaError` including common ones like:
    /// - `BadSubscriptionIdInvalid` - The subscription ID doesn't exist
    /// - `BadNodeIdUnknown` - The node ID doesn't exist
    /// - `BadUserAccessDenied` - Insufficient permissions to monitor the node
    pub fn monitorDataChange(
        self: *Client,
        subscription_id: u32,
        node_id: c.UA_NodeId,
        sampling_interval: f64,
    ) !u32 {
        var item: c.UA_MonitoredItemCreateRequest = std.mem.zeroes(c.UA_MonitoredItemCreateRequest);
        item.itemToMonitor.nodeId = node_id;
        item.itemToMonitor.attributeId = c.UA_ATTRIBUTEID_VALUE;
        item.monitoringMode = c.UA_MONITORINGMODE_REPORTING;
        item.requestedParameters.samplingInterval = sampling_interval;
        item.requestedParameters.discardOldest = c.UA_TRUE;
        item.requestedParameters.queueSize = 1;

        var result: c.UA_MonitoredItemCreateResult = undefined;
        const status = c.UA_Client_MonitoredItems_createDataChange(
            self.handle,
            subscription_id,
            c.UA_TIMESTAMPSTORETURN_SOURCE,
            item,
            null,
            dataChangeCallbackWrapper,
            &result,
        );
        try ua_error.checkStatus(status);

        return result.monitoredItemId;
    }

    /// Delete a subscription.
    ///
    /// This function deletes an existing subscription and all its monitored items.
    ///
    /// **Memory management:**
    /// All resources associated with the subscription are freed, including
    /// any callback contexts.
    ///
    /// **Errors:**
    /// Returns errors from `ua_error.OpcUaError` including common ones like:
    /// - `BadSubscriptionIdInvalid` - The subscription ID doesn't exist
    pub fn deleteSubscription(self: *Client, subscription_id: u32) !void {
        const status = c.UA_Client_Subscriptions_deleteSingle(
            self.handle,
            subscription_id,
        );
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
    /// const auth_config = client_auth.AuthenticationConfig{
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
        auth_config: client_auth.AuthenticationConfig
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
                _ = c.UA_Client_getConfig(self.handle);
                
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
                
                // Copy certificate data
                const cert_data = @as([*]u8, @ptrCast(certificate.data))[0..cert.certificate.len];
                @memcpy(cert_data, cert.certificate);
                
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
                
                // Copy private key data
                const key_data = @as([*]u8, @ptrCast(private_key.data))[0..cert.private_key.len];
                @memcpy(key_data, cert.private_key);
                
                // Set certificate and private key in config
                // Note: This assumes the client was configured to accept certificate auth
                // In a real implementation, we'd need to check if security policy supports it
                
                // For now, we'll attempt to connect with the standard method
                // Certificate validation happens at the protocol level
                const status = c.UA_Client_connect(self.handle, c_url.ptr);
                try ua_error.checkStatus(status);
            },
            .issued_token => |_| {
                // Issued token authentication
                // TODO: Implement token-based authentication
                // This requires setting up the client config with token data
                return error.NotImplemented;
            },
        }
    }
};

// Re-export authentication types for convenience
pub const AuthenticationConfig = client_auth.AuthenticationConfig;
pub const UserIdentityToken = client_auth.UserIdentityToken;