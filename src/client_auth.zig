const std = @import("std");
const c = @import("c.zig");
const ua_error = @import("ua_error.zig");

/// X.509 certificate for OPC UA authentication.
/// Contains both the certificate and private key in DER format.
pub const Certificate = struct {
    certificate: []const u8,
    private_key: []const u8,
    allocator: std.mem.Allocator,

    /// Load a certificate and private key from DER files.
    ///
    /// This function loads an X.509 certificate and its corresponding
    /// private key from DER-encoded files. Both files must be in
    /// binary DER format (not PEM).
    ///
    /// **Memory management:**
    /// The loaded certificate data is heap-allocated and must be freed
    /// with `deinit()` when no longer needed.
    ///
    /// Example usage:
    /// ```zig
    /// const cert = try Certificate.loadFromFiles(
    ///     allocator,
    ///     "client_cert.der",
    ///     "client_key.der",
    /// );
    /// defer cert.deinit();
    /// ```
    ///
    /// **Errors:**
    /// - `error.OutOfMemory` - Failed to allocate memory for certificate data
    /// - `error.FileNotFound` - Certificate or key file not found
    /// - `error.ReadFailed` - Failed to read certificate or key file
    pub fn loadFromFiles(
        allocator: std.mem.Allocator,
        cert_path: []const u8,
        key_path: []const u8,
    ) !Certificate {
        const cert_data = try std.fs.cwd().readFileAlloc(allocator, cert_path, std.math.maxInt(usize));
        errdefer allocator.free(cert_data);

        const key_data = try std.fs.cwd().readFileAlloc(allocator, key_path, std.math.maxInt(usize));
        errdefer allocator.free(key_data);

        return Certificate{
            .certificate = cert_data,
            .private_key = key_data,
            .allocator = allocator,
        };
    }

    /// Load a certificate and private key from PEM files.
    ///
    /// This function loads an X.509 certificate and its corresponding
    /// private key from PEM-encoded files and converts them to DER format.
    /// Both files must be in PEM format (base64-encoded with headers).
    ///
    /// **Memory management:**
    /// The loaded certificate data is heap-allocated and must be freed
    /// with `deinit()` when no longer needed.
    ///
    /// Example usage:
    /// ```zig
    /// const cert = try Certificate.loadFromPemFiles(
    ///     allocator,
    ///     "client_cert.pem",
    ///     "client_key.pem",
    /// );
    /// defer cert.deinit();
    /// ```
    ///
    /// **Errors:**
    /// - `error.OutOfMemory` - Failed to allocate memory for certificate data
    /// - `error.FileNotFound` - Certificate or key file not found
    /// - `error.ReadFailed` - Failed to read certificate or key file
    /// - `error.InvalidPem` - PEM file format is invalid
    pub fn loadFromPemFiles(
        allocator: std.mem.Allocator,
        cert_path: []const u8,
        key_path: []const u8,
    ) !Certificate {
        const cert_pem = try std.fs.cwd().readFileAlloc(allocator, cert_path, std.math.maxInt(usize));
        defer allocator.free(cert_pem);

        const key_pem = try std.fs.cwd().readFileAlloc(allocator, key_path, std.math.maxInt(usize));
        defer allocator.free(key_pem);

        return try Certificate.fromPem(allocator, cert_pem, key_pem);
    }

    /// Create a certificate from PEM strings.
    ///
    /// This function creates a certificate from PEM-encoded strings
    /// (certificate and private key) and converts them to DER format.
    ///
    /// **Memory management:**
    /// The certificate data is heap-allocated and must be freed
    /// with `deinit()` when no longer needed.
    ///
    /// Example usage:
    /// ```zig
    /// const cert_pem = \"\"\"-----BEGIN CERTIFICATE-----
    /// MII...certificate data...
    /// -----END CERTIFICATE-----\"\"\";
    /// const key_pem = \"\"\"-----BEGIN PRIVATE KEY-----
    /// MII...private key data...
    /// -----END PRIVATE KEY-----\"\"\";
    /// const cert = try Certificate.fromPem(allocator, cert_pem, key_pem);
    /// defer cert.deinit();
    /// ```
    ///
    /// **Errors:**
    /// - `error.OutOfMemory` - Failed to allocate memory for certificate data
    /// - `error.InvalidPem` - PEM format is invalid
    pub fn fromPem(
        allocator: std.mem.Allocator,
        cert_pem: []const u8,
        key_pem: []const u8,
    ) !Certificate {
        // Parse certificate PEM
        const cert = try parsePem(allocator, cert_pem, "CERTIFICATE");
        errdefer allocator.free(cert);

        // Parse private key PEM
        const key = try parsePem(allocator, key_pem, "PRIVATE KEY");
        errdefer allocator.free(key);

        return Certificate{
            .certificate = cert,
            .private_key = key,
            .allocator = allocator,
        };
    }

    /// Parse a PEM-encoded string into DER format.
    ///
    /// This is a helper function that extracts the base64-encoded data
    /// from a PEM file and decodes it to binary DER format.
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
            if (trimmed.len == 0) {
                continue;
            }

            if (std.mem.startsWith(u8, trimmed, "-----BEGIN ")) {
                const label_start = "-----BEGIN ".len;
                const label_end = trimmed.len - "-----".len;
                const label = trimmed[label_start..label_end];
                if (!std.mem.eql(u8, label, expected_label)) {
                    return error.InvalidPem;
                }
                in_section = true;
                continue;
            }

            if (std.mem.startsWith(u8, trimmed, "-----END ")) {
                in_section = false;
                break;
            }

            if (in_section) {
                try base64_data.appendSlice(trimmed);
            }
        }

        if (in_section) {
            return error.InvalidPem; // Missing END marker
        }

        // Decode base64
        const der = try allocator.alloc(u8, try std.base64.standard.Decoder.calcSizeForSlice(base64_data.items));
        errdefer allocator.free(der);
        _ = try std.base64.standard.Decoder.decode(der, base64_data.items);

        return der;
    }

    /// Convert certificate to C types for use with the open62541 C API.
    ///
    /// This function allocates C UA_ByteString structures and copies the
    /// certificate and private key data into them. The caller is responsible
    /// for freeing the C structures with UA_ByteString_delete.
    ///
    /// **Memory management:**
    /// The returned C structures are heap-allocated and must be freed
    /// with UA_ByteString_delete.
    pub fn toC(self: Certificate) !struct { certificate: *c.UA_ByteString, private_key: *c.UA_ByteString } {
        var certificate = c.UA_ByteString_new();
        defer c.UA_ByteString_delete(certificate);
        
        const cert_status = c.UA_ByteString_allocBuffer(
            certificate,
            @intCast(self.certificate.len),
        );
        if (cert_status != c.UA_STATUSCODE_GOOD) {
            return ua_error.OpcUaError.BadCertificateInvalid;
        }
        
        // Copy certificate data
        const cert_data = @as([*]u8, @ptrCast(certificate.data))[0..self.certificate.len];
        @memcpy(cert_data, self.certificate);
        
        // Load private key from PEM data  
        var private_key = c.UA_ByteString_new();
        defer c.UA_ByteString_delete(private_key);
        
        const key_status = c.UA_ByteString_allocBuffer(
            private_key,
            @intCast(self.private_key.len),
        );
        if (key_status != c.UA_STATUSCODE_GOOD) {
            return ua_error.OpcUaError.BadCertificateInvalid;
        }
        
        // Copy private key data
        const key_data = @as([*]u8, @ptrCast(private_key.data))[0..self.private_key.len];
        @memcpy(key_data, self.private_key);

        // Take ownership of the C structures
        const cert_ptr = c.UA_ByteString_new();
        c.UA_ByteString_copy(certificate, cert_ptr);
        
        const key_ptr = c.UA_ByteString_new();
        c.UA_ByteString_copy(private_key, key_ptr);

        return .{
            .certificate = cert_ptr,
            .private_key = key_ptr,
        };
    }

    /// Deinitialize the certificate.
    ///
    /// This function frees all heap-allocated certificate data.
    ///
    /// **Memory management:**
    /// Must be called when the certificate is no longer needed to avoid
    /// memory leaks.
    pub fn deinit(self: Certificate) void {
        self.allocator.free(self.certificate);
        self.allocator.free(self.private_key);
    }
};