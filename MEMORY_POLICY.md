# Memory Management Policy

This document describes the memory management patterns and conventions used in the zopcua library.

## Core Principles

1. **Caller-Owned Data**: Functions that return allocated data should take an `allocator` parameter and clearly document that the caller owns the returned memory.

2. **C Translation Layer Only**: The ONLY time we allocate memory internally (without taking an allocator parameter) is for temporary C ABI conversions. Always use an arena backed by `c_allocator` for this.

3. **Unmanaged Pattern**: Types use the "unmanaged" pattern where `deinit()` takes an allocator parameter to free resources.

## Allocator Parameter Guidelines

### When to Accept an Allocator Parameter

Accept an `allocator` parameter **ONLY** when:
- The function returns heap-allocated data that the caller must free

**Example:**
```zig
pub fn getNamespaceByIndex(
    self: *Server,
    allocator: Allocator,
    namespace_index: u16,
) ![]const u8 {
    // Returns an allocated string that the caller must free
    // The allocator parameter is for the RETURNED data
    return allocator.dupe(u8, slice);
}
```

**Not this:**
```zig
// WRONG - don't do this
pub fn addNamespace(self: *Server, allocator: Allocator, uri: []const u8) !u16 {
    // Returns u16 (scalar), allocator only used for temp C conversion
    // This is a memory policy violation - should use internal arena
}
```

### When NOT to Accept an Allocator Parameter

DO NOT accept an allocator parameter when the function:
- Returns scalar values or non-allocated data (e.g., `u16`, `NodeId` struct)
- Only needs memory for temporary C ABI conversions

In these cases, use an internal arena backed by `c_allocator` for C conversions.

**Example:**
```zig
pub fn addObjectNode(self: *Server, node_id: NodeId, ...) !NodeId {
    // Internal arena for C ABI conversions ONLY
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();

    // Convert Zig types to C types temporarily
    const c_node_id = try node_id.toC(arena.allocator());
    const c_name = try name.toC(arena.allocator());
    // ... more conversions

    // Call C API
    const status = c.UA_Server_addObjectNode(...);

    // Return scalar NodeId (no allocation, caller doesn't own heap data)
    return NodeId.fromC(out_node_id);
}
```

**If the function also returns allocated data**, you still need an allocator parameter for the returned data, but use a separate arena for C conversions:
```zig
pub fn readValueAttribute(self: Client, allocator: Allocator, node_id: NodeId) !Variant {
    // Internal arena for C ABI conversion (NodeId -> C)
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();

    const c_node_id = try node_id.toC(arena.allocator());

    var c_variant: c.UA_Variant = undefined;
    const status = c.UA_Client_readValueAttribute(self.handle, c_node_id, &c_variant);

    // Use PASSED allocator for returned data (caller owns this)
    return try Variant.fromC(c_variant, allocator);
}
```

## Common Patterns

### Pattern 1: Internal Arena for Temporary C Conversions

When you need to convert Zig types to C types temporarily:

```zig
pub fn someOperation(self: *Server, param: NodeId) !Result {
    // Create arena for temporary allocations
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();

    // Use arena for temporary C conversions
    const c_param = try param.toC(arena.allocator());
    // No explicit freeToC() needed - arena handles cleanup

    // Call C API
    const result = c.UA_Some_Function(self.handle, c_param);

    return convertResult(result);
}
```

### Pattern 2: Caller-Owned Return Data

When returning allocated data to the caller:

```zig
pub fn getData(self: *Server, allocator: Allocator, id: NodeId) ![]u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();

    // Temporary conversions use internal arena
    const c_id = try id.toC(arena.allocator());

    // Get C data
    var c_result = c.UA_Get_Data(self.handle, c_id);

    // Convert to Zig using CALLER's allocator
    // Caller owns this memory
    return try convertCString(c_result, allocator);
}
```

### Pattern 3: Unmanaged Types

Types that manage resources use the unmanaged pattern:

```zig
pub const MyType = struct {
    data: []u8,

    pub fn init(allocator: Allocator) !MyType {
        return .{
            .data = try allocator.alloc(u8, 100),
        };
    }

    // deinit takes allocator to free resources
    pub fn deinit(self: *MyType, allocator: Allocator) void {
        allocator.free(self.data);
    }
};
```

## Rationale

### Why Internal Arenas for Temporary Allocations?

1. **Cleaner API**: Functions don't expose implementation details about temporary allocations
2. **Safety**: Arena guarantees all temporary memory is freed, even on error paths
3. **Performance**: Arena allocations are fast, and batch deallocation is more efficient than individual frees
4. **Simplicity**: No need for error-prone manual `defer freeToC()` chains

### Why Do We Need Temporary Allocations for C Translation?

The open62541 C library expects specific data structures with specific memory layouts. Many OPC UA types require heap-allocated data:

**String Types:**
- C expects null-terminated strings (`char*`) or `UA_String` with `.data` pointer
- Zig strings are `[]const u8` - not null-terminated, different representation
- **Allocation required** to create a null-terminated copy or `UA_String` with owned data

**NodeId Types:**
- String-based NodeIds (`ns=2;s=temperature`) contain a string identifier
- GUID-based NodeIds may contain dynamically-sized data
- **Allocation required** when NodeId contains string/dynamic data

**Complex Types:**
- `UA_QualifiedName` contains a `UA_String` (which may need allocation)
- `UA_VariableAttributes` contains multiple `UA_LocalizedText` fields (strings)
- Arrays in variants need proper memory layout for C

**Why can't we just stack-allocate?**
- We don't know the size at compile time (e.g., string length is runtime data)
- C API may hold references to the data during the call
- Some types require specific alignment/padding for C compatibility

### The Standard Pattern: Arena Backed by c_allocator

For C ABI conversions, **always** use an arena backed by `c_allocator`. This is not optional - it's the standard pattern:

```zig
pub fn addObjectNode(...) !NodeId {
    // Standard pattern: arena backed by c_allocator for C conversions
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();

    // All C conversions use arena.allocator()
    const c_node_id = try node_id.toC(arena.allocator());
    const c_parent_node_id = try parent_node_id.toC(arena.allocator());
    const c_parent_ref_node_id = try parent_ref_node_id.toC(arena.allocator());
    const c_name = try name.toC(arena.allocator());
    const c_type_definition = try type_definition.toC(arena.allocator());

    // Call C API
    const status = c.UA_Server_addObjectNode(...);

    // arena.deinit() frees all C conversions automatically
    return NodeId.fromC(out_node_id);
}
```

**Why this pattern?**
- **Safety**: Single `defer arena.deinit()` guarantees all memory is freed on all code paths (success, error, early return)
- **Simplicity**: No need for error-prone chains of `defer freeToC()` calls
- **Performance**: Batch deallocation is more efficient than individual frees
- **Correctness**: Impossible to forget to free one of the allocations
- **Consistency**: Every function that does C conversions looks the same

**Even for a single allocation**, use the arena pattern for consistency:
```zig
pub fn addNamespace(self: *Server, allocator: Allocator, uri: []const u8) !u16 {
    // Even though there's only one allocation, use arena for consistency
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();

    const c_uri = try arena.allocator().allocSentinel(u8, uri.len, 0);
    @memcpy(c_uri, uri);

    return c.UA_Server_addNamespace(self.handle, c_uri.ptr);
}
```

This keeps the code consistent and makes it obvious that this is a C translation allocation.

### Why c_allocator for Arenas?

The library uses `std.heap.c_allocator` as the backing allocator for internal arenas:

**Rationale:**
- **C API Behavior**: open62541 **deep copies** most data passed through its ABI. When you pass a `UA_String` or `UA_NodeId` to the C library, it makes its own internal copy. This means our temporary allocations can be freed immediately after the C function returns.
- **Lifetime**: These arenas are short-lived (function scope only) - we allocate, call C API, C library copies the data, we free
- **Availability**: `c_allocator` is globally available, no need to pass it around
- **C Interop**: We're already linking to C code (open62541), so libc malloc is present
- **Bounded Usage**: Memory usage is limited by function parameters (e.g., a few NodeIds)
- **Performance**: C malloc/free is highly optimized for this use case

**Important**: The C API owns its own copies of the data. Our temporary allocations exist only during the function call. The pattern looks like:

```zig
var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
defer arena.deinit();  // Safe to free immediately

const c_string = try convertToC(arena.allocator(), zig_string);
c.UA_Server_addSomething(c_string);  // C library deep copies c_string internally
// arena.deinit() runs here - our copy is freed, C library still has its copy
```

**Why not use the passed allocator?**
If a function takes an allocator for **returned data**, that allocator is meant for the data the caller will own. Mixing it with temporary allocations would be confusing:

```zig
// CONFUSING - don't do this:
pub fn getData(self: *Server, allocator: Allocator) ![]u8 {
    // Using allocator for BOTH temporary AND returned data
    const temp = try allocator.alloc(u8, 10);  // temporary
    defer allocator.free(temp);

    return try allocator.dupe(u8, temp);  // returned (caller owns)
}

// CLEAR - do this:
pub fn getData(self: *Server, allocator: Allocator) ![]u8 {
    // Separate concerns: arena for temps, allocator for returned data
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();

    const temp = try arena.allocator().alloc(u8, 10);  // temporary

    return try allocator.dupe(u8, temp);  // returned (caller owns)
}
```

This separation makes it clear:
- **Arena allocations**: Implementation details, caller doesn't care
- **Parameter allocator**: Used for data the caller will own and must free

## Examples from Codebase

### Correct: browseWithDescription
```zig
pub fn browseWithDescription(
    self: Client,
    allocator: std.mem.Allocator,  // For returned BrowseResult (caller-owned)
    desc: BrowseDescription,
) BrowseError!BrowseResult {
    // Internal arena for temporary conversions
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();

    const c_desc = try desc.toC(arena.allocator());
    // ...
}
```

### Correct: getNamespaceByName
```zig
pub fn getNamespaceByName(
    self: *Server,
    namespace_uri: []const u8,  // No allocator - returns scalar u16
) NamespaceError!u16 {
    // Use arena even for single allocation - consistency!
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();

    const c_uri = try arena.allocator().allocSentinel(u8, namespace_uri.len, 0);
    @memcpy(c_uri, namespace_uri);

    return c.UA_Server_getNamespaceByName(self.handle, c_uri.ptr);
}
```

### Incorrect (Now Fixed): Old readValueAttribute
```zig
// DON'T DO THIS:
pub fn readValueAttribute(self: Client, allocator: Allocator, node_id: NodeId) !Variant {
    // WRONG: Uses c_allocator directly instead of arena
    const c_node_id = node_id.toC(std.heap.c_allocator);
    defer node_id.freeToC(std.heap.c_allocator, c_node_id);
    // ...
}
```

## Checklist for New Functions

When writing a new function:

- [ ] Does it return allocated data? → Accept allocator parameter
- [ ] Does it only make temporary allocations? → Use internal arena
- [ ] Does it convert Zig types to C temporarily? → Use internal arena
- [ ] Does it return a scalar or non-allocated value? → Don't accept allocator
- [ ] If accepting allocator, is it documented which data the caller owns?

## Related Documentation

- Zig Allocator Documentation: https://ziglang.org/documentation/master/std/#std.mem.Allocator
- Arena Allocator: https://ziglang.org/documentation/master/std/#std.heap.ArenaAllocator
