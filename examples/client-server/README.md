# OPC UA Client and Server Combined Example

Demonstrates running both a client and server in the same process, with the client performing operations on the server.

## What it does

1. Starts an OPC UA server in a background thread with a "counter" variable
2. Runs client operations in the main thread:
   - Connects to the local server
   - Reads the initial counter value (0)
   - Writes new values (1, then 2)
   - Reads the counter after each write to confirm
3. Leaves the server running until you press Ctrl-C

## Building and running

```bash
zig build run
```

Output:
```
[info] Server started on opc.tcp://localhost:4840

[info] === Client Operations ===
[info] Connecting to opc.tcp://localhost:4840...

[info] 1. Reading initial counter value...
[info]    Counter = 0

[info] 2. Incrementing counter...
[info]    Written new value: 1

[info] 3. Reading updated counter value...
[info]    Counter = 1

[info] 4. Incrementing counter again...
[info]    Written new value: 2

[info] 5. Reading final counter value...
[info]    Counter = 2

[info] === Client operations completed successfully! ===

[info] Press Ctrl-C to stop the server
```

## Code walkthrough

### Server thread

The server runs in a background thread:

```zig
fn serverThread(allocator: std.mem.Allocator) !void {
    var server = try ua.Server.init();
    defer server.deinit();

    // Add a writable counter variable
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "counter"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Counter"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(i32, 0),
            .access_level = .{ .read = true, .write = true },
            // ... other attributes
        },
        allocator,
    );

    try server.runUntilInterrupt();
}
```

### Client operations

The client runs in the main thread after a brief delay:

```zig
// Give server time to start
std.time.sleep(500 * std.time.ns_per_ms);

// Connect to local server
const client = try ua.Client.init();
try client.connect("opc.tcp://localhost:4840");

// Read, write, read, write, read...
const node_id = ua.NodeId.initString(1, "counter");
const value = try client.readValueAttribute(node_id, allocator);
try client.writeValueAttribute(node_id, ua.Variant.scalar(i32, 1));
```

## Use cases

This pattern is useful for:

1. **Integration testing** - Test client and server together in one process
2. **Demos and examples** - Show complete workflows without multiple terminals
3. **Embedded applications** - Single process that exposes OPC UA and consumes it
4. **Development** - Quickly iterate on both client and server code

## Threading considerations

- The server runs in a background thread using `std.Thread.spawn()`
- The main thread runs the client operations
- Both threads share the same allocator (GPA in this case)
- The server's `runUntilInterrupt()` will block its thread until Ctrl-C
- The main thread waits forever after client operations complete

## Limitations

- Only works with a single client connection in this simple example
- The server thread will terminate when you press Ctrl-C
- No synchronization beyond the initial startup delay

## Variations

You could modify this to:

```zig
// Multiple client operations in a loop
for (0..10) |i| {
    const val = try client.readValueAttribute(node_id, allocator);
    std.log.info("Iteration {}: {}", .{i, val});
    std.time.sleep(1000 * std.time.ns_per_ms);
}

// Use atomic shutdown flag instead of runUntilInterrupt()
// (see server-advanced for manual loop control)

// Spawn multiple client threads
// (would need proper synchronization)
```

## Next steps

- Modify to use manual server loop (see `server-advanced`)
- Add more variables and complex operations
- Implement graceful shutdown with atomic flags
- Add error handling and retry logic for client operations
