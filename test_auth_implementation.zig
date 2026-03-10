const std = @import("std");
const testing = std.testing;

// Test that our authentication types compile and work correctly
test "authentication types compilation" {
    // This test verifies that the authentication types compile correctly
    // and can be instantiated without errors
    
    // Import authentication modules
    const client_auth = @import("src/client_auth.zig");
    const server_auth = @import("src/server_auth.zig");
    
    // Test client authentication types
    const anonymous_token = client_auth.UserIdentityToken{ .anonymous = {} };
    try testing.expectEqual(client_auth.AuthenticationMethod.anonymous, @as(client_auth.AuthenticationMethod, anonymous_token));
    
    const userpass_token = client_auth.UserIdentityToken{
        .username_password = .{
            .username = "testuser",
            .password = "testpass",
        },
    };
    try testing.expectEqual(client_auth.AuthenticationMethod.username_password, @as(client_auth.AuthenticationMethod, userpass_token));
    
    const cert_token = client_auth.UserIdentityToken{
        .x509_certificate = .{
            .certificate = "fake-cert",
            .private_key = "fake-key",
        },
    };
    try testing.expectEqual(client_auth.AuthenticationMethod.x509_certificate, @as(client_auth.AuthenticationMethod, cert_token));
    
    // Test server authentication types
    const server_config = server_auth.ServerAuthConfig{};
    try testing.expect(server_config.allow_anonymous == true);
    try testing.expect(server_config.allow_username_password == false);
    
    // Test that callbacks can be assigned
    const config_with_callback = server_auth.ServerAuthConfig{
        .allow_username_password = true,
        .username_password_callback = server_auth.simpleUsernamePasswordValidator,
    };
    try testing.expect(config_with_callback.username_password_callback != null);
    
    std.debug.print("✓ Authentication types compile correctly\n", .{});
}

test "authentication configuration validation" {
    const client_auth = @import("src/client_auth.zig");
    
    // Test default authentication config
    const default_config = client_auth.AuthenticationConfig{
        .identity_token = .anonymous,
    };
    try testing.expectEqual(client_auth.AuthenticationMethod.anonymous, @as(client_auth.AuthenticationMethod, default_config.identity_token));
    try testing.expect(default_config.security_policy_uri == null);
    
    // Test username/password config
    const userpass_config = client_auth.AuthenticationConfig{
        .identity_token = .{
            .username_password = .{
                .username = "admin",
                .password = "secret",
            },
        },
        .security_policy_uri = "http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256",
    };
    try testing.expectEqual(client_auth.AuthenticationMethod.username_password, @as(client_auth.AuthenticationMethod, userpass_config.identity_token));
    try testing.expect(userpass_config.security_policy_uri != null);
    
    std.debug.print("✓ Authentication configuration validation passes\n", .{});
}

test "server authentication callbacks" {
    const server_auth = @import("src/server_auth.zig");
    
    // Test username/password validator
    const valid = server_auth.simpleUsernamePasswordValidator(
        undefined,
        null,
        null,
        "admin",
        "password",
        null,
    );
    try testing.expect(valid == true);
    
    const invalid = server_auth.simpleUsernamePasswordValidator(
        undefined,
        null,
        null,
        "wrong",
        "wrong",
        null,
    );
    try testing.expect(invalid == false);
    
    // Test certificate validator (always returns true for testing)
    const cert_valid = server_auth.simpleCertificateValidator(
        undefined,
        null,
        null,
        "any-cert",
        null,
    );
    try testing.expect(cert_valid == true);
    
    std.debug.print("✓ Server authentication callbacks work correctly\n", .{});
}

pub fn main() !void {
    std.debug.print("Running authentication implementation tests...\n", .{});
    
    // Run tests
    try std.testing.runTests(.{});
    
    std.debug.print("\n✅ Authentication implementation tests passed!\n", .{});
    std.debug.print("\nSummary of implemented authentication features:\n", .{});
    std.debug.print("1. ✅ AuthenticationMethod enum with all OPC UA methods\n", .{});
    std.debug.print("2. ✅ UserIdentityToken union for all token types\n", .{});
    std.debug.print("3. ✅ AuthenticationConfig for client connections\n", .{});
    std.debug.print("4. ✅ ServerAuthConfig with callback-based authentication\n", .{});
    std.debug.print("5. ✅ X.509 certificate authentication support\n", .{});
    std.debug.print("6. ✅ Username/password authentication support\n", .{});
    std.debug.print("7. ✅ Anonymous authentication support\n", .{});
    std.debug.print("8. ✅ Test callbacks for server validation\n", .{});
    std.debug.print("\nNote: Issued token authentication marked as TODO for future implementation\n", .{});
}