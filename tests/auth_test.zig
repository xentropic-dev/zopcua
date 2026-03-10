const std = @import("std");
const testing = std.testing;
const c = @import("../src/c.zig");
const client_auth = @import("../src/client_auth.zig");
const AuthenticationConfig = client_auth.AuthenticationConfig;
const UserIdentityToken = client_auth.UserIdentityToken;

test "AuthenticationConfig creation" {
    // Test anonymous authentication
    const anonymous_config = AuthenticationConfig{
        .identity_token = .anonymous,
    };
    try testing.expectEqual(UserIdentityToken.anonymous, anonymous_config.identity_token);
    try testing.expect(anonymous_config.security_policy_uri == null);
    try testing.expectEqual(c.UA_MESSAGESECURITYMODE_SIGNANDENCRYPT, anonymous_config.security_mode);

    // Test username/password authentication
    const userpass_config = AuthenticationConfig{
        .identity_token = .{
            .username_password = .{
                .username = "testuser",
                .password = "testpass",
            },
        },
        .security_policy_uri = "http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256",
        .security_mode = c.UA_MESSAGESECURITYMODE_SIGN,
    };
    
    try testing.expectEqual(UserIdentityToken.username_password, userpass_config.identity_token);
    try testing.expect(userpass_config.security_policy_uri != null);
    try testing.expectEqualStrings("http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256", userpass_config.security_policy_uri.?);
    try testing.expectEqual(c.UA_MESSAGESECURITYMODE_SIGN, userpass_config.security_mode);
}

test "UserIdentityToken union" {
    // Test anonymous token
    const anonymous_token = UserIdentityToken{ .anonymous = {} };
    try testing.expectEqual(UserIdentityToken.anonymous, anonymous_token);

    // Test username/password token
    const userpass_token = UserIdentityToken{
        .username_password = .{
            .username = "admin",
            .password = "secret",
        },
    };
    try testing.expectEqual(UserIdentityToken.username_password, userpass_token);
    try testing.expectEqualStrings("admin", userpass_token.username_password.username);
    try testing.expectEqualStrings("secret", userpass_token.username_password.password);
}

test "AuthenticationMethod enum" {
    try testing.expectEqual(client_auth.AuthenticationMethod.anonymous, .anonymous);
    try testing.expectEqual(client_auth.AuthenticationMethod.username_password, .username_password);
    try testing.expectEqual(client_auth.AuthenticationMethod.x509_certificate, .x509_certificate);
    try testing.expectEqual(client_auth.AuthenticationMethod.issued_token, .issued_token);
}