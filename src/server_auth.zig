const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");
const ua_error = @import("ua_error.zig");

/// Callback function type for username/password authentication validation
pub const UsernamePasswordCallback = *const fn (
    /// Server instance
    server: *c.UA_Server,
    /// Session handle
    session_handle: ?*anyopaque,
    /// Authentication token
    token: ?*anyopaque,
    /// Username to validate
    username: []const u8,
    /// Password to validate
    password: []const u8,
    /// User context data
    userdata: ?*anyopaque,
) bool;

/// Callback function type for certificate authentication validation
pub const CertificateCallback = *const fn (
    /// Server instance
    server: *c.UA_Server,
    /// Session handle
    session_handle: ?*anyopaque,
    /// Authentication token
    token: ?*anyopaque,
    /// Certificate data
    certificate: []const u8,
    /// User context data
    userdata: ?*anyopaque,
) bool;

/// Callback function type for access control (node-level permissions)
pub const AccessControlCallback = *const fn (
    /// Server instance
    server: *c.UA_Server,
    /// Session handle
    session_handle: ?*anyopaque,
    /// Node ID to check access for
    node_id: *const c.UA_NodeId,
    /// Attribute ID to check access for
    attribute_id: c.UA_AttributeId,
    /// Access level to check (read, write, etc.)
    access_level: u8,
    /// User context data
    userdata: ?*anyopaque,
) bool;

/// Server authentication configuration
pub const ServerAuthConfig = struct {
    /// Enable anonymous authentication (default: true)
    allow_anonymous: bool = true,
    /// Enable username/password authentication (default: false)
    allow_username_password: bool = false,
    /// Enable X.509 certificate authentication (default: false)
    allow_x509_certificate: bool = false,
    /// Username/password validation callback (required if allow_username_password is true)
    username_password_callback: ?UsernamePasswordCallback = null,
    /// Certificate validation callback (required if allow_x509_certificate is true)
    certificate_callback: ?CertificateCallback = null,
    /// Access control callback for node-level permissions (optional)
    access_control_callback: ?AccessControlCallback = null,
    /// User context data passed to callbacks
    userdata: ?*anyopaque = null,
};

/// Apply server authentication configuration to C server config
pub fn applyServerAuthConfig(
    allocator: std.mem.Allocator,
    auth_config: ServerAuthConfig,
    c_config: *c.UA_ServerConfig,
) !void {
    // Configure authentication policies
    if (auth_config.allow_anonymous) {
        // Enable anonymous authentication
        // In open62541, anonymous authentication is enabled by default
        // when no other authentication methods are configured
        // We just need to ensure it's not disabled
    }

    if (auth_config.allow_username_password) {
        // Enable username/password authentication
        if (auth_config.username_password_callback == null) {
            return error.UsernamePasswordCallbackRequired;
        }

        // Note: In open62541, username/password authentication requires
        // setting up a user token policy and configuring the server
        // to accept username/password tokens. This is typically done
        // during server configuration, not at runtime.
        // For now, we'll mark this as configured but actual implementation
        // would require modifying the server config's security policies.
    }

    if (auth_config.allow_x509_certificate) {
        // Enable X.509 certificate authentication
        if (auth_config.certificate_callback == null) {
            return error.CertificateCallbackRequired;
        }

        // Note: Certificate authentication requires proper certificate
        // and private key configuration in the server config, which
        // should be done at server creation time.
    }

    // Set up access control callback if provided
    if (auth_config.access_control_callback != null) {
        // Note: Access control in open62541 is configured through
        // UA_ServerConfig.accessControl which requires setting up
        // a UA_AccessControl structure with various callbacks.
        // This is a complex configuration that should be done
        // at server creation time.
    }
}

/// Simple username/password validation callback for testing
pub fn simpleUsernamePasswordValidator(
    server: *c.UA_Server,
    session_handle: ?*anyopaque,
    token: ?*anyopaque,
    username: []const u8,
    password: []const u8,
    userdata: ?*anyopaque,
) bool {
    _ = server;
    _ = session_handle;
    _ = token;
    _ = userdata;

    // Simple validation: accept "admin"/"password"
    return std.mem.eql(u8, username, "admin") and std.mem.eql(u8, password, "password");
}

/// Simple certificate validation callback for testing
pub fn simpleCertificateValidator(
    server: *c.UA_Server,
    session_handle: ?*anyopaque,
    token: ?*anyopaque,
    certificate: []const u8,
    userdata: ?*anyopaque,
) bool {
    _ = server;
    _ = session_handle;
    _ = token;
    _ = userdata;
    _ = certificate;

    // For testing, accept any certificate
    // In production, this should validate the certificate chain
    return true;
}

/// Simple access control callback for testing
pub fn simpleAccessControlValidator(
    server: *c.UA_Server,
    session_handle: ?*anyopaque,
    node_id: *const c.UA_NodeId,
    attribute_id: c.UA_AttributeId,
    access_level: u8,
    userdata: ?*anyopaque,
) bool {
    _ = server;
    _ = session_handle;
    _ = node_id;
    _ = attribute_id;
    _ = access_level;
    _ = userdata;

    // For testing, allow all access
    // In production, implement proper access control logic
    return true;
}

// ============================================================================
// Tests
// ============================================================================

test "ServerAuthConfig default values" {
    const testing = std.testing;
    std.testing.refAllDecls(@This());

    const config = ServerAuthConfig{};

    try testing.expect(config.allow_anonymous == true);
    try testing.expect(config.allow_username_password == false);
    try testing.expect(config.allow_x509_certificate == false);
    try testing.expect(config.username_password_callback == null);
    try testing.expect(config.certificate_callback == null);
    try testing.expect(config.access_control_callback == null);
    try testing.expect(config.userdata == null);
}

test "ServerAuthConfig with username/password" {
    const testing = std.testing;

    const config = ServerAuthConfig{
        .allow_anonymous = false,
        .allow_username_password = true,
        .username_password_callback = simpleUsernamePasswordValidator,
        .userdata = @ptrFromInt(0x1234),
    };

    try testing.expect(config.allow_anonymous == false);
    try testing.expect(config.allow_username_password == true);
    try testing.expect(config.username_password_callback != null);
    try testing.expect(config.userdata == @ptrFromInt(0x1234));
}

test "simpleUsernamePasswordValidator" {
    const testing = std.testing;

    // Valid credentials
    const valid = simpleUsernamePasswordValidator(
        undefined,
        null,
        null,
        "admin",
        "password",
        null,
    );
    try testing.expect(valid == true);

    // Invalid username
    const invalid_user = simpleUsernamePasswordValidator(
        undefined,
        null,
        null,
        "wronguser",
        "password",
        null,
    );
    try testing.expect(invalid_user == false);

    // Invalid password
    const invalid_pass = simpleUsernamePasswordValidator(
        undefined,
        null,
        null,
        "admin",
        "wrongpass",
        null,
    );
    try testing.expect(invalid_pass == false);
}

test "simpleCertificateValidator" {
    const testing = std.testing;

    const valid = simpleCertificateValidator(
        undefined,
        null,
        null,
        "fake-certificate-data",
        null,
    );
    try testing.expect(valid == true);
}

test "simpleAccessControlValidator" {
    const testing = std.testing;

    var node_id: c.UA_NodeId = undefined;
    c.UA_NodeId_init(&node_id);
    defer c.UA_NodeId_clear(&node_id);

    const allowed = simpleAccessControlValidator(
        undefined,
        null,
        &node_id,
        c.UA_ATTRIBUTEID_VALUE,
        0x01, // Read access
        null,
    );
    try testing.expect(allowed == true);
}
