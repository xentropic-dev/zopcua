# Client Namespace Discovery Example

This example demonstrates how to dynamically discover namespace indices from an OPC UA server using the client namespace API. This is useful when connecting to servers with custom namespaces where the indices may vary.

## Features

- Dynamic namespace discovery using `Client.getNamespaceByName()`
- Constructing NodeIds with discovered namespace indices
- Reading variables from multiple custom namespaces
- Writing to variables in custom namespaces
- Error handling for missing namespaces

## Why Use Dynamic Discovery?

Instead of hardcoding namespace indices like:
```zig
const node_id = NodeId.initString(2, "temperature"); // What if index changes?
```

You can discover them dynamically:
```zig
const ns_idx = try client.getNamespaceByName("http://example.com/sensors");
const node_id = NodeId.initString(ns_idx, "temperature"); // Adapts to server config!
```

## Running

First, start the server-namespace example in another terminal:
```bash
cd ../server-namespace
zig build run
```

Then run this client:
```bash
zig build run
```

## Expected Output

```
info: Connecting to server at opc.tcp://localhost:4840...
info: Connected successfully!
info: OPC UA standard namespace index: 0
info: Sensors namespace index: 2
info: Actuators namespace index: 3

info: Reading variables from discovered namespaces...
info: Temperature (ns=2;s=temperature): 22.5°C
info: Humidity (ns=2;s=humidity): 65.0%
info: Valve (ns=3;s=valve): CLOSED

info: Toggling valve state...
info: Valve after toggle: OPEN

info: ✓ Successfully demonstrated dynamic namespace discovery!
```

## Key Concepts

### Namespace Discovery
```zig
const ns_idx = try client.getNamespaceByName("http://example.com/sensors");
```

### Error Handling
```zig
const ns_idx = client.getNamespaceByName("http://example.com/missing") catch |err| {
    std.log.warn("Namespace not found: {s}", .{@errorName(err)});
    return err;
};
```

### Using Discovered Indices
```zig
const node_id = NodeId.initString(ns_idx, "temperature");
const value = try client.readValueAttribute(allocator, node_id);
defer value.deinit(allocator);
```

## Notes

- Namespace indices can vary between server configurations
- Standard OPC UA namespace is always at index 0
- Server default namespace is typically at index 1
- Custom namespaces start at index 2
- Dynamic discovery makes your client code more portable
