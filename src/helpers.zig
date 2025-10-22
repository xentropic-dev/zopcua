//! This module provides helpers for open62541
//! Due to the library's use of bit fields in certain structs, we need to wrap
//! some function calls in C code first before exposing them to Zig, as Zig
//! does not support bit fields directly.
// zlint-disable
const c = @import("c.zig");

const ServerResult = extern struct {
    status: c.UA_StatusCode,
    server: ?*c.UA_Server,
};

const ClientResult = extern struct {
    status: c.UA_StatusCode,
    client: ?*c.UA_Client,
};

// I'm actually not sure this was necessary now.
pub extern fn UA_Server_newDefaultWithStatus() ServerResult;
pub extern fn UA_Client_newDefaultWithStatus() ClientResult;

// Variant initialization helpers
//
// These extern declarations link to C wrapper functions in vendor/helpers.c that call
// open62541's UA_Variant_setScalarCopy() and UA_Variant_setArrayCopy().
//
// IMPORTANT: Always use these functions (via Variant.toC()) to create UA_Variant
// structs for passing to open62541 APIs. Do NOT manually construct UA_Variant structs.
//
// Rationale:
// - Ensures proper initialization of all variant fields (type, data, arrayDimensions, etc.)
// - Uses open62541's allocator for memory management consistency
// - Prevents issues with uninitialized or incorrectly initialized struct fields
// - Required for proper interop with open62541's internal variant copying logic
//
// See vendor/helpers.h and vendor/helpers.c for implementation details.
pub extern fn helper_variant_setScalarCopy(variant: *c.UA_Variant, data: *const anyopaque, data_type: *const c.UA_DataType) c.UA_StatusCode;
pub extern fn helper_variant_setArrayCopy(variant: *c.UA_Variant, data: *const anyopaque, arrayLength: usize, data_type: *const c.UA_DataType) c.UA_StatusCode;
