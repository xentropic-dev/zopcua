# Minimal OPC UA Client Example

The simplest possible OPC UA client - connects to a server and disconnects.

## What it does

Creates a client, connects to an OPC UA server, and cleanly disconnects.

## Prerequisites

You need a running OPC UA server. Start one of the server examples first:

```bash
# In one terminal
cd ../server-minimal
zig build run
```

## Building and running

```bash
# In another terminal
zig build run
```

Output:
```
[info] Connecting to opc.tcp://localhost:4840...
[info] Connected successfully!
```

## Code walkthrough

```zig
const ua = @import("ua");

pub fn main() !void {
    const client = try ua.Client.init();     // Create client
    defer client.deinit();                    // Clean up on exit

    const url = "opc.tcp://localhost:4840";
    try client.connect(url);                  // Connect to server
    defer client.disconnect() catch |err| {   // Always disconnect
        std.log.err("Failed to disconnect: {}", .{err});
    };

    // Client is now connected and ready for operations
}
```

## Connection lifecycle

1. **init()** - Creates the client instance
2. **connect(url)** - Establishes connection to server
3. *... do work ...*
4. **disconnect()** - Closes the connection
5. **deinit()** - Cleans up client resources

Always use `defer` to ensure cleanup happens even if errors occur.

## Next steps

- See `client-read` to read variable values
- See `client-write` to modify variables on the server
