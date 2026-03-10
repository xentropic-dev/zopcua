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

        // Allocate buffer and create null-terminated string for endpoint URL
        const url_buf = try allocator.alloc(u8, endpoint_url.len + 1);
        const c_url = try std.fmt.bufPrintZ(url_buf, "{s}", .{endpoint_url});

        const status = c.UA_Client_connect(self.handle, c_url);
        try ua_error.checkStatus(status);
    }

    /// Connect to an OPC UA server with username/password authentication.
    ///
    /// This function establishes a connection to an OPC UA server at the
    /// specified endpoint URL using username/password authentication.
    ///
    /// **Memory management:**
    /// This function handles all memory management internally using temporary allocations.
    /// No cleanup is required by the caller.
    ///
    /// Example usage:
    /// ```zig
    /// const client = try Client.init(allocator);
    /// defer client.deinit();
    /// try client.connectWithUsername("opc.tcp://localhost:4840", "admin", "secret");
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
        password: []const u8,
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
        const c_user = try std.fmt.bufPrintZ(user_buf, "{s}", .{username});

        const pass_buf = try allocator.alloc(u8, password.len + 1);
        const c_pass = try std.fmt.bufPrintZ(pass_buf, "{s}", .{password});

        const status = c.UA_Client_connectUsername(self.handle, c_url, c_user, c_pass);
        try ua_error.checkStatus(status);
    }

    /// Connect to an OPC UA server with X.509 certificate authentication.
    ///
    /// This function establishes a connection to an OPC UA server at the
    /// specified endpoint URL using X.509 certificate authentication.
    ///
    /// **Memory management:**
    /// This function handles all memory management internally using temporary allocations.
    /// No cleanup is required by the caller.
    ///
    /// Example usage:
    /// ```zig
    /// const client = try Client.init(allocator);
    /// defer client.deinit();
    /// const cert = try Certificate.loadFromFiles(
    ///     allocator,
    ///     "client_cert.der",
    ///     "client_key.der",
    /// );
    /// defer cert.deinit();
    /// try client.connectWithCertificate("opc.tcp://localhost:4840", cert);
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
    /// - `BadCertificateInvalid` - Certificate validation failed
    pub fn connectWithCertificate(
        self: *Client,
        endpoint_url: []const u8,
        certificate: client_auth.Certificate,
    ) !void {
        // Use arena allocator to safely create null-terminated strings for C API
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        // Allocate buffer and create null-terminated string for endpoint URL
        const url_buf = try allocator.alloc(u8, endpoint_url.len + 1);
        const c_url = try std.fmt.bufPrintZ(url_buf, "{s}", .{endpoint_url});

        // Convert certificate to C types
        var cert: c.UA_ByteString = undefined;
        var private_key: c.UA_ByteString = undefined;

        const cert_status = c.UA_ByteString_allocBuffer(
            &cert,
            @intCast(certificate.certificate.len),
        );
        try ua_error.checkStatus(cert_status);
        defer c.UA_ByteString_deleteMembers(&cert);

        const key_status = c.UA_ByteString_allocBuffer(
            &private_key,
            @intCast(certificate.private_key.len),
        );
        try ua_error.checkStatus(key_status);
        defer c.UA_ByteString_deleteMembers(&private_key);

        // Copy certificate data
        @memcpy(cert.data, certificate.certificate.ptr, certificate.certificate.len);
        cert.length = @intCast(certificate.certificate.len);

        // Copy private key data
        @memcpy(private_key.data, certificate.private_key.ptr, certificate.private_key.len);
        private_key.length = @intCast(certificate.private_key.len);

        const status = c.UA_Client_connectCertificate(
            self.handle,
            c_url,
            &cert,
            &private_key,
        );
        try ua_error.checkStatus(status);
    }

    /// Disconnect from the OPC UA server.
    ///
    /// This function disconnects from the currently connected OPC UA server.
    /// It should be called before deinitializing the client.
    ///
    /// **Memory management:**
    /// This function cleans up all connection-related resources.
    ///
    /// Example usage:
    /// ```zig
    /// const client = try Client.init(allocator);
    /// defer client.deinit();
    /// try client.connect("opc.tcp://localhost:4840");
    /// defer client.disconnect(); // Important: disconnect before deinit
    /// ```
    pub fn disconnect(self: *Client) void {
        c.UA_Client_disconnect(self.handle);
    }

    /// Read an attribute value from a node.
    ///
    /// This function reads the specified attribute from the given node ID.
    ///
    /// **Memory management:**
    /// The returned DataValue must be deinitialized with `deinit()` when no longer needed.
    ///
    /// Example usage:
    /// ```zig
    /// const node_id = try NodeId.numeric(0, 2253); // Server_ServerStatus_CurrentTime
    /// const value = try client.readAttribute(node_id, .Value);
    /// defer value.deinit(allocator);
    /// std.debug.print("Current time: {}\\n", .{value});
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
        // SAFETY: Variable is initialized by UA_Client_readValueAttribute
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
    ///         std.debug.print("Data changed: sub={}, mon={}, value={}\\n", .{sub_id, mon_id, value});
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
            @ptrCast(ctx),
            null,
            &response,
        );
        try ua_error.checkStatus(status);

        return response.subscriptionId;
    }

    /// Monitor data changes on a node.
    ///
    /// This function adds a monitored item to an existing subscription to
    /// track changes on a specific node.
    ///
    /// **Memory management:**
    /// The monitored item context is heap-allocated and managed by the C library.
    /// It will be automatically freed when the monitored item is deleted.
    ///
    /// Example usage:
    /// ```zig
    /// const sub_id = try client.createSubscription(1000.0, callback, null);
    /// const mon_id = try client.monitorDataChange(sub_id, node_id, 1000.0);
    /// ```
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
        item.requestedParameters.queueSize = 1;
        item.requestedParameters.discardOldest = c.UA_TRUE;

        var result: c.UA_MonitoredItemCreateResult = undefined;
        const status = c.UA_Client_MonitoredItems_createDataChange(
            self.handle,
            subscription_id,
            c.UA_TIMESTAMPSTORETURN_BOTH,
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
    /// All subscription-related resources are freed, including the context.
    ///
    /// Example usage:
    /// ```zig
    /// const sub_id = try client.createSubscription(1000.0, callback, null);
    /// // ... use subscription ...
    /// try client.deleteSubscription(sub_id);
    /// ```
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
}