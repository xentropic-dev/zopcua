# Examples Guide

This guide provides detailed examples for common OPC UA operations using zopcua.

## Quick Start Examples

### Minimal Server

The simplest possible OPC UA server:

```zig
const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var server = try ua.Server.init();
    defer server.deinit();

    try server.runUntilInterrupt(); // Blocks until Ctrl-C
}
```

This creates a server with default configuration on port 4840. Press Ctrl-C to stop.

### Minimal Client

The simplest possible OPC UA client:

```zig
const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var client = try ua.Client.init();
    defer client.deinit();

    try client.connect("opc.tcp://localhost:4840");
    defer client.disconnect() catch {};

    std.debug.print("Connected successfully!\n", .{});
}
```

## Server Examples

### Adding Variables

Create a server with a temperature variable:

```zig
const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var server = try ua.Server.init();
    defer server.deinit();

    // Add a temperature variable
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "temperature"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Temperature"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(f64, 23.5),
            .display_name = ua.LocalizedText.init("en-US", "Temperature"),
            .description = ua.LocalizedText.initText("Current temperature in Celsius"),
            .access_level = .{ .read = true, .write = true },
        },
    );

    try server.runUntilInterrupt();
}
```

### Adding Array Variables

Create a variable holding an array of values:

```zig
const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var server = try ua.Server.init();
    defer server.deinit();

    // Array of measurements
    const measurements = [_]f64{ 10.1, 20.2, 30.3, 40.4, 50.5 };
    const array_dims = [_]u32{5};

    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "measurements"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Measurements"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.array(f64, &measurements),
            .display_name = ua.LocalizedText.init("en-US", "Measurements"),
            .access_level = .{ .read = true },
            .value_rank = 1, // One-dimensional array
            .array_dimensions = &array_dims,
        },
    );

    try server.runUntilInterrupt();
}
```

### Creating Object Hierarchies

Organize nodes using object folders:

```zig
const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var server = try ua.Server.init();
    defer server.deinit();

    // Create a "Sensors" folder
    const sensors_folder = try server.addObjectNode(
        ua.NodeId.initString(1, "sensors"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Sensors"),
        ua.StandardNodeId.folder_type,
        .{
            .display_name = ua.LocalizedText.init("en-US", "Sensors"),
            .description = ua.LocalizedText.initText("Folder containing all sensor nodes"),
        },
    );

    // Add temperature variable under the sensors folder
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "temperature"),
        sensors_folder, // parent is the sensors folder
        ua.ReferenceType.has_component,
        ua.QualifiedName.init(1, "Temperature"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(f64, 23.5),
            .display_name = ua.LocalizedText.init("en-US", "Temperature"),
            .access_level = .{ .read = true },
        },
    );

    // Add pressure variable under the sensors folder
    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "pressure"),
        sensors_folder,
        ua.ReferenceType.has_component,
        ua.QualifiedName.init(1, "Pressure"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(f64, 101.3),
            .display_name = ua.LocalizedText.init("en-US", "Pressure"),
            .access_level = .{ .read = true },
        },
    );

    try server.runUntilInterrupt();
}
```

### Using Custom Namespaces

Create and use custom namespaces for your nodes:

```zig
const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var server = try ua.Server.init();
    defer server.deinit();

    // Add custom namespace before starting server
    const ns_idx = try server.addNamespace("http://example.com/myapp");
    std.debug.print("Created namespace with index: {d}\n", .{ns_idx});

    // Use the custom namespace for our nodes
    _ = try server.addVariableNode(
        ua.NodeId.initString(ns_idx, "temperature"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(ns_idx, "Temperature"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(f64, 23.5),
            .display_name = ua.LocalizedText.init("en-US", "Temperature"),
            .access_level = .{ .read = true, .write = true },
        },
    );

    // Look up namespace by name
    const found_idx = try server.getNamespaceByName("http://example.com/myapp");
    std.debug.print("Found namespace at index: {d}\n", .{found_idx});

    try server.runUntilInterrupt();
}
```

### Custom Server Configuration

Configure server port, security, and other options:

```zig
const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var server = try ua.Server.initWithConfig(.{
        .port = 8080,
        .security_mode = .none,
    });
    defer server.deinit();

    std.debug.print("Server running on port 8080\n", .{});

    try server.runUntilInterrupt();
}
```

### Manual Server Lifecycle Control

Fine-grained control over server lifecycle:

```zig
const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var server = try ua.Server.init();
    defer server.deinit();

    // Add some nodes here...

    try server.start();
    std.debug.print("Server started\n", .{});

    var running = true;
    var iterations: usize = 0;
    while (running) {
        _ = server.iterate(true);
        iterations += 1;

        // Stop after 100 iterations (for demonstration)
        if (iterations >= 100) {
            running = false;
        }
    }

    try server.stop();
    std.debug.print("Server stopped after {d} iterations\n", .{iterations});
}
```

## Client Examples

### Reading Values

Connect to a server and read a variable value:

```zig
const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try ua.Client.init();
    defer client.deinit();

    try client.connect("opc.tcp://localhost:4840");
    defer client.disconnect() catch {};

    // Read a value
    const node_id = ua.NodeId.initString(1, "temperature");
    const variant = try client.readValueAttribute(allocator, node_id);
    defer variant.deinit(allocator);

    // Handle different value types
    switch (variant) {
        .double => |value| std.debug.print("Temperature: {d}°C\n", .{value}),
        .float => |value| std.debug.print("Temperature: {d}°C\n", .{value}),
        .int32 => |value| std.debug.print("Temperature: {d}°C\n", .{value}),
        else => std.debug.print("Unexpected type: {s}\n", .{@tagName(variant)}),
    }
}
```

### Writing Values

Connect to a server and write a new value:

```zig
const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var client = try ua.Client.init();
    defer client.deinit();

    try client.connect("opc.tcp://localhost:4840");
    defer client.disconnect() catch {};

    // Write a new value
    const node_id = ua.NodeId.initString(1, "temperature");
    const new_value = ua.Variant.scalar(f64, 25.5);

    try client.writeValueAttribute(node_id, new_value);
    std.debug.print("Successfully wrote value\n", .{});
}
```

### Browsing the Address Space

Discover nodes in the server's address space:

```zig
const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try ua.Client.init();
    defer client.deinit();

    try client.connect("opc.tcp://localhost:4840");
    defer client.disconnect() catch {};

    // Browse the Objects folder
    const result = try client.browse(allocator, ua.StandardNodeId.objects_folder);
    defer result.deinit(allocator);

    std.debug.print("Found {d} references:\n", .{result.references.len});
    for (result.references) |ref| {
        std.debug.print("  - {s} (NodeClass: {s})\n", .{
            ref.browse_name.name,
            @tagName(ref.node_class),
        });
    }
}
```

### Advanced Browsing

Browse with custom parameters and filters:

```zig
const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try ua.Client.init();
    defer client.deinit();

    try client.connect("opc.tcp://localhost:4840");
    defer client.disconnect() catch {};

    // Browse with custom description
    const desc = ua.BrowseDescription{
        .node_id = ua.StandardNodeId.objects_folder,
        .browse_direction = .forward,
        .reference_type_id = ua.ReferenceType.organizes,
        .include_subtypes = true,
        .node_class_mask = ua.NodeClassMask.objects_only,
        .result_mask = ua.BrowseResultMask.all,
    };

    var result = try client.browseWithDescription(allocator, desc, 0);
    defer result.deinit(allocator);

    std.debug.print("Found {d} object nodes:\n", .{result.references.len});
    for (result.references) |ref| {
        std.debug.print("  - {s}\n", .{ref.browse_name.name});
    }

    // Handle continuation point if more results available
    while (result.continuation_point) |cp| {
        const next = try client.browseNext(allocator, cp);
        result.deinit(allocator);
        result = next;

        std.debug.print("Next batch: {d} nodes\n", .{result.references.len});
    }
}
```

### Custom Client Configuration

Configure client timeouts and other options:

```zig
const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var client = try ua.Client.initWithConfig(.{
        .timeout = 10000, // 10 second timeout
        .security_mode = .none,
    });
    defer client.deinit();

    try client.connect("opc.tcp://localhost:4840");
    defer client.disconnect() catch {};

    std.debug.print("Connected with custom config\n", .{});
}
```

## Combined Client-Server Example

Run a client and server in the same application:

```zig
const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Start server
    var server = try ua.Server.init();
    defer server.deinit();

    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "counter"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Counter"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(i32, 0),
            .display_name = ua.LocalizedText.init("en-US", "Counter"),
            .access_level = .{ .read = true, .write = true },
        },
    );

    try server.start();
    defer server.stop() catch {};

    // Give server time to start
    std.time.sleep(100 * std.time.ns_per_ms);

    // Connect client
    var client = try ua.Client.init();
    defer client.deinit();

    try client.connect("opc.tcp://localhost:4840");
    defer client.disconnect() catch {};

    // Interact with server
    const node_id = ua.NodeId.initString(1, "counter");

    // Read initial value
    var value = try client.readValueAttribute(allocator, node_id);
    defer value.deinit(allocator);
    std.debug.print("Initial value: {d}\n", .{value.int32});

    // Write new value
    try client.writeValueAttribute(node_id, ua.Variant.scalar(i32, 42));

    // Read updated value
    value.deinit(allocator);
    value = try client.readValueAttribute(allocator, node_id);
    std.debug.print("Updated value: {d}\n", .{value.int32});
}
```

## Working with Different Data Types

### Numeric Types

```zig
// Integers
_ = try server.addVariableNode(
    ua.NodeId.initNumeric(1, 1000),
    ua.StandardNodeId.objects_folder,
    ua.ReferenceType.organizes,
    ua.QualifiedName.init(1, "Int32Var"),
    ua.StandardNodeId.base_data_variable_type,
    .{ .value = ua.Variant.scalar(i32, 42) },
);

// Unsigned integers
_ = try server.addVariableNode(
    ua.NodeId.initNumeric(1, 1001),
    ua.StandardNodeId.objects_folder,
    ua.ReferenceType.organizes,
    ua.QualifiedName.init(1, "UInt32Var"),
    ua.StandardNodeId.base_data_variable_type,
    .{ .value = ua.Variant.scalar(u32, 42) },
);

// Floating point
_ = try server.addVariableNode(
    ua.NodeId.initNumeric(1, 1002),
    ua.StandardNodeId.objects_folder,
    ua.ReferenceType.organizes,
    ua.QualifiedName.init(1, "DoubleVar"),
    ua.StandardNodeId.base_data_variable_type,
    .{ .value = ua.Variant.scalar(f64, 3.14159) },
);
```

### String Types

```zig
_ = try server.addVariableNode(
    ua.NodeId.initString(1, "message"),
    ua.StandardNodeId.objects_folder,
    ua.ReferenceType.organizes,
    ua.QualifiedName.init(1, "Message"),
    ua.StandardNodeId.base_data_variable_type,
    .{
        .value = ua.Variant.scalar([]const u8, "Hello, OPC UA!"),
        .display_name = ua.LocalizedText.init("en-US", "Message"),
    },
);
```

### Boolean Types

```zig
_ = try server.addVariableNode(
    ua.NodeId.initString(1, "is_active"),
    ua.StandardNodeId.objects_folder,
    ua.ReferenceType.organizes,
    ua.QualifiedName.init(1, "IsActive"),
    ua.StandardNodeId.base_data_variable_type,
    .{ .value = ua.Variant.scalar(bool, true) },
);
```

### Array Types

```zig
const temps = [_]f64{ 20.5, 21.2, 22.1, 21.8, 20.9 };
const dims = [_]u32{5};

_ = try server.addVariableNode(
    ua.NodeId.initString(1, "temperatures"),
    ua.StandardNodeId.objects_folder,
    ua.ReferenceType.organizes,
    ua.QualifiedName.init(1, "Temperatures"),
    ua.StandardNodeId.base_data_variable_type,
    .{
        .value = ua.Variant.array(f64, &temps),
        .value_rank = 1,
        .array_dimensions = &dims,
    },
);
```

## Error Handling

### Proper Error Handling

```zig
const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try ua.Client.init();
    defer client.deinit();

    // Connection errors
    client.connect("opc.tcp://invalid-server:4840") catch |err| {
        std.debug.print("Connection failed: {s}\n", .{@errorName(err)});
        return;
    };
    defer client.disconnect() catch {};

    // Read errors
    const node_id = ua.NodeId.initString(1, "nonexistent");
    const value = client.readValueAttribute(allocator, node_id) catch |err| {
        switch (err) {
            error.NodeIdUnknown => std.debug.print("Node not found\n", .{}),
            error.NotReadable => std.debug.print("Node not readable\n", .{}),
            error.UserAccessDenied => std.debug.print("Access denied\n", .{}),
            else => std.debug.print("Read error: {s}\n", .{@errorName(err)}),
        }
        return;
    };
    defer value.deinit(allocator);
}
```

## Memory Management

See [MEMORY_POLICY.md](MEMORY_POLICY.md) for detailed information about memory management in zopcua.

Key points:
- Server and Client use C allocator internally (managed by open62541)
- Variants returned from read operations must be freed with `variant.deinit(allocator)`
- Browse results must be freed with `result.deinit(allocator)`
- Use arena allocators for temporary allocations in tight loops

## Complete Examples

The [examples/](../examples/) directory contains complete, runnable examples:

**Server Examples:**
- `server-minimal` - Bare minimum server
- `server-simple` - Server with a simple variable
- `server-namespace` - Custom namespace management
- `server-object-nesting` - Hierarchical object organization
- `server-advanced` - Complex server with multiple nodes
- `server-custom-config` - Custom server configuration

**Client Examples:**
- `client-minimal` - Basic client connection
- `client-read` - Reading values from a server
- `client-write` - Writing values to a server
- `client-custom-config` - Custom client configuration
- `client-server` - Combined client-server example

Build and run any example:
```bash
cd examples/server-simple
zig build run
```
