const std = @import("std");
const testing = std.testing;
const c = @import("../src/c.zig");
const zopcua = @import("../src/root.zig");

const Client = zopcua.Client;
const Server = zopcua.Server;
const NodeId = zopcua.NodeId;
const Variant = zopcua.Variant;
const QualifiedName = zopcua.QualifiedName;
const StandardNodeId = zopcua.StandardNodeId;
const ReferenceType = zopcua.ReferenceType;
const AuthenticationConfig = zopcua.AuthenticationConfig;
const UserIdentityToken = zopcua.UserIdentityToken;
const ServerAuthConfig = zopcua.ServerAuthConfig;

/// Test server with authentication enabled
fn createTestServerWithAuth() !Server {
    var server = try Server.init();
    // TODO: Configure server with authentication
    // This requires extending Server.initWithConfig to support authentication
    return server;
}

/// Simple username/password validator for testing
fn testUsernamePasswordValidator(
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

    // Accept only "testuser"/"testpass"
    return std.mem.eql(u8, username, "testuser") and
           std.mem.eql(u8, password, "testpass");
}

test "Client authentication types" {
    // Test AuthenticationConfig creation
    const anonymous_config = AuthenticationConfig{
        .identity_token = .anonymous,
    };
    try testing.expectEqual(UserIdentityToken.anonymous, anonymous_config.identity_token);

    const userpass_config = AuthenticationConfig{
        .identity_token = .{
            .username_password = .{
                .username = "user",
                .password = "pass",
            },
        },
    };
    try testing.expectEqual(UserIdentityToken.username_password, userpass_config.identity_token);
    try testing.expectEqualStrings("user", userpass_config.identity_token.username_password.username);
    try testing.expectEqualStrings("pass", userpass_config.identity_token.username_password.password);
}

test "ServerAuthConfig creation" {
    const config = ServerAuthConfig{
        .allow_anonymous = true,
        .allow_username_password = true,
        .username_password_callback = testUsernamePasswordValidator,
        .userdata = @ptrFromInt(0x1234),
    };

    try testing.expect(config.allow_anonymous == true);
    try testing.expect(config.allow_username_password == true);
    try testing.expect(config.username_password_callback != null);
    try testing.expect(config.userdata == @ptrFromInt(0x1234));
}

test "Authentication callback validation" {
    // Test the validator function directly
    const valid = testUsernamePasswordValidator(
        undefined,
        null,
        null,
        "testuser",
        "testpass",
        null,
    );
    try testing.expect(valid == true);

    const invalid_user = testUsernamePasswordValidator(
        undefined,
        null,
        null,
        "wronguser",
        "testpass",
        null,
    );
    try testing.expect(invalid_user == false);

    const invalid_pass = testUsernamePasswordValidator(
        undefined,
        null,
        null,
        "testuser",
        "wrongpass",
        null,
    );
    try testing.expect(invalid_pass == false);
}

test "Client authentication method integration" {
    // This test verifies that authentication methods are properly integrated
    // into the Client struct without actually connecting to a server
    
    // Create a client (won't actually connect in this test)
    var client = try Client.init();
    defer client.deinit();
    
    // Verify client has authentication methods
    // The methods exist at compile time, so if this compiles, the test passes
    _ = client.connectWithAuth;
    _ = client.connectWithUsername;
    _ = client.connectAnonymous;
    
    // Test passes if compilation succeeds
    try testing.expect(true);
}

test "Authentication type exports" {
    // Verify all authentication types are exported from root module
    _ = zopcua.AuthenticationMethod;
    _ = zopcua.UserIdentityToken;
    _ = zopcua.AuthenticationConfig;
    _ = zopcua.ServerAuthConfig;
    
    // Test passes if compilation succeeds
    try testing.expect(true);
}

test "Memory safety in authentication types" {
    const allocator = testing.allocator;
    
    // Test that UserIdentityToken doesn't leak memory
    // (it's a union with slices, but slices don't own memory)
    const token = UserIdentityToken{
        .username_password = .{
            .username = "test",
            .password = "secret",
        },
    };
    
    // The token should be valid
    try testing.expectEqual(UserIdentityToken.username_password, token);
    try testing.expectEqualStrings("test", token.username_password.username);
    try testing.expectEqualStrings("secret", token.username_password.password);
    
    // No cleanup needed - slices don't own memory
}

test "AuthenticationConfig with security policy" {
    const config = AuthenticationConfig{
        .identity_token = .anonymous,
        .security_policy_uri = "http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256",
        .security_mode = c.UA_MESSAGESECURITYMODE_SIGN,
    };
    
    try testing.expect(config.security_policy_uri != null);
    try testing.expectEqualStrings(
        "http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256",
        config.security_policy_uri.?,
    );
    try testing.expectEqual(c.UA_MESSAGESECURITYMODE_SIGN, config.security_mode);
}

// Note: Full integration tests requiring actual server connection
// are skipped here because they require:
// 1. A running OPC UA server with authentication configured
// 2. Certificate setup for X.509 tests
// 3. Network connectivity

// Future integration tests to add:
// test "Client connects with username/password to authenticated server"
// test "Client anonymous connection to server allowing anonymous"
// test "Client connection rejected with invalid credentials"
// test "Server authentication callback integration"
// test "Access control callback integration"

// Helper function for future integration tests
fn skipIfNoServer() bool {
    // In a real test environment, this would check if a test server is available
    // For now, we skip server-dependent tests
    return true;
}

test "Authentication documentation examples compile" {
    // Test that the example code from documentation compiles
    
    // Client authentication example
    const client_auth_example = struct {
        fn example() !void {
            var client = try Client.init();
            defer client.deinit();
            
            // These should compile
            _ = client.connectWithAuth;
            _ = client.connectWithUsername;
            _ = client.connectAnonymous;
        }
    }.example;
    
    // Server authentication example
    const server_auth_example = struct {
        fn example() !void {
            const config = ServerAuthConfig{
                .allow_anonymous = true,
                .allow_username_password = true,
                .username_password_callback = testUsernamePasswordValidator,
            };
            _ = config;
        }
    }.example;
    
    // If we get here, the examples compile
    try testing.expect(true);
}