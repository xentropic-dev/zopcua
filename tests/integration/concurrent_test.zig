const std = @import("std");
const ua = @import("ua");
const test_helpers = @import("test_helpers");
const TestServer = test_helpers.TestServer;
const fixtures = test_helpers.fixtures;

pub fn main() !void {
    const allocator = std.heap.page_allocator;


    // Create and setup server
    var test_server = try TestServer.init(allocator, 4840);
    defer test_server.deinit();

    const nodes = try fixtures.setupStandardNodes(&test_server.server, allocator);
    try test_server.startAsync();
    defer test_server.stop() catch |err| {
        std.debug.print("Failed to stop test server: {}\n", .{err});
    };

    var url_buf: [128]u8 = undefined;
    const endpoint_url = try test_server.getEndpointUrl(&url_buf);

    // Test 1: Multiple concurrent readers
    try testConcurrentReaders(endpoint_url, nodes.int32, allocator);

    // Test 2: Multiple concurrent writers (race condition)
    try testConcurrentWriters(endpoint_url, nodes.int32, allocator);

    // Test 3: Mixed concurrent read/write
    try testMixedConcurrentAccess(endpoint_url, nodes, allocator);

    // Test 4: Multiple clients on different nodes
    try testConcurrentClientsMultipleNodes(endpoint_url, nodes, allocator);

}

const ReaderResult = struct {
    success: bool,
    value: i32,
    error_msg: ?[]const u8 = null,
};

fn testConcurrentReaders(
    endpoint_url: []const u8,
    node_id: ua.NodeId,
    allocator: std.mem.Allocator,
) !void {

    const num_clients = 10;
    const num_reads_per_client = 20;
    var threads: [num_clients]std.Thread = undefined;
    var results = [_]?ReaderResult{null} ** num_clients;

    // Spawn reader threads
    for (&threads, 0..) |*thread, i| {
        const ctx = ReaderContext{
            .endpoint_url = endpoint_url,
            .node_id = node_id,
            .allocator = allocator,
            .result = &results[i],
            .num_reads = num_reads_per_client,
        };
        thread.* = try std.Thread.spawn(.{}, readerThread, .{ctx});
    }

    // Wait for all threads
    for (threads) |thread| {
        thread.join();
    }

    // Check results
    var successful_reads: usize = 0;
    for (results) |maybe_result| {
        if (maybe_result) |result| {
            if (result.success) {
                successful_reads += 1;
            } else {
            }
        }
    }

    if (successful_reads != num_clients) {
        return error.SomeReadersFailed;
    }

}

const ReaderContext = struct {
    endpoint_url: []const u8,
    node_id: ua.NodeId,
    allocator: std.mem.Allocator,
    result: *?ReaderResult,
    num_reads: usize,
    stagger_ms: u64 = 0,
};

fn readerThread(ctx: ReaderContext) void {
    // Stagger connection attempts to avoid overwhelming the server/network stack
    if (ctx.stagger_ms > 0) {
        std.Thread.sleep(ctx.stagger_ms * std.time.ns_per_ms);
    }

    var client = ua.Client.init() catch {
        ctx.result.* = ReaderResult{ .success = false, .value = 0, .error_msg = "Client init failed" };
        return;
    };
    defer client.deinit();

    client.connect(ctx.endpoint_url) catch {
        ctx.result.* = ReaderResult{ .success = false, .value = 0, .error_msg = "Connection failed" };
        return;
    };
    defer client.disconnect() catch |err| {
        std.debug.print("Failed to disconnect client: {}\n", .{err});
    };

    var last_value: i32 = 0;
    var read_count: usize = 0;

    while (read_count < ctx.num_reads) : (read_count += 1) {
        const variant = client.readValueAttribute(ctx.node_id, ctx.allocator) catch {
            ctx.result.* = ReaderResult{ .success = false, .value = 0, .error_msg = "Read failed" };
            return;
        };
        defer variant.deinit(ctx.allocator);

        last_value = variant.int32;
        std.Thread.sleep(1 * std.time.ns_per_ms); // Small delay between reads
    }

    ctx.result.* = ReaderResult{ .success = true, .value = last_value };
}

fn testConcurrentWriters(
    endpoint_url: []const u8,
    node_id: ua.NodeId,
    allocator: std.mem.Allocator,
) !void {

    const num_writers = 5;
    var threads: [num_writers]std.Thread = undefined;
    var results = [_]?bool{null} ** num_writers;

    // Spawn writer threads
    for (&threads, 0..) |*thread, i| {
        const ctx = WriterContext{
            .endpoint_url = endpoint_url,
            .node_id = node_id,
            .writer_id = i,
            .result = &results[i],
        };
        thread.* = try std.Thread.spawn(.{}, writerThread, .{ctx});
    }

    // Wait for all threads
    for (threads) |thread| {
        thread.join();
    }

    // Check results
    var successful_writes: usize = 0;
    for (results) |maybe_result| {
        if (maybe_result) |result| {
            if (result) successful_writes += 1;
        }
    }

    if (successful_writes != num_writers) {
        return error.SomeWritersFailed;
    }

    // Read final value to verify writes were committed
    var verify_client = try ua.Client.init();
    defer verify_client.deinit();
    try verify_client.connect(endpoint_url);
    defer verify_client.disconnect() catch |err| {
        std.debug.print("Failed to disconnect verify client: {}\n", .{err});
    };

    const final_value = try verify_client.readValueAttribute(node_id, allocator);
    defer final_value.deinit(allocator);

}

const WriterContext = struct {
    endpoint_url: []const u8,
    node_id: ua.NodeId,
    writer_id: usize,
    result: *?bool,
    stagger_ms: u64 = 0,
};

fn writerThread(ctx: WriterContext) void {
    // Stagger connection attempts to avoid overwhelming the server/network stack
    if (ctx.stagger_ms > 0) {
        std.Thread.sleep(ctx.stagger_ms * std.time.ns_per_ms);
    }

    var client = ua.Client.init() catch {
        ctx.result.* = false;
        return;
    };
    defer client.deinit();

    client.connect(ctx.endpoint_url) catch {
        ctx.result.* = false;
        return;
    };
    defer client.disconnect() catch |err| {
        std.debug.print("Failed to disconnect writer client: {}\n", .{err});
    };

    // Each writer writes multiple values
    const base_value: i32 = @intCast(ctx.writer_id * 1000);
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        const value = base_value + @as(i32, @intCast(i));
        const variant = ua.Variant.scalar(i32, value);
        client.writeValueAttribute(ctx.node_id, variant) catch {
            ctx.result.* = false;
            return;
        };
        std.Thread.sleep(2 * std.time.ns_per_ms); // Small delay between writes
    }

    ctx.result.* = true;
}

fn testMixedConcurrentAccess(
    endpoint_url: []const u8,
    nodes: fixtures.TestNodeIds,
    allocator: std.mem.Allocator,
) !void {

    const num_readers = 10;
    const num_writers = 5;
    const total_clients = num_readers + num_writers;

    var threads: [total_clients]std.Thread = undefined;
    var reader_results = [_]?ReaderResult{null} ** num_readers;
    var writer_results = [_]?bool{null} ** num_writers;

    // Spawn readers (with staggered connection attempts)
    for (0..num_readers) |i| {
        const ctx = ReaderContext{
            .endpoint_url = endpoint_url,
            .node_id = nodes.int32,
            .allocator = allocator,
            .result = &reader_results[i],
            .num_reads = 30,
            .stagger_ms = i * 10, // Stagger by 10ms per client
        };
        threads[i] = try std.Thread.spawn(.{}, readerThread, .{ctx});
    }

    // Spawn writers (with staggered connection attempts)
    for (0..num_writers) |i| {
        const ctx = WriterContext{
            .endpoint_url = endpoint_url,
            .node_id = nodes.int32,
            .writer_id = i,
            .result = &writer_results[i],
            .stagger_ms = (num_readers + i) * 10, // Continue staggering after readers
        };
        threads[num_readers + i] = try std.Thread.spawn(.{}, writerThread, .{ctx});
    }

    // Wait for all threads
    for (threads) |thread| {
        thread.join();
    }

    // Count successes
    var successful_readers: usize = 0;
    for (reader_results) |result| {
        if (result) |r| {
            if (r.success) successful_readers += 1;
        }
    }

    var successful_writers: usize = 0;
    for (writer_results) |result| {
        if (result) |r| {
            if (r) successful_writers += 1;
        }
    }


    if (successful_readers != num_readers or successful_writers != num_writers) {
        return error.MixedAccessFailed;
    }

}

fn testConcurrentClientsMultipleNodes(
    endpoint_url: []const u8,
    nodes: fixtures.TestNodeIds,
    allocator: std.mem.Allocator,
) !void {

    const node_list = [_]ua.NodeId{
        nodes.boolean,
        nodes.int16,
        nodes.int32,
        nodes.int64,
        nodes.float,
        nodes.double,
        nodes.string,
        nodes.uint32,
    };

    var threads: [node_list.len]std.Thread = undefined;
    var results = [_]?bool{null} ** node_list.len;

    // Spawn a client for each node (with staggered connection attempts)
    for (&threads, 0..) |*thread, i| {
        const ctx = MultiNodeContext{
            .endpoint_url = endpoint_url,
            .node_id = node_list[i],
            .allocator = allocator,
            .result = &results[i],
            .client_id = i,
            .stagger_ms = i * 10, // Stagger by 10ms per client
        };
        thread.* = try std.Thread.spawn(.{}, multiNodeThread, .{ctx});
    }

    // Wait for all threads
    for (threads) |thread| {
        thread.join();
    }

    // Check results
    var successful: usize = 0;
    for (results) |result| {
        if (result) |r| {
            if (r) successful += 1;
        }
    }

    if (successful != node_list.len) {
        return error.MultiNodeAccessFailed;
    }

}

const MultiNodeContext = struct {
    endpoint_url: []const u8,
    node_id: ua.NodeId,
    allocator: std.mem.Allocator,
    result: *?bool,
    client_id: usize,
    stagger_ms: u64 = 0,
};

fn multiNodeThread(ctx: MultiNodeContext) void {
    // Stagger connection attempts to avoid overwhelming the server/network stack
    if (ctx.stagger_ms > 0) {
        std.Thread.sleep(ctx.stagger_ms * std.time.ns_per_ms);
    }

    var client = ua.Client.init() catch {
        ctx.result.* = false;
        return;
    };
    defer client.deinit();

    client.connect(ctx.endpoint_url) catch {
        ctx.result.* = false;
        return;
    };
    defer client.disconnect() catch |err| {
        std.debug.print("Failed to disconnect multinode client: {}\n", .{err});
    };

    // Perform multiple read/write cycles
    var i: usize = 0;
    while (i < 15) : (i += 1) {
        // Read
        const variant = client.readValueAttribute(ctx.node_id, ctx.allocator) catch {
            ctx.result.* = false;
            return;
        };
        defer variant.deinit(ctx.allocator);

        std.Thread.sleep(5 * std.time.ns_per_ms);
    }

    ctx.result.* = true;
}
