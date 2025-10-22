# OPC UA Client Read Example

Demonstrates reading a variable value from an OPC UA server.

## What it does

Connects to a server and reads the value of "the answer" variable (ns=1;s=the.answer).

## Prerequisites

Start a server with the variable:

```bash
# Terminal 1: Start server with variables
cd ../server-simple
zig build run
```

## Building and running

```bash
# Terminal 2: Read the variable
cd client-read
zig build run
```

Output:
```
[info] Connecting to opc.tcp://localhost:4840...
[info] Reading node: ns=1;s=the.answer
[info] Value: 42
```

## Code walkthrough

```zig
// Create the NodeId for "the answer" variable
const node_id = ua.NodeId.initString(1, "the.answer");

// Read the value attribute
const value = try client.readValueAttribute(node_id, allocator);
defer value.deinit(allocator);

// The value is a Variant that can hold any OPC UA data type
std.log.info("Value: {}", .{value});
```

## NodeId types

You can create NodeIds in several ways:

```zig
// String identifier (namespace 1)
const node_id = ua.NodeId.initString(1, "the.answer");

// Numeric identifier (namespace 0)
const node_id = ua.NodeId.initNumeric(0, 2253);

// GUID identifier
const guid = ua.Guid{ ... };
const node_id = ua.NodeId.initGuid(1, guid);

// ByteString identifier
const node_id = ua.NodeId.initByteString(1, &[_]u8{1, 2, 3, 4});
```

## Error handling

The `readValueAttribute()` method returns specific errors:

- `ServerNotConnected` - Client not connected to server
- `NodeIdUnknown` - Node doesn't exist on the server
- `NotReadable` - Node doesn't allow read access
- `UserAccessDenied` - Permission denied
- And more (see src/client.zig for full list)

## Next steps

- See `client-write` to modify variable values
- Try reading different variables from `server-advanced`
- Modify the code to read different NodeIds
