const std = @import("std");
const c = @import("c.zig");
const ua_error = @import("ua_error.zig");
const client_auth = @import("client_auth.zig");
const client_config = @import("client_config.zig");

const AttributeId = u32;

/// OPC UA Client for connecting to OPC UA servers.
/// This struct provides a high-level interface to the open62541 C client API.
pub const Client = struct {
    handle: *c.UA_Client,

    /// Initialize a new OPC UA client with default configuration.
    /// The client must be deinitialized with `deinit()` when no longer needed.
    pub fn init() !Client {
        const handle = c.UA_Client_new();
        if (handle == null) {
            return error.OutOfMemory;
        }

        const status = c.UA_ClientConfig_setDefault(c.UA_Client_getConfig(handle));
        try ua_error.checkStatus(status);

        return Client{ .handle = handle.? };
    }

    /// Initialize a new OPC UA client with custom configuration.
    /// The client must be deinitialized with `deinit()` when no longer needed.
    pub fn initWithConfig(config: client_config.ClientConfig) !Client {
        const handle = c.UA_Client_new();
        if (handle == null) {
            return error.OutOfMemory;
        }

        // Apply custom configuration
        const c_config = c.UA_Client_getConfig(handle);
        config.applyTo(c_config);

        return Client{ .handle = handle.? };
    }

    /// Deinitialize the OPC UA client and free all associated resources.
    /// This function must be called when the client is no longer needed.
    pub fn deinit(self: *Client) void {
        c.UA_Client_delete(self.handle);
        self.handle = undefined;
    }

    /// Connect to an OPC UA server using anonymous authentication.
    ///
    /// This function establishes a connection to the specified OPC UA server
    /// endpoint URL using anonymous authentication.
    ///
    /// Connect to an OPC UA server using anonymous authentication (no credentials).
    /// This is a convenience wrapper for backward compatibility.
    /// For more control over authentication, use `connectWithAuth()`.
    ///
    /// Example:
    /// ```zig
    /// const client = try Client.init();
    /// defer client.deinit();
    /// try client.connect("opc.tcp://localhost:4840");
    /// ```
    pub fn connect(self: *Client, endpoint_url: []const u8) !void {
        return self.connectAnonymous(endpoint_url);
    }

    /// Connect to an OPC UA server using anonymous authentication (no credentials).
    ///
    /// Example:
    /// ```zig
    /// const client = try Client.init();
    /// defer client.deinit();
    /// try client.connectAnonymous("opc.tcp://localhost:4840");
    /// ```
    pub fn connectAnonymous(self: *Client, endpoint_url: []const u8) !void {
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

    /// Connect to an OPC UA server using username/password authentication.
    ///
    /// This function establishes a connection to the specified OPC UA server
    /// endpoint URL using username and password authentication.
    ///
    /// Example:
    /// ```zig
    /// const client = try Client.init();
    /// defer client.deinit();
    /// try client.connectUsernamePassword(
    ///     "opc.tcp://localhost:4840",
    ///     "admin",
    ///     "secret"
    /// );
    /// ```
    pub fn connectUsernamePassword(
        self: *Client,
        endpoint_url: []const u8,
        username: []const u8,
        password: []const u8,
    ) !void {
        // Use arena allocator to safely create null-terminated strings for C API
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        // Allocate buffers and create null-terminated strings
        const url_buf = try allocator.alloc(u8, endpoint_url.len + 1);
        const c_url = try std.fmt.bufPrintZ(url_buf, "{s}", .{endpoint_url});

        const user_buf = try allocator.alloc(u8, username.len + 1);
        const c_user = try std.fmt.bufPrintZ(user_buf, "{s}", .{username});

        const pass_buf = try allocator.alloc(u8, password.len + 1);
        const c_pass = try std.fmt.bufPrintZ(pass_buf, "{s}", .{password});

        const status = c.UA_Client_connectUsername(
            self.handle,
            c_url,
            c_user,
            c_pass,
        );
        try ua_error.checkStatus(status);
    }

    /// Connect to an OPC UA server using X.509 certificate authentication.
    ///
    /// This function establishes a connection to the specified OPC UA server
    /// endpoint URL using X.509 certificate authentication.
    ///
    /// Example:
    /// ```zig
    /// const client = try Client.init();
    /// defer client.deinit();
    /// const certificate = .{
    ///     .certificate = "-----BEGIN CERTIFICATE-----\\n...\\n-----END CERTIFICATE-----",
    ///     .private_key = "-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----",
    /// };
    /// try client.connectCertificate(
    ///     "opc.tcp://localhost:4840",
    ///     certificate
    /// );
    /// ```
    pub fn connectCertificate(
        self: *Client,
        endpoint_url: []const u8,
        certificate: client_auth.X509Certificate,
    ) !void {
        // Use arena allocator to safely create null-terminated strings for C API
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        // Allocate buffer and create null-terminated string for endpoint URL
        const url_buf = try allocator.alloc(u8, endpoint_url.len + 1);
        const c_url = try std.fmt.bufPrintZ(url_buf, "{s}", .{endpoint_url});

        // Convert certificate to C types
        const cert = c.UA_ByteString_new();
        defer c.UA_ByteString_delete(cert);
        const key = c.UA_ByteString_new();
        defer c.UA_ByteString_delete(key);

        const cert_status = c.UA_ByteString_allocBuffer(
            cert,
            @intCast(certificate.certificate.len),
        );
        try ua_error.checkStatus(cert_status);

        const key_status = c.UA_ByteString_allocBuffer(
            key,
            @intCast(certificate.private_key.len),
        );
        try ua_error.checkStatus(key_status);

        // Copy certificate data
        @memcpy(cert.data[0..certificate.certificate.len], certificate.certificate);
        cert.length = @intCast(certificate.certificate.len);

        // Copy private key data
        @memcpy(key.data[0..certificate.private_key.len], certificate.private_key);
        key.length = @intCast(certificate.private_key.len);

        const status = c.UA_Client_connectCertificate(
            self.handle,
            c_url,
            cert,
            key,
        );
        try ua_error.checkStatus(status);
    }

    /// Connect to an OPC UA server with full authentication configuration.
    ///
    /// This function establishes a connection to the specified OPC UA server
    /// endpoint URL using the provided authentication configuration, which
    /// includes identity token, security policy, and security mode.
    ///
    /// Example:
    /// ```zig
    /// const client = try Client.init();
    /// defer client.deinit();
    /// const auth_config = client_auth.AuthenticationConfig{
    ///     .identity_token = .{
    ///         .username_password = .{
    ///             .username = "admin",
    ///             .password = "secret",
    ///         },
    ///     },
    ///     .security_policy_uri = "http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256",
    ///     .security_mode = c.UA_MESSAGESECURITYMODE_SIGNANDENCRYPT,
    /// };
    /// try client.connectWithAuth(
    ///     "opc.tcp://localhost:4840",
    ///     auth_config
    /// );
    /// ```
    pub fn connectWithAuth(
        self: *Client,
        endpoint_url: []const u8,
        auth_config: client_auth.AuthenticationConfig,
    ) !void {
        // Use arena allocator to safely create null-terminated strings for C API
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        // Allocate buffer and create null-terminated string for endpoint URL
        const url_buf = try allocator.alloc(u8, endpoint_url.len + 1);
        const c_url = try std.fmt.bufPrintZ(url_buf, "{s}", .{endpoint_url});

        // Convert authentication config to C types
        // SAFETY: `undefined` is safe here because `convertAuthenticationConfig` will fully initialize the struct
        var c_auth_config: c.UA_ClientConfig_Authentication = undefined;
        try client_auth.convertAuthenticationConfig(&c_auth_config, auth_config, allocator);

        const status = c.UA_Client_connectWithAuth(
            self.handle,
            c_url,
            &c_auth_config,
        );
        try ua_error.checkStatus(status);
    }

    /// Disconnect from the OPC UA server.
    ///
    /// This function disconnects from the currently connected OPC UA server.
    /// It should be called before deinitializing the client.
    pub fn disconnect(self: *Client) !void {
        const status = c.UA_Client_disconnect(self.handle);
        try ua_error.checkStatus(status);
    }

    /// Read a node attribute value from the OPC UA server.
    ///
    /// This function reads the value of a specific attribute from a node
    /// in the OPC UA server's address space.
    ///
    /// Example:
    /// ```zig
    /// const value = try client.readNodeAttribute(
    ///     "ns=2;i=1234",
    ///     c.UA_ATTRIBUTEID_VALUE
    /// );
    /// ```
    pub fn readNodeAttribute(
        self: *Client,
        node_id: []const u8,
        attribute_id: AttributeId,
    ) !c.UA_DataValue {
        _ = attribute_id; // Mark as intentionally unused for now
        // Use arena allocator to safely create null-terminated strings for C API
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        // Allocate buffer and create null-terminated string for node ID
        const node_id_buf = try allocator.alloc(u8, node_id.len + 1);
        const c_node_id = try std.fmt.bufPrintZ(node_id_buf, "{s}", .{node_id});

        // SAFETY: `undefined` is safe here because `UA_NodeId_parse` will fully initialize the struct
        var c_node: c.UA_NodeId = undefined;
        const parse_status = c.UA_NodeId_parse(&c_node, c.UA_STRING(c_node_id.ptr));
        try ua_error.checkStatus(parse_status);

        // SAFETY: `undefined` is safe here because `UA_Client_readValueAttribute` will fully initialize the struct
        var value: c.UA_Variant = undefined;
        const status = c.UA_Client_readValueAttribute(
            self.handle,
            c_node,
            &value,
        );
        try ua_error.checkStatus(status);

        // Convert UA_Variant to UA_DataValue
        var data_value: c.UA_DataValue = undefined;
        data_value.value = value;
        data_value.hasValue = true;
        data_value.hasStatus = false;
        data_value.hasSourceTimestamp = false;
        data_value.hasServerTimestamp = false;
        data_value.hasSourcePicoseconds = false;
        data_value.hasServerPicoseconds = false;
        return data_value;
    }

    /// Write a node attribute value to the OPC UA server.
    ///
    /// This function writes a value to a specific attribute of a node
    /// in the OPC UA server's address space.
    ///
    /// Example:
    /// ```zig
    /// var variant: c.UA_Variant = undefined;
    /// // Initialize variant with value...
    /// try client.writeNodeAttribute(
    ///     "ns=2;i=1234",
    ///     c.UA_ATTRIBUTEID_VALUE,
    ///     &variant
    /// );
    /// ```
    pub fn writeNodeAttribute(
        self: *Client,
        node_id: []const u8,
        attribute_id: AttributeId,
        value: *const c.UA_Variant,
    ) !void {
        _ = attribute_id; // Mark as intentionally unused for now
        // Use arena allocator to safely create null-terminated strings for C API
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        // Allocate buffer and create null-terminated string for node ID
        const node_id_buf = try allocator.alloc(u8, node_id.len + 1);
        const c_node_id = try std.fmt.bufPrintZ(node_id_buf, "{s}", .{node_id});

        // SAFETY: `undefined` is safe here because `UA_NodeId_parse` will fully initialize the struct
        var c_node: c.UA_NodeId = undefined;
        const parse_status = c.UA_NodeId_parse(&c_node, c.UA_STRING(c_node_id.ptr));
        try ua_error.checkStatus(parse_status);

        const status = c.UA_Client_writeValueAttribute(
            self.handle,
            c_node,
            value,
        );
        try ua_error.checkStatus(status);
    }

    /// Browse the OPC UA server's address space starting from a specific node.
    ///
    /// This function browses the references from a starting node in the
    /// OPC UA server's address space.
    ///
    /// Example:
    /// ```zig
    /// const result = try client.browse("ns=0;i=85");
    /// ```
    pub fn browse(self: *Client, node_id: []const u8) !c.UA_BrowseResult {
        // Use arena allocator to safely create null-terminated strings for C API
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        // Allocate buffer and create null-terminated string for node ID
        const node_id_buf = try allocator.alloc(u8, node_id.len + 1);
        const c_node_id = try std.fmt.bufPrintZ(node_id_buf, "{s}", .{node_id});

        // SAFETY: `undefined` is safe here because `UA_NodeId_parse` will fully initialize the struct
        var c_node: c.UA_NodeId = undefined;
        const parse_status = c.UA_NodeId_parse(&c_node, c.UA_STRING(c_node_id.ptr));
        try ua_error.checkStatus(parse_status);

        // SAFETY: `undefined` is safe here because `UA_Client_browse` will fully initialize the struct
        var result: c.UA_BrowseResult = undefined;
        const status = c.UA_Client_browse(
            self.handle,
            c_node,
            &result,
        );
        try ua_error.checkStatus(status);

        return result;
    }

    /// Get the current session state of the client.
    ///
    /// This function returns the current session state of the client,
    /// which can be used to determine if the client is connected and
    /// authenticated.
    pub fn getSessionState(self: *Client) c.UA_SessionState {
        return c.UA_Client_getState(self.handle);
    }

    /// Check if the client is currently connected to a server.
    ///
    /// This function returns true if the client is currently connected
    /// to an OPC UA server, false otherwise.
    pub fn isConnected(self: *Client) bool {
        return self.getSessionState() != c.UA_SESSIONSTATE_DISCONNECTED;
    }
};
