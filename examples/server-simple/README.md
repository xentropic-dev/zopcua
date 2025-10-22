# Simple OPC UA Server Example

A minimal server that demonstrates adding a single variable.

## What it does

Creates an OPC UA server and adds one writable integer variable called "the answer" with a value of 42.

## Building and running

```bash
zig build run
```

The server will start and display:
```
[info] Server starting on opc.tcp://localhost:4840
[info] Variable 'the answer' = 42 (NodeId: ns=1;s=the.answer)
```

## Testing with a client

You can connect with any OPC UA client (like UaExpert) or use the client examples:

```bash
# In another terminal, from the client-read example:
zig build run -- opc.tcp://localhost:4840 "ns=1;s=the.answer"
```

## Code walkthrough

```zig
// Add a variable to the Objects folder
_ = try server.addVariableNode(
    ua.NodeId.initString(1, "the.answer"),       // NodeId: ns=1;s=the.answer
    ua.StandardNodeId.objects_folder,             // Parent: Objects folder
    ua.ReferenceType.organizes,                   // Reference type
    ua.QualifiedName.init(1, "the answer"),       // Browse name
    ua.StandardNodeId.base_data_variable_type,    // Type definition
    .{
        .value = ua.Variant.scalar(i32, 42),      // Initial value
        .display_name = ua.LocalizedText.init("en-US", "The Answer"),
        .description = ua.LocalizedText.init("en-US", "The answer to life..."),
        .access_level = .{ .read = true, .write = true },  // Read/write access
    },
    allocator,
);
```

## Key concepts

- **NodeId**: Unique identifier for the variable (namespace 1, string "the.answer")
- **Parent node**: Where the variable appears in the address space (Objects folder)
- **Variant**: Type-safe container for the variable's value
- **Access level**: Controls read/write permissions

## Next steps

- See `client-write` to modify this variable from a client
- See `server-advanced` for multiple variables and custom event loops
