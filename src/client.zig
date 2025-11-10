const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");
const ua_error = @import("ua_error.zig");
const NodeId = @import("types.zig").NodeId;
const Variant = @import("variant.zig").Variant;
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

    /// Writes a value attribute to the specified node.
    ///
    /// This function writes a new value to a variable node on the OPC UA server.
    /// The variant must contain data compatible with the node's declared data type.
    ///
    /// **Memory management:**
    /// This function handles all memory management internally using temporary allocations.
    /// No cleanup is required by the caller.
    ///
    /// Example usage:
    /// ```zig
    /// const new_value = Variant.scalar(f64, 42.5);
    /// try client.writeValueAttribute(node_id, new_value);
    /// ```
    ///
    /// **Errors:**
    /// Based on the underlying C implementation (`__UA_Client_writeAttribute`), this function
    /// can return the following errors:
    ///
    /// **Connection/Session Errors:**
    /// - `ServerNotConnected` - The client is not connected to a server
    /// - `SessionClosed` - The session has been closed
    /// - `Timeout` - The write operation timed out
    /// - `CommunicationError` - Network communication error occurred
    ///
    /// **Node/Attribute Errors:**
    /// - `NodeIdUnknown` - The specified node does not exist on the server
    /// - `NodeIdInvalid` - The node ID format is invalid
    /// - `AttributeIdInvalid` - The attribute ID is invalid
    /// - `NotWritable` - The node does not allow write access
    /// - `UserAccessDenied` - The current user does not have permission to write
    /// - `ObjectDeleted` - The node has been deleted
    /// - `NotFound` - The requested node was not found
    ///
    /// **Data Errors:**
    /// - `TypeMismatch` - Value type doesn't match the node's declared data type
    /// - `IndexRangeInvalid` - Invalid index range specified (if index range used)
    /// - `IndexRangeNoData` - No data exists in the specified index range
    /// - `DataEncodingInvalid` - The data encoding is invalid
    /// - `DataEncodingUnsupported` - The data encoding is not supported
    /// - `OutOfRange` - Value is outside the node's configured range
    ///
    /// **System Errors:**
    /// - `OutOfMemory` - Insufficient memory to complete the operation
    /// - `InternalError` - An internal server error occurred
    /// - `ServiceUnsupported` - The service is not supported
    /// - `SecurityChecksFailed` - Security checks failed
    /// - `UnexpectedError` - An unexpected error occurred (returned by the C code for
    ///   internal errors like wrong resultsSize)
    pub fn writeValueAttribute(self: Client, node_id: NodeId, variant: Variant) WriteAttributeError!void {
        // Convert the Variant to open62541's C representation and write it
        const status = blk: {
            var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            defer arena.deinit();

            // Create C variant using open62541's initialization functions
            var c_variant = variant.toC(arena.allocator()) catch {
                return WriteAttributeError.OutOfMemory;
            };
            // IMPORTANT: Must call UA_Variant_clear to free memory allocated by
            // open62541's UA_Variant_setScalarCopy/UA_Variant_setArrayCopy.
            // UA_Client_writeValueAttribute makes its own copy, so we're responsible
            // for cleaning up our temporary variant.
            defer c.UA_Variant_clear(&c_variant);

            const c_node_id = node_id.toC(arena.allocator()) catch {
                return WriteAttributeError.OutOfMemory;
            };
            // No explicit freeToC needed - arena.deinit() handles cleanup

            break :blk c.UA_Client_writeValueAttribute(self.handle, c_node_id, &c_variant);
        };

        // Map status codes to specific errors based on the C implementation
        // The C code can return:
        // 1. response.responseHeader.serviceResult (from UA_Client_Service_write)
        // 2. response.results[0] (the actual write result)
        // 3. UA_STATUSCODE_BADUNEXPECTEDERROR (if resultsSize != 1)
        // 4. UA_STATUSCODE_BADTYPEMISMATCH (if input is null)
        return switch (status) {
            c.UA_STATUSCODE_GOOD => {},

            // Connection/Session errors
            c.UA_STATUSCODE_BADSERVERNOTCONNECTED => WriteAttributeError.ServerNotConnected,
            c.UA_STATUSCODE_BADSESSIONCLOSED => WriteAttributeError.SessionClosed,
            c.UA_STATUSCODE_BADTIMEOUT => WriteAttributeError.Timeout,
            c.UA_STATUSCODE_BADREQUESTTIMEOUT => WriteAttributeError.Timeout,
            c.UA_STATUSCODE_BADCOMMUNICATIONERROR => WriteAttributeError.CommunicationError,

            // Node/Attribute errors
            c.UA_STATUSCODE_BADNODEIDUNKNOWN => WriteAttributeError.NodeIdUnknown,
            c.UA_STATUSCODE_BADNODEIDINVALID => WriteAttributeError.NodeIdInvalid,
            c.UA_STATUSCODE_BADATTRIBUTEIDINVALID => WriteAttributeError.AttributeIdInvalid,
            c.UA_STATUSCODE_BADNOTWRITABLE => WriteAttributeError.NotWritable,
            c.UA_STATUSCODE_BADUSERACCESSDENIED => WriteAttributeError.UserAccessDenied,
            c.UA_STATUSCODE_BADOBJECTDELETED => WriteAttributeError.ObjectDeleted,
            c.UA_STATUSCODE_BADNOTFOUND => WriteAttributeError.NotFound,

            // Data errors (especially important for write operations)
            c.UA_STATUSCODE_BADTYPEMISMATCH => WriteAttributeError.TypeMismatch,
            c.UA_STATUSCODE_BADINDEXRANGEINVALID => WriteAttributeError.IndexRangeInvalid,
            c.UA_STATUSCODE_BADINDEXRANGENODATA => WriteAttributeError.IndexRangeNoData,
            c.UA_STATUSCODE_BADDATAENCODINGINVALID => WriteAttributeError.DataEncodingInvalid,
            c.UA_STATUSCODE_BADDATAENCODINGUNSUPPORTED => WriteAttributeError.DataEncodingUnsupported,
            c.UA_STATUSCODE_BADOUTOFRANGE => WriteAttributeError.OutOfRange,

            // System errors
            c.UA_STATUSCODE_BADOUTOFMEMORY => WriteAttributeError.OutOfMemory,
            c.UA_STATUSCODE_BADINTERNALERROR => WriteAttributeError.InternalError,
            c.UA_STATUSCODE_BADSERVICEUNSUPPORTED => WriteAttributeError.ServiceUnsupported,
            c.UA_STATUSCODE_BADSECURITYCHECKSFAILED => WriteAttributeError.SecurityChecksFailed,

            // Catch-all for unexpected errors (including BADUNEXPECTEDERROR from C code)
            c.UA_STATUSCODE_BADUNEXPECTEDERROR => WriteAttributeError.UnexpectedError,
            else => WriteAttributeError.UnexpectedError,
        };
    }

    /// Reads the value attribute from the specified node.
    ///
    /// This function retrieves the current value of a variable node from the OPC UA server.
    /// The value is returned as a Variant which can contain any OPC UA data type.
    ///
    /// **Memory management:**
    /// The returned Variant deep-copies all data from the C library using the provided allocator.
    /// The caller MUST call `variant.deinit(allocator)` when done to free the allocated memory.
    ///
    /// Example usage:
    /// ```zig
    /// const variant = try client.readValueAttribute(allocator, node_id);
    /// defer variant.deinit(allocator);
    /// // Use variant...
    /// ```
    ///
    /// **Errors:**
    /// Based on the underlying C implementation (`__UA_Client_readAttribute`), this function
    /// can return the following errors:
    ///
    /// **Connection/Session Errors:**
    /// - `ServerNotConnected` - The client is not connected to a server
    /// - `SessionClosed` - The session has been closed
    /// - `Timeout` - The read operation timed out
    /// - `CommunicationError` - Network communication error occurred
    ///
    /// **Node/Attribute Errors:**
    /// - `NodeIdUnknown` - The specified node does not exist on the server
    /// - `NodeIdInvalid` - The node ID format is invalid
    /// - `AttributeIdInvalid` - The attribute ID is invalid
    /// - `NotReadable` - The node does not allow read access
    /// - `UserAccessDenied` - The current user does not have permission to read this node
    /// - `ObjectDeleted` - The node has been deleted
    /// - `NotFound` - The requested data was not found
    ///
    /// **Data Errors:**
    /// - `IndexRangeInvalid` - Invalid index range specified (if index range used)
    /// - `IndexRangeNoData` - No data exists in the specified index range
    /// - `DataEncodingInvalid` - The data encoding is invalid
    /// - `DataEncodingUnsupported` - The data encoding is not supported
    ///
    /// **System Errors:**
    /// - `OutOfMemory` - Insufficient memory to complete the operation
    /// - `InternalError` - An internal server error occurred
    /// - `ServiceUnsupported` - The service is not supported
    /// - `SecurityChecksFailed` - Security checks failed
    /// - `UnexpectedError` - An unexpected error occurred (returned by the C code for
    ///   internal errors like wrong resultsSize or missing value when one was expected)
    pub fn readValueAttribute(self: Client, allocator: std.mem.Allocator, node_id: NodeId) ReadAttributeError!Variant {
        // SAFETY: c_variant is initialized immediately by UA_Variant_init before any use
        var c_variant: c.UA_Variant = undefined;
        c.UA_Variant_init(&c_variant);

        // Use internal arena for temporary NodeId conversion
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();

        const c_node_id = node_id.toC(arena.allocator()) catch {
            return ReadAttributeError.OutOfMemory;
        };
        // No explicit freeToC needed - arena.deinit() handles cleanup

        const status = c.UA_Client_readValueAttribute(self.handle, c_node_id, &c_variant);

        // Map status codes to specific errors based on the C implementation
        // The C code can return:
        // 1. response.responseHeader.serviceResult (from UA_Client_Service_read)
        // 2. response.results[0].status (the actual read result)
        // 3. UA_STATUSCODE_BADUNEXPECTEDERROR (if resultsSize != 1 or !hasValue)
        return switch (status) {
            c.UA_STATUSCODE_GOOD => blk: {
                // The C code transfers ownership of the variant's heap data to us.
                // Convert it to a Zig variant (deep-copying all data), then clean up the C variant.
                const result = Variant.fromC(c_variant, allocator) catch {
                    // If conversion fails, clean up the C variant before propagating the error
                    c.UA_Variant_clear(&c_variant);
                    return ReadAttributeError.OutOfMemory;
                };
                // Clean up the C-allocated memory now that we've deep-copied
                c.UA_Variant_clear(&c_variant);
                break :blk result;
            },

            // Connection/Session errors
            c.UA_STATUSCODE_BADSERVERNOTCONNECTED => ReadAttributeError.ServerNotConnected,
            c.UA_STATUSCODE_BADSESSIONCLOSED => ReadAttributeError.SessionClosed,
            c.UA_STATUSCODE_BADTIMEOUT => ReadAttributeError.Timeout,
            c.UA_STATUSCODE_BADREQUESTTIMEOUT => ReadAttributeError.Timeout,
            c.UA_STATUSCODE_BADCOMMUNICATIONERROR => ReadAttributeError.CommunicationError,

            // Node/Attribute errors
            c.UA_STATUSCODE_BADNODEIDUNKNOWN => ReadAttributeError.NodeIdUnknown,
            c.UA_STATUSCODE_BADNODEIDINVALID => ReadAttributeError.NodeIdInvalid,
            c.UA_STATUSCODE_BADATTRIBUTEIDINVALID => ReadAttributeError.AttributeIdInvalid,
            c.UA_STATUSCODE_BADNOTREADABLE => ReadAttributeError.NotReadable,
            c.UA_STATUSCODE_BADUSERACCESSDENIED => ReadAttributeError.UserAccessDenied,
            c.UA_STATUSCODE_BADOBJECTDELETED => ReadAttributeError.ObjectDeleted,
            c.UA_STATUSCODE_BADNOTFOUND => ReadAttributeError.NotFound,

            // Data errors
            c.UA_STATUSCODE_BADINDEXRANGEINVALID => ReadAttributeError.IndexRangeInvalid,
            c.UA_STATUSCODE_BADINDEXRANGENODATA => ReadAttributeError.IndexRangeNoData,
            c.UA_STATUSCODE_BADDATAENCODINGINVALID => ReadAttributeError.DataEncodingInvalid,
            c.UA_STATUSCODE_BADDATAENCODINGUNSUPPORTED => ReadAttributeError.DataEncodingUnsupported,

            // System errors
            c.UA_STATUSCODE_BADOUTOFMEMORY => ReadAttributeError.OutOfMemory,
            c.UA_STATUSCODE_BADINTERNALERROR => ReadAttributeError.InternalError,
            c.UA_STATUSCODE_BADSERVICEUNSUPPORTED => ReadAttributeError.ServiceUnsupported,
            c.UA_STATUSCODE_BADSECURITYCHECKSFAILED => ReadAttributeError.SecurityChecksFailed,

            // Catch-all for unexpected errors (including BADUNEXPECTEDERROR from C code)
            c.UA_STATUSCODE_BADUNEXPECTEDERROR => ReadAttributeError.UnexpectedError,
            else => ReadAttributeError.UnexpectedError,
        };
    }

    /// Browse nodes starting from the specified node with a simple interface.
    ///
    /// This is a convenience wrapper around `browseWithDescription()` that uses default
    /// browse parameters (forward direction, all reference types, all node classes).
    ///
    /// **Memory management:**
    /// The returned BrowseResult deep-copies all data from the C library using the provided allocator.
    /// The caller MUST call `result.deinit(allocator)` when done to free the allocated memory.
    ///
    /// Example usage:
    /// ```zig
    /// const result = try client.browse(allocator, StandardNodeId.objects_folder);
    /// defer result.deinit(allocator);
    /// for (result.references) |ref| {
    ///     std.log.info("Found: {s}", .{ref.browse_name.name});
    /// }
    /// ```
    ///
    /// **Errors:**
    /// See `BrowseError` for the complete list of possible errors.
    pub fn browse(self: Client, allocator: std.mem.Allocator, node_id: NodeId) BrowseError!BrowseResult {
        const desc = BrowseDescription{
            .node_id = node_id,
        };
        return self.browseWithDescription(allocator, desc, 0);
    }

    /// Browse nodes with full control over browse parameters.
    ///
    /// This function provides complete control over the browse operation, allowing you to
    /// specify the browse direction, reference types, node class filters, and more.
    ///
    /// **Memory management:**
    /// The returned BrowseResult deep-copies all data from the C library using the provided allocator.
    /// The caller MUST call `result.deinit(allocator)` when done to free the allocated memory.
    ///
    /// **Parameters:**
    /// - `allocator`: Memory allocator for result data
    /// - `description`: Browse parameters including node, direction, and filters
    /// - `max_references`: Maximum number of references to return (0 = no limit)
    ///
    /// Example usage:
    /// ```zig
    /// const desc = BrowseDescription{
    ///     .node_id = StandardNodeId.objects_folder,
    ///     .browse_direction = .forward,
    ///     .reference_type_id = ReferenceType.organizes,
    ///     .include_subtypes = true,
    ///     .node_class_mask = .objects_only,
    /// };
    /// const result = try client.browseWithDescription(allocator, desc, 100);
    /// defer result.deinit(allocator);
    /// ```
    ///
    /// **Errors:**
    /// Based on the underlying C implementation (`UA_Client_Service_browse`), this function
    /// can return the following errors:
    ///
    /// **Connection/Session Errors:**
    /// - `ServerNotConnected` - The client is not connected to a server
    /// - `SessionClosed` - The session has been closed
    /// - `Timeout` - The browse operation timed out
    /// - `CommunicationError` - Network communication error occurred
    ///
    /// **Node/Browse Errors:**
    /// - `NodeIdUnknown` - The specified node does not exist on the server
    /// - `NodeIdInvalid` - The node ID format is invalid
    /// - `BrowseDirectionInvalid` - The browse direction is invalid
    /// - `ReferenceTypeIdInvalid` - The reference type ID is invalid
    /// - `UserAccessDenied` - The current user does not have permission to browse
    /// - `ObjectDeleted` - The node has been deleted
    /// - `NotFound` - The requested node was not found
    ///
    /// **System Errors:**
    /// - `OutOfMemory` - Insufficient memory to complete the operation
    /// - `InternalError` - An internal server error occurred
    /// - `ServiceUnsupported` - The service is not supported
    /// - `SecurityChecksFailed` - Security checks failed
    /// - `UnexpectedError` - An unexpected error occurred
    pub fn browseWithDescription(
        self: Client,
        allocator: std.mem.Allocator,
        description: BrowseDescription,
        max_references: u32,
    ) BrowseError!BrowseResult {
        // Use arena allocator for temporary C conversions
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();

        // Convert BrowseDescription to C
        const c_desc = description.toC(arena.allocator()) catch {
            return BrowseError.OutOfMemory;
        };
        // No explicit freeToC needed - arena.deinit() handles cleanup

        // Create browse request
        // SAFETY: request is immediately initialized by UA_BrowseRequest_init before any use
        var request: c.UA_BrowseRequest = undefined;
        c.UA_BrowseRequest_init(&request);
        request.requestedMaxReferencesPerNode = max_references;
        request.nodesToBrowseSize = 1;
        request.nodesToBrowse = @constCast(&c_desc);

        // Execute browse
        const response = c.UA_Client_Service_browse(self.handle, request);
        defer c.UA_BrowseResponse_clear(@constCast(&response));

        // Check service-level status
        if (response.responseHeader.serviceResult != c.UA_STATUSCODE_GOOD) {
            return mapBrowseError(response.responseHeader.serviceResult);
        }

        // Check that we got exactly one result
        if (response.resultsSize != 1) {
            return BrowseError.UnexpectedError;
        }

        // Convert result from C (deep-copies all data)
        return BrowseResult.fromC(response.results[0], allocator) catch {
            return BrowseError.OutOfMemory;
        };
    }

    /// Continue a browse operation using a continuation point.
    ///
    /// When a browse operation returns more results than can fit in a single response,
    /// the server provides a continuation point. Use this method to retrieve the remaining results.
    ///
    /// **Memory management:**
    /// The returned BrowseResult deep-copies all data from the C library using the provided allocator.
    /// The caller MUST call `result.deinit(allocator)` when done to free the allocated memory.
    ///
    /// **Parameters:**
    /// - `allocator`: Memory allocator for result data
    /// - `continuation_point`: The continuation point from a previous browse result
    ///
    /// Example usage:
    /// ```zig
    /// var result = try client.browse(allocator, node_id);
    /// defer result.deinit(allocator);
    ///
    /// while (result.continuation_point) |cp| {
    ///     const next = try client.browseNext(allocator, cp);
    ///     result.deinit(allocator);
    ///     result = next;
    /// }
    /// ```
    ///
    /// **Errors:**
    /// See `BrowseError` for the complete list of possible errors.
    pub fn browseNext(
        self: Client,
        allocator: std.mem.Allocator,
        continuation_point: []const u8,
    ) BrowseError!BrowseResult {
        // Create browse next request
        // SAFETY: request is immediately initialized by UA_BrowseNextRequest_init before any use
        var request: c.UA_BrowseNextRequest = undefined;
        c.UA_BrowseNextRequest_init(&request);
        request.releaseContinuationPoints = false;
        request.continuationPointsSize = 1;

        // Create C ByteString for continuation point
        var c_cp: c.UA_ByteString = .{
            .length = continuation_point.len,
            .data = @constCast(continuation_point.ptr),
        };
        request.continuationPoints = &c_cp;

        // Execute browse next
        const response = c.UA_Client_Service_browseNext(self.handle, request);
        defer c.UA_BrowseNextResponse_clear(@constCast(&response));

        // Check service-level status
        if (response.responseHeader.serviceResult != c.UA_STATUSCODE_GOOD) {
            return mapBrowseError(response.responseHeader.serviceResult);
        }

        // Check that we got exactly one result
        if (response.resultsSize != 1) {
            return BrowseError.UnexpectedError;
        }

        // Convert result from C (deep-copies all data)
        return BrowseResult.fromC(response.results[0], allocator) catch {
            return BrowseError.OutOfMemory;
        };
    }

    /// Get the namespace index for a given URI from the connected server.
    ///
    /// Queries the server's namespace table for a matching URI and returns its index.
    /// This is useful for dynamically discovering namespace indices at runtime instead
    /// of hardcoding them, especially when connecting to servers with varying configurations.
    ///
    /// **Memory management:**
    /// This function uses internal temporary allocations only. No cleanup is required by the caller.
    ///
    /// **Parameters:**
    /// - `namespace_uri`: URI string to search for (e.g., "http://example.com/sensors")
    ///
    /// **Returns:**
    /// - The namespace index if found (typically 0 for OPC UA standard, 1 for server default, 2+ for custom)
    ///
    /// **Errors:**
    /// - `InvalidNamespaceUri` - Empty or null URI provided
    /// - `NamespaceNotFound` - No namespace with this URI exists on the server
    /// - `ServerNotConnected` - The client is not connected to a server
    /// - `SessionClosed` - The session has been closed
    /// - `Timeout` - The operation timed out
    /// - `CommunicationError` - Network communication error occurred
    /// - `OutOfMemory` - Insufficient memory to complete the operation
    /// - `InternalError` - An internal error occurred
    /// - `ServiceUnsupported` - The service is not supported by the server
    /// - `UnexpectedError` - An unexpected error occurred
    ///
    /// **Example usage:**
    /// ```zig
    /// var client = try Client.init();
    /// defer client.deinit();
    /// try client.connect("opc.tcp://localhost:4840");
    /// defer client.disconnect() catch {};
    ///
    /// // Dynamically discover the namespace index
    /// const ns_idx = try client.getNamespaceByName("http://example.com/sensors");
    /// std.debug.print("Sensors namespace is at index: {d}\n", .{ns_idx});
    ///
    /// // Use the discovered index to construct NodeIds
    /// const node_id = NodeId.initString(ns_idx, "temperature");
    /// const value = try client.readValueAttribute(allocator, node_id);
    /// defer value.deinit(allocator);
    /// ```
    pub fn getNamespaceByName(
        self: Client,
        namespace_uri: []const u8,
    ) NamespaceError!u16 {
        if (namespace_uri.len == 0) return NamespaceError.InvalidNamespaceUri;

        // Convert URI to UA_String
        var c_uri = c.UA_String{
            .length = namespace_uri.len,
            .data = @constCast(namespace_uri.ptr),
        };

        var found_index: u16 = 0;
        const status = c.UA_Client_NamespaceGetIndex(
            self.handle,
            &c_uri,
            &found_index,
        );

        return switch (status) {
            c.UA_STATUSCODE_GOOD => found_index,

            // Namespace not found
            c.UA_STATUSCODE_BADNOTFOUND => NamespaceError.NamespaceNotFound,

            // Connection/Session errors
            c.UA_STATUSCODE_BADSERVERNOTCONNECTED => NamespaceError.ServerNotConnected,
            c.UA_STATUSCODE_BADSESSIONCLOSED => NamespaceError.SessionClosed,
            c.UA_STATUSCODE_BADTIMEOUT => NamespaceError.Timeout,
            c.UA_STATUSCODE_BADREQUESTTIMEOUT => NamespaceError.Timeout,
            c.UA_STATUSCODE_BADCOMMUNICATIONERROR => NamespaceError.CommunicationError,

            // System errors
            c.UA_STATUSCODE_BADOUTOFMEMORY => NamespaceError.OutOfMemory,
            c.UA_STATUSCODE_BADINTERNALERROR => NamespaceError.InternalError,
            c.UA_STATUSCODE_BADSERVICEUNSUPPORTED => NamespaceError.ServiceUnsupported,

            // Catch-all
            else => NamespaceError.UnexpectedError,
        };
    }

    /// Create a new subscription on the server.
    ///
    /// This creates a subscription that can be used to monitor nodes for changes.
    /// The subscription will send notifications when monitored nodes change.
    ///
    /// **Memory management:**
    /// This function uses internal temporary allocations only. No cleanup required by caller.
    /// The subscription ID is a scalar value owned by the server.
    ///
    /// **Parameters:**
    /// - `params`: Subscription configuration parameters
    ///
    /// **Returns:**
    /// - The subscription ID on success
    ///
    /// **Errors:**
    /// - See `SubscriptionError` for possible errors
    ///
    /// **Example:**
    /// ```zig
    /// const sub_id = try client.createSubscription(.{
    ///     .publishing_interval = 1000.0,  // 1 second
    ///     .priority = 10,
    /// });
    /// defer client.deleteSubscription(sub_id) catch {};
    /// ```
    pub fn createSubscription(
        self: Client,
        params: SubscriptionParameters,
    ) SubscriptionError!SubscriptionId {
        // Create subscription request with default settings
        var request = c.UA_CreateSubscriptionRequest_default();
        request.requestedPublishingInterval = params.publishing_interval;
        request.requestedMaxKeepAliveCount = params.max_keep_alive_count;
        request.requestedLifetimeCount = params.lifetime_count;
        request.maxNotificationsPerPublish = params.max_notifications_per_publish;
        request.publishingEnabled = true;
        request.priority = params.priority;

        // Create subscription - returns response struct
        const response = c.UA_Client_Subscriptions_create(
            self.handle,
            request,
            null, // context
            null, // status change callback
            null, // delete callback
        );

        return switch (response.responseHeader.serviceResult) {
            c.UA_STATUSCODE_GOOD => response.subscriptionId,
            c.UA_STATUSCODE_BADSERVERNOTCONNECTED => SubscriptionError.ServerNotConnected,
            c.UA_STATUSCODE_BADSESSIONCLOSED => SubscriptionError.SessionClosed,
            c.UA_STATUSCODE_BADTIMEOUT => SubscriptionError.Timeout,
            c.UA_STATUSCODE_BADREQUESTTIMEOUT => SubscriptionError.Timeout,
            c.UA_STATUSCODE_BADCOMMUNICATIONERROR => SubscriptionError.CommunicationError,
            c.UA_STATUSCODE_BADINVALIDARGUMENT => SubscriptionError.InvalidParameters,
            c.UA_STATUSCODE_BADTOOMANYSUBSCRIPTIONS => SubscriptionError.TooManySubscriptions,
            c.UA_STATUSCODE_BADOUTOFMEMORY => SubscriptionError.OutOfMemory,
            c.UA_STATUSCODE_BADINTERNALERROR => SubscriptionError.InternalError,
            c.UA_STATUSCODE_BADSERVICEUNSUPPORTED => SubscriptionError.ServiceUnsupported,
            c.UA_STATUSCODE_BADSECURITYCHECKSFAILED => SubscriptionError.SecurityChecksFailed,
            else => SubscriptionError.UnexpectedError,
        };
    }

    /// Delete an existing subscription from the server.
    ///
    /// This removes the subscription and all its monitored items. The server will
    /// stop sending notifications for this subscription.
    ///
    /// **Memory management:**
    /// This function uses internal temporary allocations only. No cleanup required by caller.
    ///
    /// **Parameters:**
    /// - `subscription_id`: The subscription ID to delete
    ///
    /// **Errors:**
    /// - See `SubscriptionError` for possible errors
    ///
    /// **Example:**
    /// ```zig
    /// try client.deleteSubscription(sub_id);
    /// ```
    pub fn deleteSubscription(
        self: Client,
        subscription_id: SubscriptionId,
    ) SubscriptionError!void {
        const status = c.UA_Client_Subscriptions_deleteSingle(self.handle, subscription_id);

        return switch (status) {
            c.UA_STATUSCODE_GOOD => {},
            c.UA_STATUSCODE_BADSERVERNOTCONNECTED => SubscriptionError.ServerNotConnected,
            c.UA_STATUSCODE_BADSESSIONCLOSED => SubscriptionError.SessionClosed,
            c.UA_STATUSCODE_BADTIMEOUT => SubscriptionError.Timeout,
            c.UA_STATUSCODE_BADREQUESTTIMEOUT => SubscriptionError.Timeout,
            c.UA_STATUSCODE_BADCOMMUNICATIONERROR => SubscriptionError.CommunicationError,
            c.UA_STATUSCODE_BADSUBSCRIPTIONIDINVALID => SubscriptionError.SubscriptionNotFound,
            c.UA_STATUSCODE_BADOUTOFMEMORY => SubscriptionError.OutOfMemory,
            c.UA_STATUSCODE_BADINTERNALERROR => SubscriptionError.InternalError,
            c.UA_STATUSCODE_BADSERVICEUNSUPPORTED => SubscriptionError.ServiceUnsupported,
            c.UA_STATUSCODE_BADSECURITYCHECKSFAILED => SubscriptionError.SecurityChecksFailed,
            else => SubscriptionError.UnexpectedError,
        };
    }

    /// Create a monitored item for data change notifications.
    ///
    /// This adds a node to be monitored within a subscription. When the node's value
    /// changes, the client will receive notifications.
    ///
    /// **Memory management:**
    /// This function uses internal temporary allocations only. No cleanup required by caller.
    /// The monitored item ID is a scalar value owned by the server.
    ///
    /// **Parameters:**
    /// - `subscription_id`: The subscription to add this monitored item to
    /// - `params`: Monitored item configuration
    ///
    /// **Returns:**
    /// - The monitored item ID on success
    ///
    /// **Errors:**
    /// - See `MonitoredItemError` for possible errors
    ///
    /// **Example:**
    /// ```zig
    /// const mon_id = try client.createMonitoredItem(sub_id, .{
    ///     .node_id = NodeId.initString(1, "temperature"),
    ///     .sampling_interval = 100.0,  // 100ms
    ///     .queue_size = 10,
    /// });
    /// defer client.deleteMonitoredItem(sub_id, mon_id) catch {};
    /// ```
    pub fn createMonitoredItem(
        self: Client,
        subscription_id: SubscriptionId,
        params: MonitoredItemParameters,
    ) MonitoredItemError!MonitoredItemId {
        // Use internal arena for temporary C conversions
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();

        // Convert NodeId to C
        const c_node_id = params.node_id.toC(arena.allocator()) catch {
            return MonitoredItemError.OutOfMemory;
        };
        // No explicit freeToC needed - arena.deinit() handles cleanup

        // Create monitored item request
        var request = c.UA_MonitoredItemCreateRequest_default(c_node_id);
        request.itemToMonitor.attributeId = params.attribute_id;
        request.monitoringMode = params.monitoring_mode.toC();
        request.requestedParameters.samplingInterval = params.sampling_interval;
        request.requestedParameters.queueSize = params.queue_size;
        request.requestedParameters.discardOldest = params.discard_oldest;

        // Create monitored item (callback can be null for polling) - returns result struct
        const result = c.UA_Client_MonitoredItems_createDataChange(
            self.handle,
            subscription_id,
            c.UA_TIMESTAMPSTORETURN_BOTH,
            request,
            null, // context
            null, // callback
            null, // delete callback
        );

        return switch (result.statusCode) {
            c.UA_STATUSCODE_GOOD => result.monitoredItemId,
            c.UA_STATUSCODE_BADSERVERNOTCONNECTED => MonitoredItemError.ServerNotConnected,
            c.UA_STATUSCODE_BADSESSIONCLOSED => MonitoredItemError.SessionClosed,
            c.UA_STATUSCODE_BADTIMEOUT => MonitoredItemError.Timeout,
            c.UA_STATUSCODE_BADREQUESTTIMEOUT => MonitoredItemError.Timeout,
            c.UA_STATUSCODE_BADCOMMUNICATIONERROR => MonitoredItemError.CommunicationError,
            c.UA_STATUSCODE_BADNODEIDUNKNOWN => MonitoredItemError.NodeIdUnknown,
            c.UA_STATUSCODE_BADNODEIDINVALID => MonitoredItemError.NodeIdInvalid,
            c.UA_STATUSCODE_BADINVALIDARGUMENT => MonitoredItemError.InvalidParameters,
            c.UA_STATUSCODE_BADSUBSCRIPTIONIDINVALID => MonitoredItemError.SubscriptionIdInvalid,
            c.UA_STATUSCODE_BADATTRIBUTEIDINVALID => MonitoredItemError.AttributeNotSupported,
            c.UA_STATUSCODE_BADTOOMANYMONITOREDITEMS => MonitoredItemError.TooManyMonitoredItems,
            c.UA_STATUSCODE_BADOUTOFMEMORY => MonitoredItemError.OutOfMemory,
            c.UA_STATUSCODE_BADINTERNALERROR => MonitoredItemError.InternalError,
            c.UA_STATUSCODE_BADSERVICEUNSUPPORTED => MonitoredItemError.ServiceUnsupported,
            c.UA_STATUSCODE_BADSECURITYCHECKSFAILED => MonitoredItemError.SecurityChecksFailed,
            else => MonitoredItemError.UnexpectedError,
        };
    }

    /// Delete a monitored item from a subscription.
    ///
    /// This removes the monitored item and stops receiving notifications for it.
    ///
    /// **Memory management:**
    /// This function uses internal temporary allocations only. No cleanup required by caller.
    ///
    /// **Parameters:**
    /// - `subscription_id`: The subscription containing this monitored item
    /// - `monitored_item_id`: The monitored item ID to delete
    ///
    /// **Errors:**
    /// - See `MonitoredItemError` for possible errors
    ///
    /// **Example:**
    /// ```zig
    /// try client.deleteMonitoredItem(sub_id, mon_id);
    /// ```
    pub fn deleteMonitoredItem(
        self: Client,
        subscription_id: SubscriptionId,
        monitored_item_id: MonitoredItemId,
    ) MonitoredItemError!void {
        const status = c.UA_Client_MonitoredItems_deleteSingle(
            self.handle,
            subscription_id,
            monitored_item_id,
        );

        return switch (status) {
            c.UA_STATUSCODE_GOOD => {},
            c.UA_STATUSCODE_BADSERVERNOTCONNECTED => MonitoredItemError.ServerNotConnected,
            c.UA_STATUSCODE_BADSESSIONCLOSED => MonitoredItemError.SessionClosed,
            c.UA_STATUSCODE_BADTIMEOUT => MonitoredItemError.Timeout,
            c.UA_STATUSCODE_BADREQUESTTIMEOUT => MonitoredItemError.Timeout,
            c.UA_STATUSCODE_BADCOMMUNICATIONERROR => MonitoredItemError.CommunicationError,
            c.UA_STATUSCODE_BADSUBSCRIPTIONIDINVALID => MonitoredItemError.SubscriptionIdInvalid,
            c.UA_STATUSCODE_BADMONITOREDITEMIDINVALID => MonitoredItemError.MonitoredItemNotFound,
            c.UA_STATUSCODE_BADOUTOFMEMORY => MonitoredItemError.OutOfMemory,
            c.UA_STATUSCODE_BADINTERNALERROR => MonitoredItemError.InternalError,
            c.UA_STATUSCODE_BADSERVICEUNSUPPORTED => MonitoredItemError.ServiceUnsupported,
            c.UA_STATUSCODE_BADSECURITYCHECKSFAILED => MonitoredItemError.SecurityChecksFailed,
            else => MonitoredItemError.UnexpectedError,
        };
    }

    /// Create a monitored item with a callback for real-time data change notifications.
    ///
    /// This adds a node to be monitored within a subscription. When the node's value
    /// changes, your callback will be invoked automatically with the new value.
    ///
    /// **Memory management:**
    /// This function allocates an internal context structure that lives until the monitored
    /// item is deleted (either explicitly or when the subscription/connection is closed).
    /// The context is automatically freed by the delete callback. No cleanup required by caller.
    ///
    /// **Parameters:**
    /// - `subscription_id`: The subscription to add this monitored item to
    /// - `params`: Monitored item configuration
    /// - `callback`: Function to call when value changes
    /// - `userdata`: Optional user context pointer passed to callback
    ///
    /// **Returns:**
    /// - The monitored item ID on success
    ///
    /// **Errors:**
    /// - See `MonitoredItemError` for possible errors
    ///
    /// **Example:**
    /// ```zig
    /// fn myCallback(
    ///     userdata: ?*anyopaque,
    ///     sub_id: SubscriptionId,
    ///     mon_id: MonitoredItemId,
    ///     value: *const Variant,
    /// ) void {
    ///     _ = sub_id;
    ///     _ = mon_id;
    ///     std.debug.print("Value changed: {}\n", .{value.*});
    /// }
    ///
    /// const mon_id = try client.createMonitoredItemWithCallback(
    ///     sub_id,
    ///     .{ .node_id = NodeId.initString(1, "temperature") },
    ///     myCallback,
    ///     null,
    /// );
    /// ```
    pub fn createMonitoredItemWithCallback(
        self: Client,
        subscription_id: SubscriptionId,
        params: MonitoredItemParameters,
        callback: DataChangeCallback,
        userdata: ?*anyopaque,
    ) MonitoredItemError!MonitoredItemId {
        // Allocate context structure to hold callback and userdata
        const ctx = std.heap.c_allocator.create(MonitoredItemContext) catch {
            return MonitoredItemError.OutOfMemory;
        };
        errdefer std.heap.c_allocator.destroy(ctx);

        ctx.* = .{
            .callback = callback,
            .userdata = userdata,
        };

        // Use internal arena for temporary C conversions
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();

        // Convert NodeId to C
        const c_node_id = params.node_id.toC(arena.allocator()) catch {
            std.heap.c_allocator.destroy(ctx);
            return MonitoredItemError.OutOfMemory;
        };

        // Create monitored item request
        var request = c.UA_MonitoredItemCreateRequest_default(c_node_id);
        request.itemToMonitor.attributeId = params.attribute_id;
        request.monitoringMode = params.monitoring_mode.toC();
        request.requestedParameters.samplingInterval = params.sampling_interval;
        request.requestedParameters.queueSize = params.queue_size;
        request.requestedParameters.discardOldest = params.discard_oldest;

        // Create monitored item with callback - returns result struct
        const result = c.UA_Client_MonitoredItems_createDataChange(
            self.handle,
            subscription_id,
            c.UA_TIMESTAMPSTORETURN_BOTH,
            request,
            ctx, // context will be passed to callbacks
            dataChangeCallbackWrapper,
            deleteMonitoredItemCallbackWrapper,
        );

        // Check status before returning
        if (result.statusCode != c.UA_STATUSCODE_GOOD) {
            // Failed to create - free the context
            std.heap.c_allocator.destroy(ctx);
        }

        return switch (result.statusCode) {
            c.UA_STATUSCODE_GOOD => result.monitoredItemId,
            c.UA_STATUSCODE_BADSERVERNOTCONNECTED => MonitoredItemError.ServerNotConnected,
            c.UA_STATUSCODE_BADSESSIONCLOSED => MonitoredItemError.SessionClosed,
            c.UA_STATUSCODE_BADTIMEOUT => MonitoredItemError.Timeout,
            c.UA_STATUSCODE_BADREQUESTTIMEOUT => MonitoredItemError.Timeout,
            c.UA_STATUSCODE_BADCOMMUNICATIONERROR => MonitoredItemError.CommunicationError,
            c.UA_STATUSCODE_BADNODEIDUNKNOWN => MonitoredItemError.NodeIdUnknown,
            c.UA_STATUSCODE_BADNODEIDINVALID => MonitoredItemError.NodeIdInvalid,
            c.UA_STATUSCODE_BADINVALIDARGUMENT => MonitoredItemError.InvalidParameters,
            c.UA_STATUSCODE_BADSUBSCRIPTIONIDINVALID => MonitoredItemError.SubscriptionIdInvalid,
            c.UA_STATUSCODE_BADATTRIBUTEIDINVALID => MonitoredItemError.AttributeNotSupported,
            c.UA_STATUSCODE_BADTOOMANYMONITOREDITEMS => MonitoredItemError.TooManyMonitoredItems,
            c.UA_STATUSCODE_BADOUTOFMEMORY => MonitoredItemError.OutOfMemory,
            c.UA_STATUSCODE_BADINTERNALERROR => MonitoredItemError.InternalError,
            c.UA_STATUSCODE_BADSERVICEUNSUPPORTED => MonitoredItemError.ServiceUnsupported,
            c.UA_STATUSCODE_BADSECURITYCHECKSFAILED => MonitoredItemError.SecurityChecksFailed,
            else => MonitoredItemError.UnexpectedError,
        };
    }
};

/// Map OPC UA status codes to BrowseError
fn mapBrowseError(status: c.UA_StatusCode) BrowseError {
    return switch (status) {
        c.UA_STATUSCODE_GOOD => BrowseError.UnexpectedError, // Should not be called with GOOD

        // Connection/Session errors
        c.UA_STATUSCODE_BADSERVERNOTCONNECTED => BrowseError.ServerNotConnected,
        c.UA_STATUSCODE_BADSESSIONCLOSED => BrowseError.SessionClosed,
        c.UA_STATUSCODE_BADTIMEOUT => BrowseError.Timeout,
        c.UA_STATUSCODE_BADREQUESTTIMEOUT => BrowseError.Timeout,
        c.UA_STATUSCODE_BADCOMMUNICATIONERROR => BrowseError.CommunicationError,

        // Node/Browse errors
        c.UA_STATUSCODE_BADNODEIDUNKNOWN => BrowseError.NodeIdUnknown,
        c.UA_STATUSCODE_BADNODEIDINVALID => BrowseError.NodeIdInvalid,
        c.UA_STATUSCODE_BADBROWSEDIRECTIONINVALID => BrowseError.BrowseDirectionInvalid,
        c.UA_STATUSCODE_BADREFERENCETYPEIDINVALID => BrowseError.ReferenceTypeIdInvalid,
        c.UA_STATUSCODE_BADUSERACCESSDENIED => BrowseError.UserAccessDenied,
        c.UA_STATUSCODE_BADOBJECTDELETED => BrowseError.ObjectDeleted,
        c.UA_STATUSCODE_BADNOTFOUND => BrowseError.NotFound,
        c.UA_STATUSCODE_BADCONTINUATIONPOINTINVALID => BrowseError.ContinuationPointInvalid,
        c.UA_STATUSCODE_BADNOCONTINUATIONPOINTS => BrowseError.NoContinuationPoint,

        // System errors
        c.UA_STATUSCODE_BADOUTOFMEMORY => BrowseError.OutOfMemory,
        c.UA_STATUSCODE_BADINTERNALERROR => BrowseError.InternalError,
        c.UA_STATUSCODE_BADSERVICEUNSUPPORTED => BrowseError.ServiceUnsupported,
        c.UA_STATUSCODE_BADSECURITYCHECKSFAILED => BrowseError.SecurityChecksFailed,

        // Catch-all
        else => BrowseError.UnexpectedError,
    };
}

test "Client.getNamespaceByName rejects empty URI" {
    const testing = std.testing;
    std.testing.refAllDecls(@This());

    var client = try Client.init();
    defer client.deinit();

    const result = client.getNamespaceByName("");
    try testing.expectError(NamespaceError.InvalidNamespaceUri, result);
}

test "Client.getNamespaceByName integration test" {
    const testing = std.testing;
    const server_mod = @import("server.zig");

    // Start a test server with custom namespaces
    var server = try server_mod.Server.init();
    defer server.deinit();

    const test_uri = "http://example.com/test-namespace";
    const expected_idx = try server.addNamespace(test_uri);

    try server.start();
    defer server.stop() catch {};

    // Give server time to start
    std.time.sleep(50 * std.time.ns_per_ms);

    // Connect client
    var client = try Client.init();
    defer client.deinit();

    try client.connect("opc.tcp://localhost:4840");
    defer client.disconnect() catch {};

    // Test: Find standard OPC UA namespace
    const std_idx = try client.getNamespaceByName("http://opcfoundation.org/UA/");
    try testing.expectEqual(@as(u16, 0), std_idx);

    // Test: Find custom namespace
    const found_idx = try client.getNamespaceByName(test_uri);
    try testing.expectEqual(expected_idx, found_idx);

    // Test: Non-existent namespace
    const result = client.getNamespaceByName("http://nonexistent.example.com/");
    try testing.expectError(NamespaceError.NamespaceNotFound, result);
}

test "Client subscription lifecycle integration test" {
    const testing = std.testing;
    const server_mod = @import("server.zig");

    // Start a test server with a variable node
    var server = try server_mod.Server.init();
    defer server.deinit();

    _ = try server.addVariableNode(
        NodeId.initString(1, "temperature"),
        @import("types.zig").StandardNodeId.objects_folder,
        @import("types.zig").ReferenceType.organizes,
        @import("types.zig").QualifiedName.init(1, "Temperature"),
        @import("types.zig").StandardNodeId.base_data_variable_type,
        .{
            .value = Variant.scalar(f64, 23.5),
            .access_level = .{ .read = true, .write = true },
        },
    );

    try server.start();
    defer server.stop() catch {};

    // Give server time to start
    std.time.sleep(50 * std.time.ns_per_ms);

    // Connect client
    var client = try Client.init();
    defer client.deinit();

    try client.connect("opc.tcp://localhost:4840");
    defer client.disconnect() catch {};

    // Create subscription
    const sub_id = try client.createSubscription(.{
        .publishing_interval = 1000.0,
        .priority = 10,
    });
    defer client.deleteSubscription(sub_id) catch {};

    try testing.expect(sub_id > 0);

    // Create monitored item
    const mon_id = try client.createMonitoredItem(sub_id, .{
        .node_id = NodeId.initString(1, "temperature"),
        .sampling_interval = 100.0,
        .queue_size = 10,
    });
    defer client.deleteMonitoredItem(sub_id, mon_id) catch {};

    try testing.expect(mon_id > 0);

    // Delete monitored item explicitly
    try client.deleteMonitoredItem(sub_id, mon_id);

    // Delete subscription explicitly
    try client.deleteSubscription(sub_id);
}

test "Client creates multiple subscriptions" {
    const testing = std.testing;
    const server_mod = @import("server.zig");

    // Start a test server
    var server = try server_mod.Server.init();
    defer server.deinit();

    try server.start();
    defer server.stop() catch {};

    std.time.sleep(50 * std.time.ns_per_ms);

    // Connect client
    var client = try Client.init();
    defer client.deinit();

    try client.connect("opc.tcp://localhost:4840");
    defer client.disconnect() catch {};

    // Create multiple subscriptions
    const sub_id1 = try client.createSubscription(.{});
    defer client.deleteSubscription(sub_id1) catch {};

    const sub_id2 = try client.createSubscription(.{
        .publishing_interval = 500.0,
    });
    defer client.deleteSubscription(sub_id2) catch {};

    try testing.expect(sub_id1 > 0);
    try testing.expect(sub_id2 > 0);
    try testing.expect(sub_id1 != sub_id2);
}

test "Client creates multiple monitored items in one subscription" {
    const testing = std.testing;
    const server_mod = @import("server.zig");

    // Start a test server with multiple variables
    var server = try server_mod.Server.init();
    defer server.deinit();

    _ = try server.addVariableNode(
        NodeId.initString(1, "temperature"),
        @import("types.zig").StandardNodeId.objects_folder,
        @import("types.zig").ReferenceType.organizes,
        @import("types.zig").QualifiedName.init(1, "Temperature"),
        @import("types.zig").StandardNodeId.base_data_variable_type,
        .{ .value = Variant.scalar(f64, 23.5) },
    );

    _ = try server.addVariableNode(
        NodeId.initString(1, "pressure"),
        @import("types.zig").StandardNodeId.objects_folder,
        @import("types.zig").ReferenceType.organizes,
        @import("types.zig").QualifiedName.init(1, "Pressure"),
        @import("types.zig").StandardNodeId.base_data_variable_type,
        .{ .value = Variant.scalar(f64, 101.3) },
    );

    try server.start();
    defer server.stop() catch {};

    std.time.sleep(50 * std.time.ns_per_ms);

    // Connect client
    var client = try Client.init();
    defer client.deinit();

    try client.connect("opc.tcp://localhost:4840");
    defer client.disconnect() catch {};

    // Create one subscription
    const sub_id = try client.createSubscription(.{});
    defer client.deleteSubscription(sub_id) catch {};

    // Create multiple monitored items
    const mon_id1 = try client.createMonitoredItem(sub_id, .{
        .node_id = NodeId.initString(1, "temperature"),
    });
    defer client.deleteMonitoredItem(sub_id, mon_id1) catch {};

    const mon_id2 = try client.createMonitoredItem(sub_id, .{
        .node_id = NodeId.initString(1, "pressure"),
    });
    defer client.deleteMonitoredItem(sub_id, mon_id2) catch {};

    try testing.expect(mon_id1 > 0);
    try testing.expect(mon_id2 > 0);
    try testing.expect(mon_id1 != mon_id2);
}

test "Client monitored item with callback integration test" {
    const testing = std.testing;
    const server_mod = @import("server.zig");

    // Callback context to track notifications
    const CallbackContext = struct {
        call_count: u32 = 0,
        last_value: f64 = 0.0,
    };

    // Callback function
    const callback = struct {
        fn onDataChange(
            userdata: ?*anyopaque,
            sub_id: SubscriptionId,
            mon_id: MonitoredItemId,
            value: *const Variant,
        ) void {
            _ = sub_id;
            _ = mon_id;
            const ctx: *CallbackContext = @ptrCast(@alignCast(userdata.?));
            ctx.call_count += 1;
            if (value.* == .double) {
                ctx.last_value = value.double;
            }
        }
    }.onDataChange;

    // Start a test server with a variable node
    var server = try server_mod.Server.init();
    defer server.deinit();

    _ = try server.addVariableNode(
        NodeId.initString(1, "temperature"),
        @import("types.zig").StandardNodeId.objects_folder,
        @import("types.zig").ReferenceType.organizes,
        @import("types.zig").QualifiedName.init(1, "Temperature"),
        @import("types.zig").StandardNodeId.base_data_variable_type,
        .{
            .value = Variant.scalar(f64, 23.5),
            .access_level = .{ .read = true, .write = true },
        },
    );

    try server.start();
    defer server.stop() catch {};

    std.time.sleep(50 * std.time.ns_per_ms);

    // Connect client
    var client = try Client.init();
    defer client.deinit();

    try client.connect("opc.tcp://localhost:4840");
    defer client.disconnect() catch {};

    // Create subscription
    const sub_id = try client.createSubscription(.{
        .publishing_interval = 100.0, // Fast for testing
        .priority = 10,
    });
    defer client.deleteSubscription(sub_id) catch {};

    // Create callback context
    var ctx = CallbackContext{};

    // Create monitored item with callback
    const mon_id = try client.createMonitoredItemWithCallback(
        sub_id,
        .{
            .node_id = NodeId.initString(1, "temperature"),
            .sampling_interval = 50.0,
            .queue_size = 10,
        },
        callback,
        &ctx,
    );
    defer client.deleteMonitoredItem(sub_id, mon_id) catch {};

    try testing.expect(mon_id > 0);

    // Give initial callback time to fire (initial value)
    _ = c.UA_Client_run_iterate(client.handle, 200);
    std.time.sleep(50 * std.time.ns_per_ms);

    // Write a new value to trigger callback
    try client.writeValueAttribute(
        NodeId.initString(1, "temperature"),
        Variant.scalar(f64, 42.0),
    );

    // Process messages to receive callback
    _ = c.UA_Client_run_iterate(client.handle, 200);
    std.time.sleep(100 * std.time.ns_per_ms);
    _ = c.UA_Client_run_iterate(client.handle, 200);

    // Verify callback was called and received the new value
    try testing.expect(ctx.call_count > 0);
    try testing.expectEqual(@as(f64, 42.0), ctx.last_value);
}
