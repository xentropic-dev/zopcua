# OPC UA Client Write Example

Demonstrates writing a new value to a variable on an OPC UA server.

## What it does

1. Connects to a server
2. Reads the current value of "the answer" variable
3. Writes a new value (provided as command line argument)
4. Reads it back to confirm the write succeeded

## Prerequisites

Start a server with writable variables:

```bash
# Terminal 1: Start server
cd ../server-simple
zig build run
```

## Building and running

```bash
# Terminal 2: Write a new value
cd client-write
zig build run -- 100
```

Output:
```
[info] Connecting to opc.tcp://localhost:4840...
[info] Reading current value of: ns=1;s=the.answer
[info] Current value: 42
[info] Writing new value: 100
[info] Confirmed value: 100
```

## Usage

```bash
zig build run -- <new-value>
```

### Examples

```bash
# Change "the answer" from 42 to 100
zig build run -- 100

# Set it to 999
zig build run -- 999

# Set it back to 42
zig build run -- 42
```

## Code walkthrough

```zig
// Parse the new value from command line
const new_value_int = try std.fmt.parseInt(i32, args[1], 10);

// Read current value
const current_value = try client.readValueAttribute(node_id, allocator);
defer current_value.deinit(allocator);

// Create a new Variant with the value
const new_value = ua.Variant.scalar(i32, new_value_int);

// Write it to the server
try client.writeValueAttribute(node_id, new_value);

// Read back to confirm
const confirmed_value = try client.readValueAttribute(node_id, allocator);
```

## Creating Variants

Variants are type-safe containers for OPC UA values:

```zig
// Integer types
ua.Variant.scalar(i32, 42);
ua.Variant.scalar(u8, 255);

// Floating point
ua.Variant.scalar(f64, 23.5);

// Boolean
ua.Variant.scalar(bool, true);

// String
ua.Variant.scalar([]const u8, "hello");

// Arrays
const values = [_]f64{ 1.0, 2.0, 3.0 };
ua.Variant.array(f64, &values);
```

## Error handling

The `writeValueAttribute()` method returns specific errors:

- `NotWritable` - Node doesn't allow write access
- `TypeMismatch` - Value type doesn't match node's declared type
- `UserAccessDenied` - Permission denied
- `OutOfRange` - Value outside allowed range
- And more (see src/client.zig for full list)

## Notes

- Only variables with `.write = true` access level can be written
- The server may reject writes based on security policies or value constraints
- Some servers require authentication for write operations

## Next steps

- Try writing to read-only variables to see the error handling
- Modify the code to write different data types
- Add validation before writing
