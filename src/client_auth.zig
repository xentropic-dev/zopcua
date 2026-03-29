const std = @import("std");
const c = @import("c.zig");
const ua_error = @import("ua_error.zig");

/// OPC UA authentication methods supported by zopcua.
/// These correspond to the OPC UA identity token types.
pub const AuthenticationMethod = enum {
    anonymous,
    username_password,
    x509_certificate,
    issued_token,
};

/// X.509 certificate and private key for certificate-based authentication.
pub const X509Certificate = struct {
    certificate: []const u8,
    private_key: []const u8,
};

/// Issued token (e.g., JWT) for token-based authentication.
pub const IssuedToken = struct {
    token_data: []const u8,
    token_type: []const u8,
};

/// Username and password for username/password authentication.
pub const UsernamePassword = struct {
    username: []const u8,
    password: []const u8,
};

/// Union type representing all OPC UA user identity tokens.
/// This is a tagged union that can hold any of the supported authentication methods.
pub const UserIdentityToken = union(AuthenticationMethod) {
    anonymous: void,
    username_password: UsernamePassword,
    x509_certificate: X509Certificate,
    issued_token: IssuedToken,
};

/// Security policy URI strings for OPC UA security policies.
/// These are the standard OPC UA security policy URIs.
pub const SecurityPolicy = struct {
    pub const None = "http://opcfoundation.org/UA/SecurityPolicy#None";
    pub const Basic128Rsa15 = "http://opcfoundation.org/UA/SecurityPolicy#Basic128Rsa15";
    pub const Basic256 = "http://opcfoundation.org/UA/SecurityPolicy#Basic256";
    pub const Basic256Sha256 = "http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256";
    pub const Aes128_Sha256_RsaOaep = "http://opcfoundation.org/UA/SecurityPolicy#Aes128_Sha256_RsaOaep";
    pub const Aes256_Sha256_RsaPss = "http://opcfoundation.org/UA/SecurityPolicy#Aes256_Sha256_RsaPss";
};

/// Authentication configuration for OPC UA client connections.
/// This struct contains all the information needed to authenticate
/// with an OPC UA server using any supported authentication method.
pub const AuthenticationConfig = struct {
    /// The user identity token to use for authentication.
    identity_token: UserIdentityToken,

    /// Optional security policy URI. If null, the server's default is used.
    security_policy_uri: ?[]const u8 = null,

    /// Security mode for the connection (Sign, SignAndEncrypt, or None).
    security_mode: c.UA_MessageSecurityMode = c.UA_MESSAGESECURITYMODE_SIGNANDENCRYPT,

    /// Convert AuthenticationConfig to C API types for use with open62541.
    /// This function allocates temporary memory for C strings and structures.
    ///
    /// **Memory management:**
    /// The caller is responsible for freeing the allocated C structures
    /// using `c.UA_ClientConfig_Authentication_clear()`.
    pub fn convertToC(
        self: AuthenticationConfig,
        c_config: *c.UA_ClientConfig_Authentication,
        allocator: std.mem.Allocator,
    ) !void {
        // Initialize the C structure
        c.UA_ClientConfig_Authentication_init(c_config);

        // Set security mode
        c_config.securityMode = self.security_mode;

        // Set security policy URI if provided
        if (self.security_policy_uri) |policy_uri| {
            const policy_buf = try allocator.alloc(u8, policy_uri.len + 1);
            errdefer allocator.free(policy_buf);
            const c_policy = try std.fmt.bufPrintZ(policy_buf, "{s}", .{policy_uri});
            c_config.securityPolicyUri = c.UA_STRING_ALLOC(c_policy);
        }

        // Set identity token based on type
        switch (self.identity_token) {
            .anonymous => {
                c_config.tokenType = c.UA_USERTOKENTYPE_ANONYMOUS;
            },
            .username_password => |userpass| {
                c_config.tokenType = c.UA_USERTOKENTYPE_USERNAME;

                // Allocate and copy username
                const user_buf = try allocator.alloc(u8, userpass.username.len + 1);
                errdefer allocator.free(user_buf);
                const c_user = try std.fmt.bufPrintZ(user_buf, "{s}", .{userpass.username});
                c_config.userName = c.UA_STRING_ALLOC(c_user);

                // Allocate and copy password
                const pass_buf = try allocator.alloc(u8, userpass.password.len + 1);
                errdefer allocator.free(pass_buf);
                const c_pass = try std.fmt.bufPrintZ(pass_buf, "{s}", .{userpass.password});
                c_config.password = c.UA_STRING_ALLOC(c_pass);
            },
            .x509_certificate => |cert| {
                c_config.tokenType = c.UA_USERTOKENTYPE_CERTIFICATE;

                // Convert certificate to UA_ByteString
                const certificate = c.UA_ByteString_new();
                defer c.UA_ByteString_delete(certificate);
                const cert_status = c.UA_ByteString_allocBuffer(
                    certificate,
                    @intCast(cert.certificate.len),
                );
                try ua_error.checkStatus(cert_status);
                @memcpy(certificate.data[0..cert.certificate.len], cert.certificate);
                certificate.length = @intCast(cert.certificate.len);

                // Convert private key to UA_ByteString
                const private_key = c.UA_ByteString_new();
                defer c.UA_ByteString_delete(private_key);
                const key_status = c.UA_ByteString_allocBuffer(
                    private_key,
                    @intCast(cert.private_key.len),
                );
                try ua_error.checkStatus(key_status);
                @memcpy(private_key.data[0..cert.private_key.len], cert.private_key);
                private_key.length = @intCast(cert.private_key.len);

                // Copy to C structure
                c_config.certificate = certificate.*;
                c_config.privateKey = private_key.*;
            },
            .issued_token => |token| {
                c_config.tokenType = c.UA_USERTOKENTYPE_ISSUEDTOKEN;

                // Allocate and copy token data
                const token_buf = try allocator.alloc(u8, token.token_data.len + 1);
                errdefer allocator.free(token_buf);
                const c_token = try std.fmt.bufPrintZ(token_buf, "{s}", .{token.token_data});
                c_config.issuedToken = c.UA_STRING_ALLOC(c_token);

                // Allocate and copy token type
                const type_buf = try allocator.alloc(u8, token.token_type.len + 1);
                errdefer allocator.free(type_buf);
                const c_type = try std.fmt.bufPrintZ(type_buf, "{s}", .{token.token_type});
                c_config.issuedTokenType = c.UA_STRING_ALLOC(c_type);
            },
        }
    }

    /// Clear C authentication configuration and free allocated memory.
    /// This function should be called after `convertToC()` when the
    /// C structures are no longer needed.
    pub fn clearC(c_config: *c.UA_ClientConfig_Authentication) void {
        c.UA_ClientConfig_Authentication_clear(c_config);
    }
};

/// Helper function to convert AuthenticationConfig to C API types.
/// This is a convenience wrapper around `AuthenticationConfig.convertToC()`.
pub fn convertAuthenticationConfig(
    c_config: *c.UA_ClientConfig_Authentication,
    config: AuthenticationConfig,
    allocator: std.mem.Allocator,
) !void {
    try config.convertToC(c_config, allocator);
}

/// Parse a PEM-encoded certificate or private key.
/// This function extracts the base64-encoded data from a PEM file,
/// ignoring headers, footers, and whitespace.
///
/// **Memory management:**
/// The returned data is heap-allocated and must be freed by the caller.
fn parsePem(
    allocator: std.mem.Allocator,
    pem: []const u8,
    expected_label: []const u8,
) ![]const u8 {
    var lines = std.mem.splitScalar(u8, pem, '\n');
    var in_section = false;
    var base64_data = std.ArrayList(u8).init(allocator);
    defer base64_data.deinit();

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \r");

        // Check for BEGIN marker
        if (std.mem.startsWith(u8, trimmed, "-----BEGIN ") and
            std.mem.endsWith(u8, trimmed, "-----"))
        {
            const label_start = "-----BEGIN ".len;
            const label_end = trimmed.len - "-----".len;
            const label = trimmed[label_start..label_end];
            if (std.mem.eql(u8, label, expected_label)) {
                in_section = true;
                continue;
            }
        }

        // Check for END marker
        if (std.mem.startsWith(u8, trimmed, "-----END ") and
            std.mem.endsWith(u8, trimmed, "-----"))
        {
            in_section = false;
            continue;
        }

        // Collect base64 data while in section
        if (in_section and trimmed.len > 0) {
            try base64_data.appendSlice(trimmed);
        }
    }

    if (base64_data.items.len == 0) {
        return error.InvalidPemFormat;
    }

    return base64_data.toOwnedSlice();
}

/// Load an X.509 certificate from a PEM file.
/// This function reads a PEM-encoded certificate file and returns
/// the raw certificate data.
///
/// **Memory management:**
/// The returned data is heap-allocated and must be freed by the caller.
pub fn loadCertificateFromPem(
    allocator: std.mem.Allocator,
    pem_data: []const u8,
) ![]const u8 {
    return parsePem(allocator, pem_data, "CERTIFICATE");
}

/// Load a private key from a PEM file.
/// This function reads a PEM-encoded private key file and returns
/// the raw private key data.
///
/// **Memory management:**
/// The returned data is heap-allocated and must be freed by the caller.
pub fn loadPrivateKeyFromPem(
    allocator: std.mem.Allocator,
    pem_data: []const u8,
) ![]const u8 {
    return parsePem(allocator, pem_data, "PRIVATE KEY");
}

/// Create an X509Certificate from PEM-encoded certificate and private key.
/// This is a convenience function that parses both certificate and private key
/// from PEM format and returns an X509Certificate struct.
///
/// **Memory management:**
/// The returned X509Certificate contains heap-allocated data that must be
/// freed by calling `freeCertificate()`.
pub fn createCertificateFromPem(
    allocator: std.mem.Allocator,
    certificate_pem: []const u8,
    private_key_pem: []const u8,
) !X509Certificate {
    const cert_data = try loadCertificateFromPem(allocator, certificate_pem);
    errdefer allocator.free(cert_data);

    const key_data = try loadPrivateKeyFromPem(allocator, private_key_pem);
    errdefer allocator.free(key_data);

    return X509Certificate{
        .certificate = cert_data,
        .private_key = key_data,
    };
}

/// Free the memory allocated for an X509Certificate.
/// This function should be called when an X509Certificate created with
/// `createCertificateFromPem()` is no longer needed.
pub fn freeCertificate(
    allocator: std.mem.Allocator,
    certificate: X509Certificate,
) void {
    allocator.free(certificate.certificate);
    allocator.free(certificate.private_key);
}

// Test that AuthenticationMethod enum has all expected values.
test "AuthenticationMethod enum values" {
    // Test each enum value exists
    _ = AuthenticationMethod.anonymous;
    _ = AuthenticationMethod.username_password;
    _ = AuthenticationMethod.x509_certificate;
    _ = AuthenticationMethod.issued_token;

    // Verify we have all expected authentication methods
    // (This is a simple check - the actual count is verified by the compiler)
}

// Test UserIdentityToken union functionality.
test "UserIdentityToken union" {
    const testing = std.testing;

    // Test anonymous token
    const anonymous = UserIdentityToken{ .anonymous = {} };
    try testing.expectEqual(AuthenticationMethod.anonymous, @as(AuthenticationMethod, anonymous));

    // Test username/password token
    const userpass = UserIdentityToken{
        .username_password = .{
            .username = "testuser",
            .password = "testpass",
        },
    };
    try testing.expectEqual(AuthenticationMethod.username_password, @as(AuthenticationMethod, userpass));
    try testing.expectEqualStrings("testuser", userpass.username_password.username);
    try testing.expectEqualStrings("testpass", userpass.username_password.password);

    // Test X.509 certificate token
    const cert = UserIdentityToken{
        .x509_certificate = .{
            .certificate = "-----BEGIN CERTIFICATE-----\ntest\n-----END CERTIFICATE-----",
            .private_key = "-----BEGIN PRIVATE KEY-----\ntest\n-----END PRIVATE KEY-----",
        },
    };
    try testing.expectEqual(AuthenticationMethod.x509_certificate, @as(AuthenticationMethod, cert));
    try testing.expect(cert.x509_certificate.certificate.len > 0);

    // Test issued token
    const token = UserIdentityToken{
        .issued_token = .{
            .token_data = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
            .token_type = "JWT",
        },
    };
    try testing.expectEqual(AuthenticationMethod.issued_token, @as(AuthenticationMethod, token));
    try testing.expect(token.issued_token.token_data.len > 0);
}

// Test AuthenticationConfig default values.
test "AuthenticationConfig default values" {
    const testing = std.testing;

    const default_config = AuthenticationConfig{
        .identity_token = .anonymous,
    };

    try testing.expectEqual(AuthenticationMethod.anonymous, @as(AuthenticationMethod, default_config.identity_token));
    try testing.expect(default_config.security_policy_uri == null);
    try testing.expectEqual(c.UA_MESSAGESECURITYMODE_SIGNANDENCRYPT, default_config.security_mode);
}

// Test AuthenticationConfig with username/password.
test "AuthenticationConfig with username/password" {
    const testing = std.testing;

    const userpass_config = AuthenticationConfig{
        .identity_token = .{
            .username_password = .{
                .username = "admin",
                .password = "secret",
            },
        },
        .security_policy_uri = "http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256",
        .security_mode = c.UA_MESSAGESECURITYMODE_SIGN,
    };

    try testing.expectEqual(AuthenticationMethod.username_password, @as(AuthenticationMethod, userpass_config.identity_token));
    try testing.expect(userpass_config.security_policy_uri != null);
    try testing.expectEqualStrings("http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256", userpass_config.security_policy_uri.?);
    try testing.expectEqual(c.UA_MESSAGESECURITYMODE_SIGN, userpass_config.security_mode);
}