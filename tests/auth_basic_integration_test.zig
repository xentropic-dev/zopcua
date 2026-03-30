const std = @import("std");
const testing = std.testing;
const ua = @import("ua");

test "AuthenticationConfig basic creation" {
    // Test anonymous authentication
    const anonymous_config = ua.AuthenticationConfig{
        .identity_token = .anonymous,
    };
    try testing.expectEqual(ua.UserIdentityToken.anonymous, anonymous_config.identity_token);
    try testing.expect(anonymous_config.security_policy_uri == null);
    try testing.expectEqual(@import("c").UA_MESSAGESECURITYMODE_SIGNANDENCRYPT, anonymous_config.security_mode);

    // Test username/password authentication
    const userpass_config = ua.AuthenticationConfig{
        .identity_token = .{
            .username_password = .{
                .username = "testuser",
                .password = "testpass",
            },
        },
        .security_policy_uri = ua.SecurityPolicy.Basic256Sha256,
        .security_mode = @import("c").UA_MESSAGESECURITYMODE_SIGN,
    };
    try testing.expectEqual(ua.UserIdentityToken.username_password, userpass_config.identity_token);
    try testing.expectEqualStrings("testuser", userpass_config.identity_token.username_password.username);
    try testing.expectEqualStrings("testpass", userpass_config.identity_token.username_password.password);
    try testing.expect(userpass_config.security_policy_uri != null);
    try testing.expectEqualStrings(ua.SecurityPolicy.Basic256Sha256, userpass_config.security_policy_uri.?);
    try testing.expectEqual(@import("c").UA_MESSAGESECURITYMODE_SIGN, userpass_config.security_mode);
}

test "Client authentication API exists and compiles" {
    const allocator = testing.allocator;
    
    // Test that we can create a client with authentication config
    var client = try ua.Client.init();
    defer client.deinit();
    
    // Test that authentication methods exist (compile-time check)
    const auth_config = ua.AuthenticationConfig{
        .identity_token = .anonymous,
    };
    
    // These should compile (we're not actually connecting since we don't have a server)
    _ = client.connectWithAuth;
    _ = client.connectWithUsername;
    
    // Test client_with_auth module
    var client_with_auth = try ua.ClientWithAuth.init(allocator);
    defer client_with_auth.deinit();
    
    // These should also compile
    _ = client_with_auth.connectWithAuth;
    _ = client_with_auth.connectWithUsername;
    
    std.debug.print("✓ Authentication API compiles correctly\n", .{});
}

test "Security policy constants" {
    // Verify all security policy URIs are defined
    try testing.expectEqualStrings(
        "http://opcfoundation.org/UA/SecurityPolicy#None",
        ua.SecurityPolicy.None,
    );
    try testing.expectEqualStrings(
        "http://opcfoundation.org/UA/SecurityPolicy#Basic128Rsa15",
        ua.SecurityPolicy.Basic128Rsa15,
    );
    try testing.expectEqualStrings(
        "http://opcfoundation.org/UA/SecurityPolicy#Basic256",
        ua.SecurityPolicy.Basic256,
    );
    try testing.expectEqualStrings(
        "http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256",
        ua.SecurityPolicy.Basic256Sha256,
    );
    try testing.expectEqualStrings(
        "http://opcfoundation.org/UA/SecurityPolicy#Aes128_Sha256_RsaOaep",
        ua.SecurityPolicy.Aes128_Sha256_RsaOaep,
    );
    try testing.expectEqualStrings(
        "http://opcfoundation.org/UA/SecurityPolicy#Aes256_Sha256_RsaPss",
        ua.SecurityPolicy.Aes256_Sha256_RsaPss,
    );
    
    std.debug.print("✓ All security policy URIs are defined\n", .{});
}

test "UserIdentityToken union completeness" {
    // Test all variants of the UserIdentityToken union
    const anonymous = ua.UserIdentityToken{ .anonymous = {} };
    try testing.expectEqual(ua.AuthenticationMethod.anonymous, @as(ua.AuthenticationMethod, anonymous));
    
    const username_password = ua.UserIdentityToken{
        .username_password = .{
            .username = "user",
            .password = "pass",
        },
    };
    try testing.expectEqual(ua.AuthenticationMethod.username_password, @as(ua.AuthenticationMethod, username_password));
    
    const x509_certificate = ua.UserIdentityToken{
        .x509_certificate = .{
            .certificate = "-----BEGIN CERT-----\ntest\n-----END CERT-----",
            .private_key = "-----BEGIN KEY-----\ntest\n-----END KEY-----",
        },
    };
    try testing.expectEqual(ua.AuthenticationMethod.x509_certificate, @as(ua.AuthenticationMethod, x509_certificate));
    
    const issued_token = ua.UserIdentityToken{
        .issued_token = .{
            .token_data = "jwt.token.here",
            .token_type = "JWT",
        },
    };
    try testing.expectEqual(ua.AuthenticationMethod.issued_token, @as(ua.AuthenticationMethod, issued_token));
    
    std.debug.print("✓ UserIdentityToken union is complete\n", .{});
}