<div align="center">
  <h1>🏭 zopcua</h1>
  <p>A Zig wrapper for <a href="https://github.com/open62541/open62541">open62541</a>, an open-source OPC UA implementation.</p>
  <p>
    <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-e0af68.svg?style=for-the-badge&logo=opensourceinitiative&logoColor=white" /></a>
    <a href="https://github.com/xentropic-dev/zopcua/actions"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/xentropic-dev/zopcua/ci.yml?style=for-the-badge&label=CI&logo=github&color=9ece6a" /></a>
    <a href="https://github.com/xentropic-dev/zopcua/stargazers"><img alt="GitHub Stars" src="https://img.shields.io/github/stars/xentropic-dev/zopcua?style=for-the-badge&color=7aa2f7&logo=github" /></a>
    <img alt="Zig 0.14" src="https://img.shields.io/badge/Zig-0.14-f7a41d.svg?style=for-the-badge&logo=zig&logoColor=white" />
  </p>
</div>

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
```

### mbedTLS Dependency

zopcua requires mbedTLS for cryptographic operations and secure communication. **By default, mbedTLS is statically linked from vendored sources** - no system installation required.

If you prefer to use system-installed mbedTLS libraries instead:

```zig
const ua = b.dependency("zopcua", .{
    .target = target,
    .optimize = optimize,
    .mbedtls = .system,  // Use system mbedTLS instead of vendored
});
exe.root_module.addImport("ua", ua.module("ua"));
```

When using system mbedTLS, ensure the libraries are installed:

- **macOS**: `brew install mbedtls`
- **Ubuntu/Debian**: `sudo apt install libmbedtls-dev`
- **Other Linux**: Use your distribution's package manager

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

Contributions are welcome! Please feel free to submit a Pull Request.
