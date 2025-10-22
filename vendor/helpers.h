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


#endif
