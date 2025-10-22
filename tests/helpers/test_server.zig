const std = @import("std");
const ua = @import("ua");

// Re-export helpers for convenience
pub const fixtures = @import("test_fixtures.zig");
pub const assertions = @import("assertions.zig");

/// A reusable test server with lifecycle management
pub const TestServer = struct {
    server: ua.Server,
    thread: ?std.Thread = null,
    running: std.atomic.Value(bool),
    port: u16,
    allocator: std.mem.Allocator,

    /// Initialize a test server on the specified port (default: 4840)
    pub fn init(allocator: std.mem.Allocator, port: u16) !TestServer {
        const server = try ua.Server.init();
        return TestServer{
            .server = server,
            .running = std.atomic.Value(bool).init(false),
            .port = port,
            .allocator = allocator,
        };
    }

    /// Start the server in a background thread
    pub fn startAsync(self: *TestServer) !void {
        try self.server.start();
        self.running.store(true, .seq_cst);
        self.thread = try std.Thread.spawn(.{}, serverThread, .{self});

        // Give server time to start listening
        std.Thread.sleep(100 * std.time.ns_per_ms);
    }

    /// Start the server in blocking mode (for simple tests)
    pub fn startBlocking(self: *TestServer) !void {
        try self.server.start();
        self.running.store(true, .seq_cst);
    }

    /// Run one iteration of the server (for manual control)
    pub fn iterate(self: *TestServer, wait_internal: bool) u16 {
        return self.server.iterate(wait_internal);
    }

    /// Stop the server
    pub fn stop(self: *TestServer) !void {
        self.running.store(false, .seq_cst);
        if (self.thread) |thread| {
            thread.join();
            self.thread = null;
        }
        try self.server.stop();
    }

    /// Clean up server resources
    pub fn deinit(self: *TestServer) void {
        self.server.deinit();
    }

    /// Get the endpoint URL for this server (null-terminated for C interop)
    pub fn getEndpointUrl(self: *TestServer, buf: []u8) ![:0]const u8 {
        return std.fmt.bufPrintZ(buf, "opc.tcp://localhost:{d}", .{self.port});
    }

    fn serverThread(self: *TestServer) void {
        while (self.running.load(.seq_cst)) {
            _ = self.server.iterate(true);
        }
    }
};

/// Helper to create a client connected to a test server
pub fn createConnectedClient(endpoint_url: []const u8) !ua.Client {
    var client = try ua.Client.init();
    errdefer client.deinit();
    try client.connect(endpoint_url);
    return client;
}

/// Helper to wait for a condition with timeout
pub fn waitFor(
    comptime condition: fn () bool,
    timeout_ms: u64,
) !void {
    const start = std.time.milliTimestamp();
    while (!condition()) {
        const elapsed = std.time.milliTimestamp() - start;
        if (elapsed > timeout_ms) {
            return error.Timeout;
        }
        std.time.sleep(10 * std.time.ns_per_ms);
    }
}
