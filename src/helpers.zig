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

// Configuration helpers
//
// These extern declarations link to C wrapper functions that configure server and client
// configurations with security settings.

/// Create a UA_ByteString from a byte array (does not copy data)
pub extern fn helper_createByteString(data: *const anyopaque, length: usize) c.UA_ByteString;

/// Set up minimal server configuration (no security)
pub extern fn helper_serverConfigSetMinimal(
    config: *c.UA_ServerConfig,
    port: c.UA_UInt16,
    certificate: ?*const c.UA_ByteString,
) c.UA_StatusCode;

/// Set up server configuration with full security policies
pub extern fn helper_serverConfigSetSecure(
    config: *c.UA_ServerConfig,
    port: c.UA_UInt16,
    certificate: *const c.UA_ByteString,
    privateKey: *const c.UA_ByteString,
    trustList: ?[*]const c.UA_ByteString,
    trustListSize: usize,
    issuerList: ?[*]const c.UA_ByteString,
    issuerListSize: usize,
    revocationList: ?[*]const c.UA_ByteString,
    revocationListSize: usize,
) c.UA_StatusCode;

/// Set up minimal client configuration
pub extern fn helper_clientConfigSetMinimal(config: *c.UA_ClientConfig) c.UA_StatusCode;

/// Set up client configuration with security
pub extern fn helper_clientConfigSetSecure(
    config: *c.UA_ClientConfig,
    certificate: ?*const c.UA_ByteString,
    privateKey: ?*const c.UA_ByteString,
    securityMode: c.UA_MessageSecurityMode,
    securityPolicyUri: ?[*:0]const u8,
) c.UA_StatusCode;
