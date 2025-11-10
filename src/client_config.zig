const std = @import("std");
const c = @import("c.zig");
const server_config = @import("server_config.zig");
const helpers = @import("helpers.zig");

// Re-export SecurityMode from server_config for consistency
pub const SecurityMode = server_config.SecurityMode;

/// Security configuration for an OPC UA client
pub const SecurityConfig = struct {
    /// Client certificate (DER-encoded), optional
    certificate: ?[]const u8 = null,

    /// Private key (PEM or DER-encoded), optional
    private_key: ?[]const u8 = null,

    /// Security mode
    security_mode: SecurityMode = .none,

    /// Security policy URI (e.g., "http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256")
    /// If null, the client will select any matching security policy
    security_policy_uri: ?[]const u8 = null,
};

/// Configuration for an OPC UA client
pub const ClientConfig = struct {
    /// Response timeout in milliseconds (default: 5000ms)
    timeout: u32 = 5000,

    /// Secure channel lifetime in milliseconds (default: 600000ms = 10min)
    secure_channel_lifetime: u32 = 600000,

    /// Requested session timeout in milliseconds (default: 1200000ms = 20min)
    requested_session_timeout: u32 = 1200000,

    /// Connectivity check interval in milliseconds (0 = disabled)
    connectivity_check_interval: u32 = 0,

    /// Disable automatic reconnection
    no_reconnect: bool = false,

    /// Don't automatically create a new session when the initial one is lost
    no_new_session: bool = false,

    /// Security configuration (optional, default: no security)
    security: ?SecurityConfig = null,

    /// Apply this configuration to a C UA_ClientConfig
    ///
    /// This method configures the provided C client config struct with the settings
    /// from this Zig config. It handles both secure and non-secure configurations.
    ///
    /// The allocator is used for temporary allocations needed to convert Zig data
    /// to C representations. These allocations are freed before returning.
    ///
    /// **Errors:**
    /// - `BadInternalError` - Configuration setup failed
    /// - `OutOfMemory` - Allocation failed
    pub fn applyToC(self: ClientConfig, allocator: std.mem.Allocator, c_config: *c.UA_ClientConfig) !void {
        _ = allocator; // Not needed for basic config, but kept for API consistency

        if (self.security) |sec| {
            // Configure with security
            var c_cert_ptr: ?*const c.UA_ByteString = null;
            // SAFETY: Initialized conditionally below by helper_createByteString before use
            var c_cert: c.UA_ByteString = undefined;
            if (sec.certificate) |cert| {
                c_cert = helpers.helper_createByteString(cert.ptr, cert.len);
                c_cert_ptr = &c_cert;
            }

            var c_key_ptr: ?*const c.UA_ByteString = null;
            // SAFETY: Initialized conditionally below by helper_createByteString before use
            var c_key: c.UA_ByteString = undefined;
            if (sec.private_key) |key| {
                c_key = helpers.helper_createByteString(key.ptr, key.len);
                c_key_ptr = &c_key;
            }

            // Convert security policy URI to null-terminated string if provided
            var policy_uri_buf: [256]u8 = undefined;
            var policy_uri_z: ?[*:0]const u8 = null;
            if (sec.security_policy_uri) |uri| {
                if (uri.len < policy_uri_buf.len) {
                    @memcpy(policy_uri_buf[0..uri.len], uri);
                    policy_uri_buf[uri.len] = 0;
                    policy_uri_z = @ptrCast(&policy_uri_buf);
                }
            }

            const status = helpers.helper_clientConfigSetSecure(
                c_config,
                c_cert_ptr,
                c_key_ptr,
                sec.security_mode.toC(),
                policy_uri_z,
            );
            if (status != c.UA_STATUSCODE_GOOD) return error.BadInternalError;
        } else {
            // Configure without security
            const status = helpers.helper_clientConfigSetMinimal(c_config);
            if (status != c.UA_STATUSCODE_GOOD) return error.BadInternalError;
        }

        // Apply other settings
        c_config.timeout = self.timeout;
        c_config.secureChannelLifeTime = self.secure_channel_lifetime;
        c_config.requestedSessionTimeout = self.requested_session_timeout;
        c_config.connectivityCheckInterval = self.connectivity_check_interval;
        c_config.noReconnect = self.no_reconnect;
        c_config.noNewSession = self.no_new_session;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "SecurityConfig default values" {
    const testing = std.testing;
    std.testing.refAllDecls(@This());

    const config = SecurityConfig{};

    try testing.expectEqual(@as(?[]const u8, null), config.certificate);
    try testing.expectEqual(@as(?[]const u8, null), config.private_key);
    try testing.expectEqual(SecurityMode.none, config.security_mode);
    try testing.expectEqual(@as(?[]const u8, null), config.security_policy_uri);
}

test "SecurityConfig with certificate and key" {
    const testing = std.testing;

    const cert = "client-cert";
    const key = "client-key";
    const policy = "http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256";

    const config = SecurityConfig{
        .certificate = cert,
        .private_key = key,
        .security_mode = .sign_and_encrypt,
        .security_policy_uri = policy,
    };

    try testing.expect(config.certificate != null);
    try testing.expectEqualStrings(cert, config.certificate.?);
    try testing.expect(config.private_key != null);
    try testing.expectEqualStrings(key, config.private_key.?);
    try testing.expectEqual(SecurityMode.sign_and_encrypt, config.security_mode);
    try testing.expect(config.security_policy_uri != null);
    try testing.expectEqualStrings(policy, config.security_policy_uri.?);
}

test "ClientConfig default values" {
    const testing = std.testing;

    const config = ClientConfig{};

    try testing.expectEqual(@as(u32, 5000), config.timeout);
    try testing.expectEqual(@as(u32, 600000), config.secure_channel_lifetime);
    try testing.expectEqual(@as(u32, 1200000), config.requested_session_timeout);
    try testing.expectEqual(@as(u32, 0), config.connectivity_check_interval);
    try testing.expectEqual(false, config.no_reconnect);
    try testing.expectEqual(false, config.no_new_session);
    try testing.expectEqual(@as(?SecurityConfig, null), config.security);
}

test "ClientConfig with custom values" {
    const testing = std.testing;

    const config = ClientConfig{
        .timeout = 10000,
        .secure_channel_lifetime = 300000,
        .requested_session_timeout = 600000,
        .connectivity_check_interval = 1000,
        .no_reconnect = true,
        .no_new_session = true,
    };

    try testing.expectEqual(@as(u32, 10000), config.timeout);
    try testing.expectEqual(@as(u32, 300000), config.secure_channel_lifetime);
    try testing.expectEqual(@as(u32, 600000), config.requested_session_timeout);
    try testing.expectEqual(@as(u32, 1000), config.connectivity_check_interval);
    try testing.expectEqual(true, config.no_reconnect);
    try testing.expectEqual(true, config.no_new_session);
}

test "ClientConfig with security" {
    const testing = std.testing;

    const cert = "client-cert";
    const key = "client-key";

    const config = ClientConfig{
        .timeout = 15000,
        .security = .{
            .certificate = cert,
            .private_key = key,
            .security_mode = .sign,
        },
    };

    try testing.expect(config.security != null);
    try testing.expect(config.security.?.certificate != null);
    try testing.expectEqualStrings(cert, config.security.?.certificate.?);
    try testing.expect(config.security.?.private_key != null);
    try testing.expectEqualStrings(key, config.security.?.private_key.?);
    try testing.expectEqual(SecurityMode.sign, config.security.?.security_mode);
}

test "ClientConfig no security with custom timeout" {
    const testing = std.testing;

    const config = ClientConfig{
        .timeout = 20000,
        .no_reconnect = false,
    };

    try testing.expectEqual(@as(u32, 20000), config.timeout);
    try testing.expectEqual(false, config.no_reconnect);
    try testing.expectEqual(@as(?SecurityConfig, null), config.security);
}

// Note: applyToC tests are skipped because they create actual client configs
// which can cause test hangs due to networking/event loop initialization.
// The method is tested implicitly through Client.initWithConfig() integration tests.
