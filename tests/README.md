# zopcua Integration Tests

Comprehensive integration testing suite for the zopcua OPC UA library, with extensive coverage of Variant types and concurrent access patterns.

## Directory Structure

```
tests/
├── README.md                       # This file
├── integration_test.zig            # Legacy integration test (backward compatibility)
├── helpers/                        # Reusable test utilities
│   ├── test_server.zig            # TestServer helper with lifecycle management
│   ├── test_fixtures.zig          # Standard test data and node setup
│   └── assertions.zig             # Custom test assertions
└── integration/                    # Comprehensive integration tests
    ├── variant_scalar_test.zig    # All scalar Variant types (18 types)
    ├── variant_array_test.zig     # All array Variant types (13 types)
    └── concurrent_test.zig        # Concurrent access patterns
```

## Test Categories

### 1. Variant Scalar Tests (`variant_scalar_test.zig`)

Tests all 18 scalar Variant types with read/write operations:

**Numeric Types:**
- `Boolean` - true/false values
- `SByte` (i8) - signed 8-bit integers
- `Byte` (u8) - unsigned 8-bit integers
- `Int16` (i16) - signed 16-bit integers
- `UInt16` (u16) - unsigned 16-bit integers
- `Int32` (i32) - signed 32-bit integers
- `UInt32` (u32) - unsigned 32-bit integers
- `Int64` (i64) - signed 64-bit integers
- `UInt64` (u64) - unsigned 64-bit integers
- `Float` (f32) - 32-bit floating point
- `Double` (f64) - 64-bit floating point

**Complex Types:**
- `String` - UTF-8 text
- `DateTime` - OPC UA timestamp (i64)
- `Guid` - 128-bit globally unique identifier
- `ByteString` - arbitrary binary data
- `NodeId` - OPC UA node identifier
- `StatusCode` - OPC UA status code
- `LocalizedText` - locale + text pair

Each test:
1. Reads initial value and validates against fixture data
2. Writes a new value
3. Reads back and verifies the write succeeded
4. Uses custom assertions for precise type-specific comparisons

**Run:** `zig build test-variant-scalar`

### 2. Variant Array Tests (`variant_array_test.zig`)

Tests all 13 array Variant types with dynamic-length arrays:

- `Boolean[]`, `SByte[]`, `Byte[]`
- `Int16[]`, `UInt16[]`, `Int32[]`, `UInt32[]`
- `Int64[]`, `UInt64[]`
- `Float[]`, `Double[]`
- `DateTime[]`, `StatusCode[]`

Additional edge cases:
- Empty arrays (length 0)
- Single-element arrays
- Large arrays (performance validation)
- Array resizing (write different lengths)

Each test validates:
- Array length preservation
- Element-by-element value accuracy
- Memory management (no leaks)
- Round-trip consistency

**Run:** `zig build test-variant-array`

### 3. Concurrent Access Tests (`concurrent_test.zig`)

Validates thread-safety and concurrent access patterns:

**Test 1: Concurrent Readers**
- 10 clients simultaneously reading the same node
- 20 reads per client (200 total operations)
- Validates: All reads succeed, no data corruption

**Test 2: Concurrent Writers**
- 5 clients simultaneously writing to the same node
- Intentional race condition to test server robustness
- Validates: All writes succeed, server remains stable

**Test 3: Mixed Read/Write**
- 10 readers + 5 writers on same node
- Validates: Readers see consistent data, writers don't block

**Test 4: Multiple Nodes**
- 8 clients on different nodes simultaneously
- Validates: No cross-node interference, isolation

**Run:** `zig build test-concurrent`

## Helper Infrastructure

### TestServer (`helpers/test_server.zig`)

Reusable server wrapper with lifecycle management:

```zig
var server = try TestServer.init(allocator, 4840);
defer server.deinit();

try server.startAsync();  // Runs in background thread
defer server.stop() catch {};

const endpoint = try server.getEndpointUrl(&buf);
```

Features:
- Automatic thread management
- Configurable port
- Helper for endpoint URL construction
- Clean shutdown handling

### Test Fixtures (`helpers/test_fixtures.zig`)

Standard test data and node setup:

```zig
const nodes = try fixtures.setupStandardNodes(&server, allocator);

// Access pre-defined test values
const expected = fixtures.TestScalarData.int32_value;
const array = fixtures.TestArrayData.float_array;
```

Provides:
- `TestNodeIds` - NodeId references for all standard test nodes
- `TestScalarData` - Known values for all scalar types
- `TestArrayData` - Known arrays for all array types
- `setupStandardNodes()` - Creates 35+ test nodes on a server

### Custom Assertions (`helpers/assertions.zig`)

Type-aware equality checks:

```zig
try assertions.expectVariantEqual(expected, actual);
try assertions.expectNodeIdEqual(expected_id, actual_id);
try assertions.expectNodeExists(client, node_id, allocator);
try assertions.expectReadError(client, node_id, .NodeIdUnknown, allocator);
```

Features:
- Deep equality for complex types (Guid, NodeId, LocalizedText)
- Approximate equality for floats (handles precision)
- Array element-by-element comparison
- Clear error messages

## Running Tests

### Individual Test Suites
```bash
zig build test-variant-scalar    # Scalar Variant tests
zig build test-variant-array      # Array Variant tests
zig build test-concurrent         # Concurrent access tests
zig build test-integration        # Legacy integration test
```

### Combined Test Runs
```bash
zig build test-integration-all    # All integration tests
zig build test-integration-quick  # Non-concurrent tests (faster for CI)
zig build test                    # Unit tests only
```

### With Build Options
```bash
zig build test-integration-all -Doptimize=ReleaseFast
zig build test-concurrent -Dmbedtls=system
```

## Test Coverage Summary

| Category | Test Files | Coverage |
|----------|-----------|----------|
| Scalar Variants | `variant_scalar_test.zig` | 18/18 types (100%) |
| Array Variants | `variant_array_test.zig` | 13/13 types (100%) |
| Concurrent Access | `concurrent_test.zig` | 4 scenarios |
| Test Helpers | `helpers/*.zig` | 3 modules |
| **Total** | **7 files** | **31+ Variant types** |

## Memory Safety

All tests use `std.heap.page_allocator` and rely on Zig's memory safety:
- Automatic leak detection via `defer`
- No manual memory management in test code
- All Variant operations use proper allocation/deallocation
- Server/client lifecycle properly managed

## Future Test Additions

Planned for future PRs:
- Browse operations (node hierarchy traversal)
- Subscription/monitoring tests
- Historical data access
- Security/authentication tests
- Large-scale performance benchmarks (1K+ nodes)
- String array Variant support
- NodeId array Variant support
- Multi-dimensional arrays
- Error recovery scenarios
- Network interruption simulation

## CI Integration

Recommended GitHub Actions workflow:

```yaml
- name: Run quick integration tests
  run: zig build test-integration-quick

- name: Run concurrent tests
  run: zig build test-concurrent

- name: Run all tests
  run: zig build test-integration-all
```

Use `test-integration-quick` for fast feedback in PRs, `test-integration-all` for release validation.
