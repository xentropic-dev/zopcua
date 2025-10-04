#ifndef OPEN62541_HELPERS_H
#define OPEN62541_HELPERS_H

#include "open62541.h"

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


#endif
