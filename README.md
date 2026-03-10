<div align="center">
  <h1>🏭 zopcua</h1>
  <p>A Zig wrapper for <a href="https://github.com/open62541/open62541">open62541</a>, an open-source OPC UA implementation.</p>
  <p>
    <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-e0af68.svg?style=for-the-badge&logo=opensourceinitiative&logoColor=white" /></a>
    <a href="https://github.com/xentropic-dev/zopcua/actions"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/xentropic-dev/zopcua/ci.yml?style=for-the-badge&label=CI&logo=github&color=9ece6a" /></a>
    <a href="https://github.com/xentropic-dev/zopcua/stargazers"><img alt="GitHub Stars" src="https://img.shields.io/github/stars/xentropic-dev/zopcua?style=for-the-badge&color=7aa2f7&logo=github" /></a>
    <img alt="Zig 0.14" src="https://img.shields.io/badge/Zig-0.15.2-f7a41d.svg?style=for-the-badge&logo=zig&logoColor=white" />
  </p>
</div>

## ⚠️ Development Status

**This library is under active development and NOT ready for production use.**

**Feature Parity:** 28% complete (see [ROADMAP.md](docs/ROADMAP.md))

```
Progress: [█████░░░░░░░░░░░░░░░] 28%
```

- Requires Zig 0.15.2
- See branch/tag history for previous Zig versions
- APIs are unstable and subject to change

### Project Goals

This wrapper aims to make working with open62541 feel native to Zig by:

1. **Memory Safety** - Proper allocator usage, clear ownership semantics, no manual memory management
2. **Zig Idioms** - Error return types, tagged unions, comptime features instead of C conventions
3. **Type Safety** - Strongly-typed wrappers eliminating void pointers and C-style type erasure
4. **Abstraction** - Hide C complexities like bitfields, null-terminated strings, and manual struct initialization

This library will not reach full feature parity with open62541 for some time. If you need functionality that isn't yet wrapped, please open an issue!

## Features

### ✅ Currently Implemented

**Server:**
- Server lifecycle (init, start, stop, iterate, runUntilInterrupt)
- Variable nodes (add with full attribute control)
- Object nodes (add with attributes)
- Namespace management (add, lookup by name/index)
- Custom server configuration (port, security mode)

**Client:**
- Client lifecycle (init, connect, disconnect)
- Read operations (readValueAttribute)
- Write operations (writeValueAttribute)
- Browse operations (browse, browseNext with full control)
- Custom client configuration (timeout, security mode)

**Data Types:**
- NodeId (numeric, string, GUID, bytestring)
- Variant (scalars and arrays for all basic types)
- QualifiedName, LocalizedText, ExpandedNodeId
- VariableAttributes, ObjectAttributes
- Browse types and masks
- Comprehensive error types

### 🚧 Planned/In Progress

- Subscriptions & monitored items (high priority)
- Method calls (medium priority)
- Events & alarms (medium priority)
- Server-side read/write operations
- Client node management
- History access
- PubSub
- Security & certificates
- Discovery services

See [ROADMAP.md](docs/ROADMAP.md) for detailed progress tracking.

## Documentation

📚 **[View the full API documentation](https://xentropic-dev.github.io/zopcua/)**

**Guides:**
- [Examples Guide](docs/EXAMPLES.md) - Complete examples for common operations
- [Memory Policy](docs/MEMORY_POLICY.md) - Understanding memory management
- [Roadmap](docs/ROADMAP.md) - Feature parity tracking

## Installation

Add zopcua to your project:

```bash
zig fetch --save git+https://github.com/xentropic-dev/zopcua.git
```

Then in your `build.zig`:

```zig
const std = @import("std");
const zopcua = @import("zopcua");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "my-app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Add zopcua - automatically handles module import and platform-specific linking
    zopcua.setup(exe, .{});

    b.installArtifact(exe);
}
```

That's it! The `setup` function automatically:

- Adds the `ua` module to your executable
- Links required system libraries (ws2_32, advapi32, crypt32, bcrypt on Windows)
- Links required frameworks (Security, CoreFoundation on macOS)
- Handles all platform-specific configuration

### mbedTLS Dependency

zopcua requires mbedTLS for cryptographic operations and secure communication. **By default, mbedTLS is statically linked from vendored sources** - no system installation required.

If you prefer to use system-installed mbedTLS libraries instead:

```zig
zopcua.setup(exe, .{
    .mbedtls = .system,  // Use system mbedTLS instead of vendored
});
```

When using system mbedTLS, ensure the libraries are installed:

- **macOS**: `brew install mbedtls`
- **Ubuntu/Debian**: `sudo apt install libmbedtls-dev`
- **Other Linux**: Use your distribution's package manager

## Quick Start

### Minimal Server

```zig
const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var server = try ua.Server.init();
    defer server.deinit();

    try server.runUntilInterrupt(); // Blocks until Ctrl-C
}
```

### Server with Variable

```zig
const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var server = try ua.Server.init();
    defer server.deinit();

    _ = try server.addVariableNode(
        ua.NodeId.initString(1, "temperature"),
        ua.StandardNodeId.objects_folder,
        ua.ReferenceType.organizes,
        ua.QualifiedName.init(1, "Temperature"),
        ua.StandardNodeId.base_data_variable_type,
        .{
            .value = ua.Variant.scalar(f64, 23.5),
            .display_name = ua.LocalizedText.init("en-US", "Temperature"),
            .access_level = .{ .read = true, .write = true },
        },
    );

    try server.runUntilInterrupt();
}
```

### Client Reading Values

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

    const node_id = ua.NodeId.initString(1, "temperature");
    const variant = try client.readValueAttribute(allocator, node_id);
    defer variant.deinit(allocator);

    std.debug.print("Temperature: {d}\n", .{variant.double});
}
```

**See [docs/EXAMPLES.md](docs/EXAMPLES.md) for more examples including writing values, browsing, arrays, objects, namespaces, and error handling.**

## Building

```bash
# Build the library (uses vendored mbedTLS by default)
zig build

# Build with system mbedTLS
zig build -Dmbedtls=system

# Run tests
zig build test

# Generate documentation
zig build docs
```


## License

This wrapper library is licensed under the MIT License. See [LICENSE](LICENSE) for details.

The underlying open62541 library is licensed under the Mozilla Public License 2.0. See the [open62541 repository](https://github.com/open62541/open62541) for details.

## Contributing

Contributions are welcome! Here's how you can help:

1. **Check [ROADMAP.md](docs/ROADMAP.md)** to see what features need implementation
2. **Look for missing features** - The library is at 28% parity with open62541, lots to do!
3. **Submit PRs** with new features, bug fixes, or improved documentation
4. **Open issues** for features you need or bugs you encounter
5. **Add tests** for new functionality

### High Priority Areas

- Subscriptions & monitored items
- Method calls
- Server-side read/write operations
- Client node management
- Additional attribute operations

See the roadmap for a complete breakdown of missing features.
