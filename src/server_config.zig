const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");

/// Security mode for OPC UA connections
pub const SecurityMode = enum {
    /// No security
    none,
    /// Sign messages only
    sign,
    /// Sign and encrypt messages
    sign_and_encrypt,

    /// Convert to C API representation
    pub fn toC(self: SecurityMode) c.UA_MessageSecurityMode {
        return switch (self) {
            .none => c.UA_MESSAGESECURITYMODE_NONE,
            .sign => c.UA_MESSAGESECURITYMODE_SIGN,
            .sign_and_encrypt => c.UA_MESSAGESECURITYMODE_SIGNANDENCRYPT,
        };
    }

    /// Convert from C API representation
    pub fn fromC(value: c.UA_MessageSecurityMode) SecurityMode {
        return switch (value) {
            c.UA_MESSAGESECURITYMODE_NONE => .none,
            c.UA_MESSAGESECURITYMODE_SIGN => .sign,
            c.UA_MESSAGESECURITYMODE_SIGNANDENCRYPT => .sign_and_encrypt,
            else => .none, // Default to none for invalid values
        };
    }
};

/// Security configuration for an OPC UA server
pub const SecurityConfig = struct {
    /// Server certificate (DER-encoded)
    certificate: []const u8,

    /// Private key (PEM or DER-encoded)
    private_key: []const u8,

    /// Trusted certificates (client certificates that are trusted)
    trust_list: []const []const u8 = &.{},

    /// Certificate issuer list
    issuer_list: []const []const u8 = &.{},

    /// Certificate revocation list
    revocation_list: []const []const u8 = &.{},

    /// Security mode
    security_mode: SecurityMode = .sign_and_encrypt,
};

/// Configuration for an OPC UA server
pub const ServerConfig = struct {
    /// Port number for the server (default: 4840)
    port: u16 = 4840,

    /// Shutdown delay in milliseconds (default: 0)
    shutdown_delay: f64 = 0.0,

    /// Enable TCP transport (default: true)
    tcp_enabled: bool = true,

    /// TCP buffer size in bytes (default: 65536)
    tcp_buf_size: u32 = 65536,

    /// Security configuration (optional, default: no security)
    security: ?SecurityConfig = null,

    /// Apply this configuration to a C UA_ServerConfig
    ///
    /// This method configures the provided C server config struct with the settings
    /// from this Zig config. It handles both secure and non-secure configurations.
    ///
    /// The allocator is used for temporary allocations needed to convert Zig data
    /// to C representations. These allocations are freed before returning.
    ///
    /// **Errors:**
    /// - `BadInternalError` - Configuration setup failed
    /// - `OutOfMemory` - Allocation failed
    pub fn applyToC(self: ServerConfig, allocator: std.mem.Allocator, c_config: *c.UA_ServerConfig) !void {
        if (self.security) |sec| {
            // Configure with security
            const c_cert = helpers.helper_createByteString(
                sec.certificate.ptr,
                sec.certificate.len,
            );
            const c_key = helpers.helper_createByteString(
                sec.private_key.ptr,
                sec.private_key.len,
            );

            // Convert trust list to C array
            var c_trust_list: ?[*]c.UA_ByteString = null;
            var trust_list_mem: []c.UA_ByteString = &.{};
            if (sec.trust_list.len > 0) {
                trust_list_mem = try allocator.alloc(c.UA_ByteString, sec.trust_list.len);
                for (sec.trust_list, 0..) |trust, i| {
                    trust_list_mem[i] = helpers.helper_createByteString(trust.ptr, trust.len);
                }
                c_trust_list = trust_list_mem.ptr;
            }
            defer if (trust_list_mem.len > 0) allocator.free(trust_list_mem);

            // Convert issuer list to C array
            var c_issuer_list: ?[*]c.UA_ByteString = null;
            var issuer_list_mem: []c.UA_ByteString = &.{};
            if (sec.issuer_list.len > 0) {
                issuer_list_mem = try allocator.alloc(c.UA_ByteString, sec.issuer_list.len);
                for (sec.issuer_list, 0..) |issuer, i| {
                    issuer_list_mem[i] = helpers.helper_createByteString(issuer.ptr, issuer.len);
                }
                c_issuer_list = issuer_list_mem.ptr;
            }
            defer if (issuer_list_mem.len > 0) allocator.free(issuer_list_mem);

            // Convert revocation list to C array
            var c_revocation_list: ?[*]c.UA_ByteString = null;
            var revocation_list_mem: []c.UA_ByteString = &.{};
            if (sec.revocation_list.len > 0) {
                revocation_list_mem = try allocator.alloc(c.UA_ByteString, sec.revocation_list.len);
                for (sec.revocation_list, 0..) |revocation, i| {
                    revocation_list_mem[i] = helpers.helper_createByteString(revocation.ptr, revocation.len);
                }
                c_revocation_list = revocation_list_mem.ptr;
            }
            defer if (revocation_list_mem.len > 0) allocator.free(revocation_list_mem);

            const status = helpers.helper_serverConfigSetSecure(
                c_config,
                self.port,
                &c_cert,
                &c_key,
                c_trust_list,
                sec.trust_list.len,
                c_issuer_list,
                sec.issuer_list.len,
                c_revocation_list,
                sec.revocation_list.len,
            );
            if (status != c.UA_STATUSCODE_GOOD) return error.BadInternalError;
        } else {
            // Configure without security
            const status = helpers.helper_serverConfigSetMinimal(c_config, self.port, null);
            if (status != c.UA_STATUSCODE_GOOD) return error.BadInternalError;
        }

        // Apply other settings
        c_config.shutdownDelay = self.shutdown_delay;
        c_config.tcpEnabled = self.tcp_enabled;
        c_config.tcpBufSize = self.tcp_buf_size;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "SecurityMode enum values" {
    const testing = std.testing;
    std.testing.refAllDecls(@This());

    try testing.expectEqual(SecurityMode.none, .none);
    try testing.expectEqual(SecurityMode.sign, .sign);
    try testing.expectEqual(SecurityMode.sign_and_encrypt, .sign_and_encrypt);
}

test "SecurityMode toC conversion" {
    const testing = std.testing;

    try testing.expectEqual(
        @as(c.UA_MessageSecurityMode, c.UA_MESSAGESECURITYMODE_NONE),
        SecurityMode.none.toC(),
    );
    try testing.expectEqual(
        @as(c.UA_MessageSecurityMode, c.UA_MESSAGESECURITYMODE_SIGN),
        SecurityMode.sign.toC(),
    );
    try testing.expectEqual(
        @as(c.UA_MessageSecurityMode, c.UA_MESSAGESECURITYMODE_SIGNANDENCRYPT),
        SecurityMode.sign_and_encrypt.toC(),
    );
}

test "SecurityMode fromC conversion" {
    const testing = std.testing;

    try testing.expectEqual(
        SecurityMode.none,
        SecurityMode.fromC(c.UA_MESSAGESECURITYMODE_NONE),
    );
    try testing.expectEqual(
        SecurityMode.sign,
        SecurityMode.fromC(c.UA_MESSAGESECURITYMODE_SIGN),
    );
    try testing.expectEqual(
        SecurityMode.sign_and_encrypt,
        SecurityMode.fromC(c.UA_MESSAGESECURITYMODE_SIGNANDENCRYPT),
    );
}

test "SecurityMode roundtrip conversion" {
    const testing = std.testing;

    const modes = [_]SecurityMode{ .none, .sign, .sign_and_encrypt };
    for (modes) |mode| {
        const c_mode = mode.toC();
        const roundtrip = SecurityMode.fromC(c_mode);
        try testing.expectEqual(mode, roundtrip);
    }
}

test "SecurityMode fromC handles invalid values" {
    const testing = std.testing;

    // Test that invalid C values default to .none
    const invalid_mode = SecurityMode.fromC(c.UA_MESSAGESECURITYMODE_INVALID);
    try testing.expectEqual(SecurityMode.none, invalid_mode);
}

test "SecurityConfig default values" {
    const testing = std.testing;

    const cert = "fake-cert";
    const key = "fake-key";

    const config = SecurityConfig{
        .certificate = cert,
        .private_key = key,
    };

    try testing.expectEqualStrings(cert, config.certificate);
    try testing.expectEqualStrings(key, config.private_key);
    try testing.expectEqual(@as(usize, 0), config.trust_list.len);
    try testing.expectEqual(@as(usize, 0), config.issuer_list.len);
    try testing.expectEqual(@as(usize, 0), config.revocation_list.len);
    try testing.expectEqual(SecurityMode.sign_and_encrypt, config.security_mode);
}

test "SecurityConfig with trust list" {
    const testing = std.testing;

    const cert = "fake-cert";
    const key = "fake-key";
    const trust_list = [_][]const u8{ "trust1", "trust2", "trust3" };

    const config = SecurityConfig{
        .certificate = cert,
        .private_key = key,
        .trust_list = &trust_list,
        .security_mode = .sign,
    };

    try testing.expectEqual(@as(usize, 3), config.trust_list.len);
    try testing.expectEqualStrings("trust1", config.trust_list[0]);
    try testing.expectEqualStrings("trust2", config.trust_list[1]);
    try testing.expectEqualStrings("trust3", config.trust_list[2]);
    try testing.expectEqual(SecurityMode.sign, config.security_mode);
}

test "ServerConfig default values" {
    const testing = std.testing;

    const config = ServerConfig{};

    try testing.expectEqual(@as(u16, 4840), config.port);
    try testing.expectEqual(@as(f64, 0.0), config.shutdown_delay);
    try testing.expectEqual(true, config.tcp_enabled);
    try testing.expectEqual(@as(u32, 65536), config.tcp_buf_size);
    try testing.expectEqual(@as(?SecurityConfig, null), config.security);
}

test "ServerConfig with custom values" {
    const testing = std.testing;

    const config = ServerConfig{
        .port = 8080,
        .shutdown_delay = 5000.0,
        .tcp_enabled = false,
        .tcp_buf_size = 131072,
    };

    try testing.expectEqual(@as(u16, 8080), config.port);
    try testing.expectEqual(@as(f64, 5000.0), config.shutdown_delay);
    try testing.expectEqual(false, config.tcp_enabled);
    try testing.expectEqual(@as(u32, 131072), config.tcp_buf_size);
}

test "ServerConfig with security" {
    const testing = std.testing;

    const cert = "server-cert";
    const key = "server-key";

    const config = ServerConfig{
        .port = 4840,
        .security = .{
            .certificate = cert,
            .private_key = key,
            .security_mode = .sign_and_encrypt,
        },
    };

    try testing.expect(config.security != null);
    try testing.expectEqualStrings(cert, config.security.?.certificate);
    try testing.expectEqualStrings(key, config.security.?.private_key);
    try testing.expectEqual(SecurityMode.sign_and_encrypt, config.security.?.security_mode);
}

// Note: applyToC tests are skipped because they create actual server configs
// which can cause test hangs due to networking/event loop initialization.
// The method is tested implicitly through Server.initWithConfig() integration tests.
