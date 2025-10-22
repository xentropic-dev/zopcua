# Minimal OPC UA Server Example

The simplest possible OPC UA server - just 7 lines of code!

## What it does

Creates and starts an OPC UA server with default configuration. The server runs until interrupted (Ctrl-C).

## Building and running

```bash
zig build run
```

The server will start on `opc.tcp://localhost:4840` and display:
```
[info] OPC UA Server started on port 4840. Press Ctrl-C to stop.
```

## Code walkthrough

```zig
const ua = @import("ua");

pub fn main() !void {
    var server = try ua.Server.init();    // Create server with defaults
    defer server.deinit();                 // Clean up on exit

    try server.runUntilInterrupt();       // Run until Ctrl-C
}
```

The `runUntilInterrupt()` method:
- Starts the server automatically
- Handles the main event loop
- Sets up signal handlers for graceful shutdown
- Blocks until Ctrl-C is pressed

## Next steps

- See `server-simple` for adding variables to your server
- See `server-advanced` for manual control over the event loop
