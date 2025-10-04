# 🏭 zopcua

A Zig wrapper for [open62541](https://github.com/open62541/open62541), an open-source OPC UA implementation.

## ⚠️ Development Status

**This library is under active development and NOT ready for production use.**

- Requires Zig 0.14
- APIs are unstable and subject to change
- Limited feature coverage of the underlying open62541 library

### Project Goals

This wrapper aims to make working with open62541 feel native to Zig by:

1. **Adopting Zig idioms** - Using error return types, tagged unions, and other Zig patterns instead of C conventions
2. **Abstracting C complexities** - open62541 uses bitfields extensively in some structs, requiring C wrapper functions for safe access

This library will not reach full feature parity with open62541 for some time. If you need functionality that isn't yet wrapped, please open an issue!

## Documentation

📚 **[View the full API documentation](https://xentropic-dev.github.io/zopcua/)**

## Installation

Add zopcua to your project:

```bash
zig fetch --save git+https://github.com/xentropic-dev/zopcua.git
```

Then in your `build.zig`:

```zig
const ua = b.dependency("zopcua", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("ua", ua.module("ua"));

// open62541 requires mbedTLS for cryptographic operations and secure communication
// Currently, these must be installed as system libraries
// Future versions will support statically linking mbedTLS dependenciesexe.linkSystemLibrary("mbedtls");
exe.linkSystemLibrary("mbedtls");
exe.linkSystemLibrary("mbedx509");
exe.linkSystemLibrary("mbedcrypto");
```

## Usage

```zig
const std = @import("std");
const ua = @import("ua");

pub fn main() !void {
    var server = try ua.Server.init();
    defer server.deinit();

    try server.runUntilInterrupt(); // Blocks here until Ctrl-C
}
```

## Building

```bash
# Build the library
zig build

# Generate documentation
zig build docs
```

## License

This wrapper library is licensed under the MIT License. See [LICENSE](LICENSE) for details.

The underlying open62541 library is licensed under the Mozilla Public License 2.0. See the [open62541 repository](https://github.com/open62541/open62541) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
