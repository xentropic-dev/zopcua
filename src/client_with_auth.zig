const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");
const ua_error = @import("ua_error.zig");
const client_auth = @import("client_auth.zig");

/// Client wrapper with integrated authentication support.
/// This provides a more convenient API for authentication.
pub const Client = struct {
    handle: *c.UA_Client,
    allocator: std.mem.Allocator,

    /// Initialize a new client with authentication support.
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

    /// Deinitialize the client.
    pub fn deinit(self: *Client) void {
        c.UA_Client_delete(self.handle);
    }

    /// Connect to an OPC UA server.
    pub fn connect(self: *Client, endpoint_url: []const u8) !void {
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
        self: Client,
        endpoint_url: []const u8,
        username: []const u8,
        password: []const u8,
    ) !void {
        const auth_config = client_auth.AuthenticationConfig{
            .identity_token = .{
                .username_password = .{
                    .username = username,
                    .password = password,
                },
            },
        };
        return client_auth.connectWithAuth(self.handle, endpoint_url, auth_config);
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
        self: Client,
        endpoint_url: []const u8,
        auth_config: client_auth.AuthenticationConfig,
    ) !void {
        return client_auth.connectWithAuth(self.handle, endpoint_url, auth_config);
    }

    /// Simplified function to connect anonymously.
    pub fn connectAnonymous(self: Client, endpoint_url: []const u8) !void {
        return client_auth.connectAnonymous(self.handle, endpoint_url);
    }

    /// Disconnect from the OPC UA server.
    pub fn disconnect(self: *Client) void {
        c.UA_Client_disconnect(self.handle);
    }

    /// Read an attribute value from a node.
    pub fn readAttribute(
        self: *Client,
        node_id: c.UA_NodeId,
        attribute_id: u32,
    ) !c.UA_DataValue {
        // SAFETY: Variable is initialized by UA_Client_readValueAttribute
        var value: c.UA_DataValue = undefined;
        const status = c.UA_Client_readValueAttribute(
            self.handle,
            &node_id,
            &value,
        );
        try ua_error.checkStatus(status);
        return value;
    }

    /// Write an attribute value to a node.
    pub fn writeAttribute(
        self: *Client,
        node_id: c.UA_NodeId,
        attribute_id: u32,
        value: c.UA_DataValue,
    ) !void {
        var c_value = value;
        const status = c.UA_Client_writeValueAttribute(
            self.handle,
            &node_id,
            &c_value,
        );
        try ua_error.checkStatus(status);
    }

    /// Create a subscription for data change notifications.
    pub fn createSubscription(
        self: *Client,
        publishing_interval: f64,
        callback: fn (u32, u32, c.UA_DataValue, ?*anyopaque) void,
        userdata: ?*anyopaque,
    ) !u32 {
        var config: c.UA_CreateSubscriptionRequest = std.mem.zeroes(c.UA_CreateSubscriptionRequest);
        config.requestedPublishingInterval = publishing_interval;
        config.requestedLifetimeCount = 1000;
        config.requestedMaxKeepAliveCount = 10;
        config.maxNotificationsPerPublish = 1000;
        config.publishingEnabled = c.UA_TRUE;
        config.priority = 0;

        // SAFETY: Variable is initialized by UA_Client_Subscriptions_create
        var response: c.UA_CreateSubscriptionResponse = undefined;
        const status = c.UA_Client_Subscriptions_create(
            self.handle,
            config,
            null,
            null,
            &response,
        );
        try ua_error.checkStatus(status);

        return response.subscriptionId;
    }

    /// Monitor data changes on a node.
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

        // SAFETY: Variable is initialized by UA_Client_MonitoredItems_createDataChange
        var result: c.UA_MonitoredItemCreateResult = undefined;
        const status = c.UA_Client_MonitoredItems_createDataChange(
            self.handle,
            subscription_id,
            c.UA_TIMESTAMPSTORETURN_SOURCE,
            item,
            null,
            null,
            &result,
        );
        try ua_error.checkStatus(status);

        return result.monitoredItemId;
    }

    /// Delete a subscription.
    pub fn deleteSubscription(self: *Client, subscription_id: u32) !void {
        const status = c.UA_Client_Subscriptions_deleteSingle(
            self.handle,
            subscription_id,
        );
        try ua_error.checkStatus(status);
    }
};
