#ifndef OPEN62541_HELPERS_H
#define OPEN62541_HELPERS_H

#include "open62541.h"

// Result structs for server/client creation
typedef struct {
  UA_StatusCode status;
  UA_Server *server;
} UA_ServerResult;

typedef struct {
  UA_StatusCode status;
  UA_Client *client;
} UA_ClientResult;

// Server/Client creation helpers
UA_ServerResult UA_Server_newDefaultWithStatus(void);
UA_ClientResult UA_Client_newDefaultWithStatus(void);

// Server helpers
UA_StatusCode helper_addStringVariable(UA_Server *server, UA_UInt16 namespaceIndex,
    UA_UInt32 numericId, UA_NodeId parentNodeId, const char *browseName,
    const char *displayName, const char *initialValue);

UA_StatusCode helper_serverConfigSetDefault(UA_Server *server);
UA_StatusCode helper_clientConfigSetDefault(UA_Client *client);

const UA_DataType* get_ua_object_attributes_type(void) {
    return &UA_TYPES[UA_TYPES_OBJECTATTRIBUTES];
}

const UA_DataType* get_ua_variable_attributes_type(void) {
    return &UA_TYPES[UA_TYPES_VARIABLEATTRIBUTES];
}

const UA_DataType* get_ua_method_attributes_type(void) {
    return &UA_TYPES[UA_TYPES_METHODATTRIBUTES];
}

const UA_DataType* get_ua_object_type_attributes_type(void) {
    return &UA_TYPES[UA_TYPES_OBJECTTYPEATTRIBUTES];
}

const UA_DataType* get_ua_variable_type_attributes_type(void) {
    return &UA_TYPES[UA_TYPES_VARIABLETYPEATTRIBUTES];
}

const UA_DataType* get_ua_reference_type_attributes_type(void) {
    return &UA_TYPES[UA_TYPES_REFERENCETYPEATTRIBUTES];
}

const UA_DataType* get_ua_data_type_attributes_type(void) {
    return &UA_TYPES[UA_TYPES_DATATYPEATTRIBUTES];
}

const UA_DataType* get_ua_view_attributes_type(void) {
    return &UA_TYPES[UA_TYPES_VIEWATTRIBUTES];
}

const UA_DataType* get_ua_type_by_index(size_t index) {
    if (index >= UA_TYPES_COUNT) {
        return NULL;
    }
    return &UA_TYPES[index];
}

size_t get_ua_types_count(void) {
    return UA_TYPES_COUNT;
}

// Variant initialization helpers
//
// IMPORTANT: These wrappers ensure variants are initialized using open62541's own
// UA_Variant_setScalarCopy() and UA_Variant_setArrayCopy() functions, which guarantees:
// 1. Proper initialization of all struct fields (including arrayDimensions)
// 2. Compatibility with open62541's internal variant copying and manipulation logic
// 3. Correct memory management using open62541's allocator
//
// Using these functions instead of manually constructing UA_Variant structs prevents
// issues with uninitialized fields and ensures proper interop with open62541.

// Initialize a scalar variant by copying the data
// Returns UA_STATUSCODE_GOOD on success
UA_StatusCode helper_variant_setScalarCopy(UA_Variant *variant, const void *data,
                                           const UA_DataType *type);

// Initialize an array variant by copying the data
// Returns UA_STATUSCODE_GOOD on success
UA_StatusCode helper_variant_setArrayCopy(UA_Variant *variant, const void *data,
                                          size_t arrayLength, const UA_DataType *type);

// Configuration helpers
//
// These helpers wrap open62541's configuration functions to provide a clean interface
// for setting up server and client configurations with security.

// Create a UA_ByteString from a byte array
// Note: Does NOT copy the data, just wraps the pointer
UA_ByteString helper_createByteString(const void *data, size_t length);

// Set up minimal server configuration (no security)
UA_StatusCode helper_serverConfigSetMinimal(
    UA_ServerConfig *config,
    UA_UInt16 port,
    const UA_ByteString *certificate
);

// Set up server configuration with full security policies
UA_StatusCode helper_serverConfigSetSecure(
    UA_ServerConfig *config,
    UA_UInt16 port,
    const UA_ByteString *certificate,
    const UA_ByteString *privateKey,
    const UA_ByteString *trustList,
    size_t trustListSize,
    const UA_ByteString *issuerList,
    size_t issuerListSize,
    const UA_ByteString *revocationList,
    size_t revocationListSize
);

// Set up minimal client configuration
UA_StatusCode helper_clientConfigSetMinimal(UA_ClientConfig *config);

// Set up client configuration with security
UA_StatusCode helper_clientConfigSetSecure(
    UA_ClientConfig *config,
    const UA_ByteString *certificate,
    const UA_ByteString *privateKey,
    UA_MessageSecurityMode securityMode,
    const char *securityPolicyUri
);


#endif
