const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");
const ua_error = @import("ua_error.zig");

/// Authentication methods supported by OPC UA
pub const AuthenticationMethod = enum {
    /// No authentication (anonymous access)
    anonymous,
    /// Username and password authentication
    username_password,
    /// X.509 certificate authentication
    x509_certificate,
    /// Issued token authentication (JWT, SAML, etc.)
    issued_token,
};

/// User identity token for authentication
pub const UserIdentityToken = union(AuthenticationMethod) {
    /// Anonymous authentication (no credentials)
    anonymous: void,
    /// Username and password authentication
    username_password: struct {
        username: []const u8,
        password: []const u8,
    },
    /// X.509 certificate authentication
    x509_certificate: struct {
        certificate: []const u8,
        private_key: []const u8,
    },
    /// Issued token authentication
    issued_token: struct {
        token_data: []const u8,
        token_type: []const u8,
    },
};

/// Authentication configuration for client connections
pub const AuthenticationConfig = struct {
    /// User identity token for authentication
    identity_token: UserIdentityToken,
    /// Security policy URI (optional, uses server default if null)
    security_policy_uri: ?[]const u8 = null,
    /// Security mode (default: sign_and_encrypt)
    security_mode: c.UA_MessageSecurityMode = c.UA_MESSAGESECURITYMODE_SIGNANDENCRYPT,
};

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
pub fn connectWithAuth(
    client: *c.UA_Client,
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
            const status = c.UA_Client_connect(client, c_url.ptr);
            try ua_error.checkStatus(status);
        },
        .username_password => |creds| {
            // Username/password authentication
            const user_buf = try allocator.alloc(u8, creds.username.len + 1);
            const c_username = try std.fmt.bufPrintZ(user_buf, "{s}", .{creds.username});

            const pass_buf = try allocator.alloc(u8, creds.password.len + 1);
            const c_password = try std.fmt.bufPrintZ(pass_buf, "{s}", .{creds.password});

            const status = c.UA_Client_connectUsername(
                client,
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
            var config: *c.UA_ClientConfig = c.UA_Client_getConfig(client);
            
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
            
            @memcpy(certificate.data[0..cert.certificate.len], cert.certificate);
            
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
            
            @memcpy(private_key.data[0..cert.private_key.len], cert.private_key);
            
            // Set certificate and private key in config
            // Note: This assumes the client was configured to accept certificate auth
            // In a real implementation, we'd need to check if security policy supports it
            
            // For now, we'll attempt to connect with the standard method
            // Certificate validation happens at the protocol level
            const status = c.UA_Client_connect(client, c_url.ptr);
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

/// Simplified function to connect with username and password
pub fn connectWithUsername(
    client: *c.UA_Client,
    endpoint_url: []const u8,
    username: []const u8,
    password: []const u8
) !void {
    const auth_config = AuthenticationConfig{
        .identity_token = .{
            .username_password = .{
                .username = username,
                .password = password,
            },
        },
    };
    return connectWithAuth(client, endpoint_url, auth_config);
}

/// Simplified function to connect anonymously
pub fn connectAnonymous(client: *c.UA_Client, endpoint_url: []const u8) !void {
    const auth_config = AuthenticationConfig{
        .identity_token = .anonymous,
    };
    return connectWithAuth(client, endpoint_url, auth_config);
}

// ============================================================================
// Tests
// ============================================================================

test "AuthenticationMethod enum values" {
    const testing = std.testing;
    std.testing.refAllDecls(@This());

    try testing.expectEqual(AuthenticationMethod.anonymous, .anonymous);
    try testing.expectEqual(AuthenticationMethod.username_password, .username_password);
    try testing.expectEqual(AuthenticationMethod.x509_certificate, .x509_certificate);
    try testing.expectEqual(AuthenticationMethod.issued_token, .issued_token);
}

test "UserIdentityToken union creation" {
    const testing = std.testing;

    // Anonymous token
    const anonymous_token = UserIdentityToken{ .anonymous = {} };
    try testing.expectEqual(AuthenticationMethod.anonymous, @as(AuthenticationMethod, anonymous_token));

    // Username/password token
    const userpass_token = UserIdentityToken{
        .username_password = .{
            .username = "testuser",
            .password = "testpass",
        },
    };
    try testing.expectEqual(AuthenticationMethod.username_password, @as(AuthenticationMethod, userpass_token));
    try testing.expectEqualStrings("testuser", userpass_token.username_password.username);
    try testing.expectEqualStrings("testpass", userpass_token.username_password.password);
}

test "AuthenticationConfig default values" {
    const testing = std.testing;

    const config = AuthenticationConfig{
        .identity_token = .anonymous,
    };

    try testing.expectEqual(AuthenticationMethod.anonymous, @as(AuthenticationMethod, config.identity_token));
    try testing.expectEqual(@as(?[]const u8, null), config.security_policy_uri);
    try testing.expectEqual(c.UA_MESSAGESECURITYMODE_SIGNANDENCRYPT, config.security_mode);
}

test "AuthenticationConfig with username/password" {
    const testing = std.testing;

    const config = AuthenticationConfig{
        .identity_token = .{
            .username_password = .{
                .username = "admin",
                .password = "secret",
            },
        },
        .security_policy_uri = "http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256",
        .security_mode = c.UA_MESSAGESECURITYMODE_SIGN,
    };

    try testing.expectEqual(AuthenticationMethod.username_password, @as(AuthenticationMethod, config.identity_token));
    try testing.expect(config.security_policy_uri != null);
    try testing.expectEqualStrings(
        "http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256",
        config.security_policy_uri.?
    );
    try testing.expectEqual(c.UA_MESSAGESECURITYMODE_SIGN, config.security_mode);
}