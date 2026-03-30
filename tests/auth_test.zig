const std = @import("std");
const testing = std.testing;
const c = @import("../src/c.zig");
const AuthenticationConfig = @import("../src/client_auth.zig").AuthenticationConfig;
const UserIdentityToken = @import("../src/client_auth.zig").UserIdentityToken;

test "AuthenticationConfig default values" {
    const config = AuthenticationConfig{
        .identity_token = .anonymous,
    };

    try testing.expectEqual(UserIdentityToken.anonymous, config.identity_token);
    try testing.expect(config.security_policy_uri == null);
    try testing.expectEqual(c.UA_MESSAGESECURITYMODE_SIGNANDENCRYPT, config.security_mode);
}

test "AuthenticationConfig with username/password" {
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

    try testing.expectEqual(UserIdentityToken.username_password, userpass_config.identity_token);
    try testing.expect(userpass_config.security_policy_uri != null);
    try testing.expectEqualStrings("http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256", userpass_config.security_policy_uri.?);
    try testing.expectEqual(c.UA_MESSAGESECURITYMODE_SIGN, userpass_config.security_mode);
}

test "UserIdentityToken union" {
    // Anonymous token
    const anonymous = UserIdentityToken{ .anonymous = {} };
    try testing.expectEqual(UserIdentityToken.anonymous, anonymous);

    // Username/password token
    const userpass = UserIdentityToken{
        .username_password = .{
            .username = "testuser",
            .password = "testpass",
        },
    };
    try testing.expectEqual(UserIdentityToken.username_password, userpass);
    try testing.expectEqualStrings("testuser", userpass.username_password.username);
    try testing.expectEqualStrings("testpass", userpass.username_password.password);
}
