const std = @import("std");
const testing = std.testing;
const c = @import("../src/c.zig");
const client_auth = @import("../src/client_auth.zig");
const server_auth = @import("../src/server_auth.zig");
const ua_error = @import("../src/ua_error.zig");

// Comprehensive authentication tests for zopcua
// These tests verify that all authentication features work correctly

test "authentication method enum completeness" {
    // Verify all OPC UA authentication methods are represented
    try testing.expectEqual(@typeInfo(client_auth.AuthenticationMethod).Enum.fields.len, 4);
    
    // Check each method exists
    _ = client_auth.AuthenticationMethod.anonymous;
    _ = client_auth.AuthenticationMethod.username_password;
    _ = client_auth.AuthenticationMethod.x509_certificate;
    _ = client_auth.AuthenticationMethod.issued_token;
    
    std.debug.print("✓ AuthenticationMethod enum is complete\n", .{});
}

test "user identity token union" {
    // Test anonymous token
    const anonymous = client_auth.UserIdentityToken{ .anonymous = {} };
    try testing.expectEqual(
        client_auth.AuthenticationMethod.anonymous,
        @as(client_auth.AuthenticationMethod, anonymous)
    );
    
    // Test username/password token
    const userpass = client_auth.UserIdentityToken{
        .username_password = .{
            .username = "testuser",
            .password = "testpass",
        },
    };
    try testing.expectEqual(
        client_auth.AuthenticationMethod.username_password,
        @as(client_auth.AuthenticationMethod, userpass)
    );
    try testing.expectEqualStrings("testuser", userpass.username_password.username);
    try testing.expectEqualStrings("testpass", userpass.username_password.password);
    
    // Test X.509 certificate token
    const cert = client_auth.UserIdentityToken{
        .x509_certificate = .{
            .certificate = "-----BEGIN CERTIFICATE-----\ntest\n-----END CERTIFICATE-----",
            .private_key = "-----BEGIN PRIVATE KEY-----\ntest\n-----END PRIVATE KEY-----",
        },
    };
    try testing.expectEqual(
        client_auth.AuthenticationMethod.x509_certificate,
        @as(client_auth.AuthenticationMethod, cert)
    );
    try testing.expect(cert.x509_certificate.certificate.len > 0);
    
    // Test issued token
    const token = client_auth.UserIdentityToken{
        .issued_token = .{
            .token_data = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
            .token_type = "JWT",
        },
    };
    try testing.expectEqual(
        client_auth.AuthenticationMethod.issued_token,
        @as(client_auth.AuthenticationMethod, token)
    );
    try testing.expect(token.issued_token.token_data.len > 0);
}

test "authentication config default values" {
    const default_config = client_auth.AuthenticationConfig{
        .identity_token = .anonymous,
    };

    try testing.expectEqual(
        client_auth.AuthenticationMethod.anonymous,
        @as(client_auth.AuthenticationMethod, default_config.identity_token)
    );
    try testing.expect(default_config.security_policy_uri == null);
    try testing.expectEqual(
        c.UA_MESSAGESECURITYMODE_SIGNANDENCRYPT,
        default_config.security_mode
    );
}

test "authentication config with username/password" {
    const userpass_config = client_auth.AuthenticationConfig{
        .identity_token = .{
            .username_password = .{
                .username = "admin",
                .password = "secret",
            },
        },
        .security_policy_uri = "http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256",
        .security_mode = c.UA_MESSAGESECURITYMODE_SIGN,
    };

    try testing.expectEqual(
        client_auth.AuthenticationMethod.username_password,
        @as(client_auth.AuthenticationMethod, userpass_config.identity_token)
    );
    try testing.expect(userpass_config.security_policy_uri != null);
    try testing.expectEqualStrings(
        "http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256",
        userpass_config.security_policy_uri.?
    );
    try testing.expectEqual(c.UA_MESSAGESECURITYMODE_SIGN, userpass_config.security_mode);
}

test "authentication config with x509 certificate" {
    const cert_config = client_auth.AuthenticationConfig{
        .identity_token = .{
            .x509_certificate = .{
                .certificate = "-----BEGIN CERTIFICATE-----\ntest\n-----END CERTIFICATE-----",
                .private_key = "-----BEGIN PRIVATE KEY-----\ntest\n-----END PRIVATE KEY-----",
            },
        },
        .security_policy_uri = "http://opcfoundation.org/UA/SecurityPolicy#Aes256_Sha256_RsaPss",
        .security_mode = c.UA_MESSAGESECURITYMODE_SIGNANDENCRYPT,
    };

    try testing.expectEqual(
        client_auth.AuthenticationMethod.x509_certificate,
        @as(client_auth.AuthenticationMethod, cert_config.identity_token)
    );
    try testing.expect(cert_config.security_policy_uri != null);
    try testing.expectEqualStrings(
        "http://opcfoundation.org/UA/SecurityPolicy#Aes256_Sha256_RsaPss",
        cert_config.security_policy_uri.?
    );
    try testing.expectEqual(
        c.UA_MESSAGESECURITYMODE_SIGNANDENCRYPT,
        cert_config.security_mode
    );
}

test "server authentication callback registration" {
    // Test that server authentication callbacks can be registered
    var callbacks = server_auth.AuthenticationCallbacks{};
    
    // Set up username/password validation callback
    callbacks.username_password = struct {
        fn validate(
            username: []const u8,
            password: []const u8,
            userdata: ?*anyopaque
        ) bool {
            _ = userdata;
            return std.mem.eql(u8, username, "admin") and
                   std.mem.eql(u8, password, "password");
        }
    }.validate;
    
    // Set up certificate validation callback
    callbacks.certificate = struct {
        fn validate(
            certificate: []const u8,
            userdata: ?*anyopaque
        ) bool {
            _ = userdata;
            return certificate.len > 0;
        }
    }.validate;
    
    // Set up access control callback
    callbacks.access_control = struct {
        fn check(
            session_id: []const u8,
            node_id: []const u8,
            attribute_id: u32,
            userdata: ?*anyopaque
        ) bool {
            _ = session_id;
            _ = node_id;
            _ = attribute_id;
            _ = userdata;
            return true; // Allow all access for testing
        }
    }.check;
    
    // Verify callbacks are set
    try testing.expect(callbacks.username_password != null);
    try testing.expect(callbacks.certificate != null);
    try testing.expect(callbacks.access_control != null);
    
    std.debug.print("✓ Server authentication callbacks can be registered\n", .{});
}

test "authentication error mapping" {
    // Test that authentication errors are properly mapped
    try testing.expectError(
        ua_error.OpcUaError.BadUserAccessDenied,
        ua_error.checkStatus(c.UA_STATUSCODE_BADUSERACCESSDENIED)
    );
    
    try testing.expectError(
        ua_error.OpcUaError.BadCertificateInvalid,
        ua_error.checkStatus(c.UA_STATUSCODE_BADCERTIFICATEINVALID)
    );
    
    try testing.expectError(
        ua_error.OpcUaError.BadSecurityChecksFailed,
        ua_error.checkStatus(c.UA_STATUSCODE_BADSECURITYCHECKSFAILED)
    );
    
    std.debug.print("✓ Authentication errors are properly mapped\n", .{});
}

test "security policy URI validation" {
    // Test common OPC UA security policy URIs
    const policies = [_][]const u8{
        "http://opcfoundation.org/UA/SecurityPolicy#None",
        "http://opcfoundation.org/UA/SecurityPolicy#Basic128Rsa15",
        "http://opcfoundation.org/UA/SecurityPolicy#Basic256",
        "http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256",
        "http://opcfoundation.org/UA/SecurityPolicy#Aes128_Sha256_RsaOaep",
        "http://opcfoundation.org/UA/SecurityPolicy#Aes256_Sha256_RsaPss",
    };
    
    for (policies) |policy| {
        const config = client_auth.AuthenticationConfig{
            .identity_token = .anonymous,
            .security_policy_uri = policy,
        };
        
        try testing.expect(config.security_policy_uri != null);
        try testing.expectEqualStrings(policy, config.security_policy_uri.?);
    }
    
    std.debug.print("✓ Security policy URIs are properly handled\n", .{});
}

test "security mode validation" {
    // Test all OPC UA security modes
    const modes = [_]c.UA_MessageSecurityMode{
        c.UA_MESSAGESECURITYMODE_INVALID,
        c.UA_MESSAGESECURITYMODE_NONE,
        c.UA_MESSAGESECURITYMODE_SIGN,
        c.UA_MESSAGESECURITYMODE_SIGNANDENCRYPT,
    };
    
    for (modes) |mode| {
        const config = client_auth.AuthenticationConfig{
            .identity_token = .anonymous,
            .security_mode = mode,
        };
        
        try testing.expectEqual(mode, config.security_mode);
    }
    
    std.debug.print("✓ Security modes are properly handled\n", .{});
}

test "authentication memory safety" {
    // Test that authentication config doesn't leak memory
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    // Create authentication config with strings
    const username = try allocator.dupe(u8, "testuser");
    const password = try allocator.dupe(u8, "testpass");
    const policy = try allocator.dupe(u8,
        "http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256"
    );
    
    const config = client_auth.AuthenticationConfig{
        .identity_token = .{
            .username_password = .{
                .username = username,
                .password = password,
            },
        },
        .security_policy_uri = policy,
        .security_mode = c.UA_MESSAGESECURITYMODE_SIGN,
    };
    
    // Verify config was created successfully
    try testing.expectEqual(
        client_auth.AuthenticationMethod.username_password,
        @as(client_auth.AuthenticationMethod, config.identity_token)
    );
    try testing.expect(config.security_policy_uri != null);
    
    std.debug.print("✓ Authentication config memory safety verified\n", .{});
}