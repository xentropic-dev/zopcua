const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");
const ua_error = @import("ua_error.zig");
const NodeId = @import("types.zig").NodeId;
const Variant = @import("variant.zig").Variant;
const ClientConfig = @import("client_config.zig").ClientConfig;

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
        try config.applyToC(&c_config, arena.allocator());

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
                defer node_id.freeToC(c_node_id, arena.allocator());

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
    /// const variant = try client.readValueAttribute(node_id, allocator);
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
    pub fn readValueAttribute(self: Client, node_id: NodeId, allocator: std.mem.Allocator) ReadAttributeError!Variant {
        // SAFETY: c_variant is initialized immediately by UA_Variant_init before any use
        var c_variant: c.UA_Variant = undefined;
        c.UA_Variant_init(&c_variant);

        const c_node_id = node_id.toC(std.heap.c_allocator) catch {
            return ReadAttributeError.OutOfMemory;
        };
        defer node_id.freeToC(c_node_id, std.heap.c_allocator);

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
};
