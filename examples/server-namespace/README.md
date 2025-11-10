# Server Namespace Example

This example demonstrates how to use custom namespaces in an OPC UA server.

## Features

- Creating custom namespaces with `addNamespace()`
- Looking up namespace indices with `getNamespaceByName()`
- Organizing nodes in different namespaces
- Demonstrating best practices for namespace URIs

## Namespaces

The example creates two custom namespaces:

1. `http://example.com/sensors` (index 2) - For sensor data
2. `http://example.com/actuators` (index 3) - For control actuators

## Nodes

The server exposes the following nodes:

- `ns=2;s=temperature` - Temperature sensor (read-only, f64)
- `ns=2;s=humidity` - Humidity sensor (read-only, f64)
- `ns=3;s=valve` - Control valve (read/write, bool)

## Running

```bash
zig build -Dexample=server-namespace
./zig-out/bin/server-namespace
```

Connect with an OPC UA client (e.g., UaExpert) to:
- Browse the namespace structure
- Read sensor values
- Write to the valve actuator

## Notes

- Namespaces must be added before calling `server.start()`
- Namespace index 0 is reserved for the OPC UA standard namespace
- Namespace index 1 is the server's default namespace
- Custom namespaces start at index 2
