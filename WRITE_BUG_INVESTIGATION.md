# OPC UA Write Bug Investigation

## Summary

Writing scalar values to variables created by our server crashes with a null pointer/misaligned address panic in open62541's `writeValueAttributeWithoutRange` function at line 39788. The crash occurs when attempting to `memcpy` arrayDimensions with a size of 0 bytes but NULL or invalid pointers.

## Current Status

**Temporary Fix Applied:** Patched `vendor/open62541.c:39788` to skip memcpy when `arrayDimensionsSize == 0`

**THIS IS A BANDAID - NOT A REAL FIX**

## The Problem

### What We Know

1. **Crash Location:** `vendor/open62541.c:39788` in `writeValueAttributeWithoutRange()`
   ```c
   memcpy(tmpValue.value.arrayDimensions, value->value.arrayDimensions,
          sizeof(UA_UInt32) * oldValue->value.arrayDimensionsSize);
   ```

2. **The Error:**
   ```
   thread panic: store of misaligned address 0x1 for type 'UA_UInt32 *'
   OR
   thread panic: null pointer passed as argument 1, which is declared to never be null
   ```

3. **When It Happens:**
   - Writing to scalar variables created via `Server.addVariableNode()`
   - The crash is SERVER-SIDE, not client-side
   - Writes to KEPServer work fine (per user testing)
   - Example server's variables work fine

4. **The Crash Conditions:**
   - Both old value (server node) and new value (client write) are scalars
   - Both have `arrayDimensionsSize == 0`
   - One or both have `arrayDimensions` pointer that is NULL or 0x1
   - open62541's optimization path tries to `memcpy(NULL, NULL, 0)` or `memcpy(ptr, 0x1, 0)`
   - Zig's safety checks catch this as undefined behavior

### What We Tried

1. **Allocating Dummy arrayDimensions Pointers**
   - Tried static dummy pointer → still got 0x1
   - Tried `allocator.create()` → still got 0x1
   - Tried `allocator.alloc(1)` → still got 0x1
   - **Finding:** The dummy pointer we create is VALID (0x7f7c5eaa1000), but somewhere between our code and the memcpy, it becomes 0x1

2. **Using Direct Scalar Write Function**
   - Initially used `UA_Client_writeValueAttribute_scalar()` to bypass variant conversion
   - Still crashed because it's a server-side bug
   - Switched to `UA_Client_writeValueAttribute()` with our `Variant.toC()`

3. **Investigating Variant Conversion**
   - Our `Variant.toC()` creates proper variants matching open62541's `UA_Variant_setScalar()`
   - Uses `std.mem.zeroes()` which matches `UA_Variant_init()` (both zero all fields)
   - Sets `arrayDimensionsSize = 0` and `arrayDimensions = NULL` for scalars (correct per OPC UA spec)

## The Real Problem (Hypothesis)

### Theory 1: open62541 Internal Variant Copy Issue

When processing a write request, open62541 likely calls `UA_Variant_copy()` somewhere in the chain. This function may:
- Not properly handle arrayDimensions when size is 0
- Create a new variant with invalid sentinel pointer (0x1)
- Not preserve our dummy pointer even if we allocate one

**Evidence:**
- We allocate valid dummy at 0x7f7c5eaa1000
- By the time memcpy is called, one pointer is 0x1
- 0x1 is Zig's sentinel value for zero-length allocations

### Theory 2: Node Creation Differences

Our `Server.addVariableNode()` might create nodes differently than the example server, even though the code looks identical:

**Example Server Code (WORKS):**
```zig
_ = try server.addVariableNode(
    ua.NodeId.initString(1, "the.answer"),
    parent,
    ua.ReferenceType.organizes,
    ua.QualifiedName.init(1, "the answer"),
    ua.StandardNodeId.base_data_variable_type,
    .{
        .value = ua.Variant.scalar(i32, 42),
        .display_name = ua.LocalizedText.init("en-US", "The Answer"),
        .access_level = .{ .read = true, .write = true },
    },
    allocator,
);
```

**Our Test Code (CRASHES):**
```zig
_ = try rw_server.addVariableNode(
    ua.NodeId.initString(1, "test.value"),
    ua.StandardNodeId.objects_folder,
    ua.ReferenceType.organizes,
    ua.QualifiedName.init(1, "TestValue"),
    ua.StandardNodeId.base_data_variable_type,
    .{
        .value = ua.Variant.scalar(i32, 100),
        .display_name = ua.LocalizedText.init("en-US", "Test Value"),
        .access_level = .{ .read = true, .write = true },
    },
    allocator,
);
```

**Potential Differences to Investigate:**
- Allocator used (page_allocator vs ??)
- Server initialization differences
- Timing of node creation (before vs after server start)
- Missing attributes (value_rank, data_type, etc.)

### Theory 3: VariableAttributes.toC() Issue

Our `VariableAttributes.toC()` conversion might not match what open62541 expects:

**Current Implementation:**
```zig
pub fn toC(self: VariableAttributes, allocator: std.mem.Allocator) !c.UA_VariableAttributes {
    var result = std.mem.zeroes(c.UA_VariableAttributes);
    result.specifiedAttributes = self.specified_attributes;
    result.displayName = self.display_name.toC();
    result.description = self.description.toC();
    result.value = try self.value.toC(allocator);
    result.valueRank = self.value_rank;
    // ... etc
}
```

**open62541 Default:**
```c
const UA_VariableAttributes UA_VariableAttributes_default = {
    0,                           /* specifiedAttributes */
    {{0, NULL}, {0, NULL}},      /* displayName */
    {{0, NULL}, {0, NULL}},      /* description */
    0, 0,                        /* writeMask (userWriteMask) */
    {NULL, UA_VARIANT_DATA,      /* value */
     0, NULL, 0, NULL},
    ...
};
```

## Investigation Steps Needed

### 1. Compare Working vs Non-Working Node Creation

- [ ] Run example server and capture its node creation with gdb/logging
- [ ] Run our test and capture the same
- [ ] Compare the actual C structs being passed to `UA_Server_addVariableNode()`
- [ ] Look for differences in:
  - `specifiedAttributes` field
  - `value_rank` (ours defaults to -1, example might be different)
  - `data_type` NodeId
  - Any other fields we're not setting

### 2. Trace the Write Path

- [ ] Add logging to track variant transformations:
  1. Client creates variant → logs pointer address
  2. Client sends write → logs pointer address
  3. Server receives write → logs pointer address
  4. Server enters `writeValueAttributeWithoutRange` → logs both old and new pointers
- [ ] Find where the 0x1 sentinel pointer is introduced

### 3. Check open62541 Variant Handling

- [ ] Review `UA_Variant_copy()` implementation for scalar handling
- [ ] Review `UA_Variant_init()` to ensure it matches `std.mem.zeroes()`
- [ ] Look for any open62541 code that might allocate zero-length arrayDimensions

### 4. Test Minimal Reproduction

Create a minimal C example that:
```c
UA_Server *server = UA_Server_new();
UA_ServerConfig_setDefault(UA_Server_getConfig(server));

// Create node EXACTLY like we do
UA_VariableAttributes attr = UA_VariableAttributes_default;
UA_Int32 value = 100;
UA_Variant_setScalar(&attr.value, &value, &UA_TYPES[UA_TYPES_INT32]);
attr.displayName = UA_LOCALIZEDTEXT("en-US", "Test");
attr.accessLevel = UA_ACCESSLEVELMASK_READ | UA_ACCESSLEVELMASK_WRITE;

UA_NodeId nodeId = UA_NODEID_STRING(1, "test.value");
UA_Server_addVariableNode(server, nodeId, ...);

UA_Server_run_startup(server);

// Try to write from client
UA_Client *client = UA_Client_new();
UA_Client_connect(client, "opc.tcp://localhost:4840");
UA_Int32 newValue = 999;
UA_Variant_setScalar(&writeValue, &newValue, &UA_TYPES[UA_TYPES_INT32]);
UA_Client_writeValueAttribute(client, nodeId, &writeValue);
```

If this reproduces, it's an open62541 bug. If it doesn't, we're doing something wrong in our Zig wrapper.

### 5. Check Translate-C Issues

- [ ] Review how `@cImport` translated the `UA_Variant` struct
- [ ] Verify alignment and field ordering matches C expectations
- [ ] Check if any union/packed struct issues exist

## Key Code Locations

### Our Code
- `src/server.zig:290` - `addVariableNode()` implementation
- `src/variable_attributes.zig:24` - `toC()` conversion
- `src/variant.zig:98` - `Variant.toC()` conversion
- `src/client.zig:240` - `writeValueAttribute()` implementation
- `tests/integration_test.zig:84` - Write test that reproduces the bug

### open62541 Code
- `vendor/open62541.c:39762` - `writeValueAttributeWithoutRange()` - THE CRASH SITE
- `vendor/open62541.c:39788` - The problematic memcpy line
- Search for `UA_Variant_copy` - Variant copying logic
- Search for `UA_Variant_setScalar` - How scalars are supposed to be created

## The Bandaid Fix

```c
// vendor/open62541.c:39785
/* Copy the data over the old memory */
memcpy(tmpValue.value.data, value->value.data,
       oSize * oldValue->value.type->memSize);

/* BANDAID: Only copy arrayDimensions if size > 0 */
if(oldValue->value.arrayDimensionsSize > 0) {
    memcpy(tmpValue.value.arrayDimensions, value->value.arrayDimensions,
           sizeof(UA_UInt32) * oldValue->value.arrayDimensionsSize);
}
```

**Why This Works:**
- Skips the memcpy entirely when size is 0
- No undefined behavior even with NULL/invalid pointers
- Correct behavior: there are no array dimensions to copy for scalars

**Why This Is Wrong:**
- We shouldn't need to patch vendored C code
- The real bug is that one of the pointers is 0x1 instead of NULL
- Something earlier in the chain is creating invalid variants

## Questions That Need Answers

1. **Where does address 0x1 come from?**
   - Is it from Zig's zero-length allocation?
   - Is it from open62541's internal code?
   - Is it a sentinel value being used incorrectly?

2. **Why does example server work but ours doesn't?**
   - Same code structure
   - Same API calls
   - Different result

3. **Why does writing to KEPServer work?**
   - User reported writes work against KEPServer
   - KEPServer's nodes probably handle the NULL pointers correctly
   - Or KEPServer doesn't use the optimization path in writeValueAttributeWithoutRange

4. **Is this a Zig translate-c issue?**
   - Are we accidentally triggering Zig-specific behavior?
   - Is the C struct layout different than expected?

## Next Steps

1. **Create minimal C reproduction** to isolate Zig vs open62541 issue
2. **Add extensive logging** to trace pointer values through the entire write path
3. **Compare working example server** node creation byte-by-byte with ours
4. **Test with different allocators** to see if it affects the 0x1 sentinel
5. **Review open62541 issue tracker** for similar problems
6. **Consider filing open62541 bug** if memcpy(NULL, NULL, 0) is triggering in their code

## Temporary Workaround for Users

Until the real fix is found, users must:
1. Keep the patch in `vendor/open62541.c:39788`
2. Be aware this is a bandaid covering up a deeper issue
3. Watch for any other symptoms of incorrect variant handling

## Related Issues

- User encountered this in their other project too
- Suggests it's not specific to our test code
- Likely affects any Zig code using open62541 with scalar variable writes
