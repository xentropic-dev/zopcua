# Advanced OPC UA Server Example

Demonstrates manual control of the server event loop with custom signal handling.

## What it does

Creates an OPC UA server with:
- Multiple variables of different types (integers, floats, strings, booleans, arrays)
- Custom signal handlers for graceful shutdown
- Manual control of the event loop using `start()` and `iterate()`

This approach gives you full control over when the server processes events, allowing you to:
- Update variable values in your own loop
- Integrate with other event loops or frameworks
- Add custom periodic tasks between iterations

## Building and running

```bash
zig build run
```

The server will display:
```
[info] Successfully created 8 demo variables
[info] OPC UA Server started on port 4840. Press Ctrl-C to stop.
[info] Browse to 'Objects' folder to see all demo variables
```

## Available variables

All variables are in the Objects folder with namespace 1:

| Variable | NodeId | Type | Access | Value |
|----------|--------|------|--------|-------|
| The Answer | `ns=1;s=the.answer` | i32 | R/W | 42 |
| Temperature | `ns=1;s=temperature` | f64 | R | 23.5 |
| Status | `ns=1;s=status` | string | R | "Running" |
| Enabled | `ns=1;s=enabled` | bool | R/W | true |
| Measurements | `ns=1;s=measurements` | f64[] | R | [10.1, 20.2, ...] |
| Counter | `ns=1;s=counter` | u32 | R/W | 0 |
| Pressure | `ns=1;s=pressure` | f32 | R | 101.325 |
| Byte Value | `ns=1;s=byte_value` | u8 | R/W | 255 |

## Code walkthrough

### Manual event loop

Instead of `runUntilInterrupt()`, this example uses manual control:

```zig
// Custom signal handler
var running = std.atomic.Value(bool).init(true);

fn handleSignal(sig: c_int) callconv(.C) void {
    _ = sig;
    running.store(false, .seq_cst);
}

// Install signal handlers
const act = std.posix.Sigaction{
    .handler = .{ .handler = handleSignal },
    .mask = std.posix.empty_sigset,
    .flags = 0,
};
std.posix.sigaction(std.posix.SIG.INT, &act, null);
std.posix.sigaction(std.posix.SIG.TERM, &act, null);

// Manual control
try server.start();
defer server.stop() catch |err| {
    std.log.err("Failed to stop server: {}", .{err});
};

// Your custom loop
while (running.load(.seq_cst)) {
    _ = server.iterate(true);  // Process events

    // You could update variables here:
    // try server.writeVariable(...);
}
```

### Why manual control?

Use this pattern when you need to:
1. **Update variables** - Modify values between iterations (e.g., read sensors)
2. **Integrate with other systems** - Combine with your own event loops
3. **Add custom logic** - Execute periodic tasks alongside OPC UA processing
4. **Fine-grained control** - Manage startup/shutdown sequences precisely

## When to use runUntilInterrupt() instead

If you just need a server that runs until stopped, use the simpler `runUntilInterrupt()` method shown in `server-minimal` and `server-simple`. It handles all the signal setup and loop management for you.

## Next steps

- Modify the loop to update variable values dynamically
- Add your own custom variables with `addVariableNode()`
- See the client examples to interact with these variables
