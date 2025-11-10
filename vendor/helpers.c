#include "helpers.h"

UA_StatusCode helper_serverConfigSetDefault(UA_Server *server) {
  UA_ServerConfig *config = UA_Server_getConfig(server);
  return UA_ServerConfig_setDefault(config);
}

UA_StatusCode helper_clientConfigSetDefault(UA_Client *client) {
  UA_ClientConfig *config = UA_Client_getConfig(client);
  return UA_ClientConfig_setDefault(config);
}

UA_ServerResult UA_Server_newDefaultWithStatus(void) {
  UA_ServerResult result;
  result.server = NULL;

  UA_ServerConfig config;
  memset(&config, 0, sizeof(UA_ServerConfig));

  result.status = UA_ServerConfig_setDefault(&config);
  if (result.status != UA_STATUSCODE_GOOD) {
    return result;
  }

  result.server = UA_Server_newWithConfig(&config);
  if (result.server == NULL) {
    result.status = UA_STATUSCODE_BADINTERNALERROR;
  }

  return result;
}

UA_ClientResult UA_Client_newDefaultWithStatus(void) {
  UA_ClientResult result;
  result.client = NULL;
  UA_ClientConfig config;
  memset(&config, 0, sizeof(UA_ClientConfig));
  /* Set up basic usable config including logger and event loop */
  result.status = UA_ClientConfig_setDefault(&config);
  if (result.status != UA_STATUSCODE_GOOD) {
    return result;
  }
  result.client = UA_Client_newWithConfig(&config);
  if (result.client == NULL) {
    result.status = UA_STATUSCODE_BADINTERNALERROR;
  }
  return result;
}

// Variant initialization helpers
//
// These thin wrappers ensure variants are initialized using open62541's own
// functions (UA_Variant_setScalarCopy and UA_Variant_setArrayCopy).
//
// Why this is needed:
// - open62541 expects variants to be initialized in a specific way
// - Manually constructing UA_Variant structs can lead to uninitialized fields
// - Using open62541's initialization functions ensures all fields (including
//   arrayDimensions, arrayDimensionsSize, etc.) are properly set
// - Memory is managed by open62541's allocator, ensuring consistency
//
// These wrappers are called from Zig code via extern declarations in src/helpers.zig

UA_StatusCode helper_variant_setScalarCopy(UA_Variant *variant, const void *data,
                                           const UA_DataType *type) {
  return UA_Variant_setScalarCopy(variant, data, type);
}

UA_StatusCode helper_variant_setArrayCopy(UA_Variant *variant, const void *data,
                                          size_t arrayLength, const UA_DataType *type) {
  return UA_Variant_setArrayCopy(variant, data, arrayLength, type);
}

// Configuration helpers

UA_ByteString helper_createByteString(const void *data, size_t length) {
  UA_ByteString bs;
  bs.length = length;
  bs.data = (UA_Byte*)data;
  return bs;
}

UA_StatusCode helper_serverConfigSetMinimal(
    UA_ServerConfig *config,
    UA_UInt16 port,
    const UA_ByteString *certificate
) {
  return UA_ServerConfig_setMinimal(config, port, certificate);
}

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
) {
  return UA_ServerConfig_setDefaultWithSecurityPolicies(
      config, port, certificate, privateKey,
      trustList, trustListSize,
      issuerList, issuerListSize,
      revocationList, revocationListSize
  );
}

UA_StatusCode helper_clientConfigSetMinimal(UA_ClientConfig *config) {
  return UA_ClientConfig_setDefault(config);
}

UA_StatusCode helper_clientConfigSetSecure(
    UA_ClientConfig *config,
    const UA_ByteString *certificate,
    const UA_ByteString *privateKey,
    UA_MessageSecurityMode securityMode,
    const char *securityPolicyUri
) {
  // First set up the default config
  UA_StatusCode status = UA_ClientConfig_setDefault(config);
  if (status != UA_STATUSCODE_GOOD) {
    return status;
  }

  // Set security mode
  config->securityMode = securityMode;

  // Set security policy URI if provided
  if (securityPolicyUri != NULL) {
    UA_String_clear(&config->securityPolicyUri);
    config->securityPolicyUri = UA_STRING_ALLOC(securityPolicyUri);
  }

  // Set client certificate if provided
  if (certificate != NULL && certificate->length > 0) {
    // Store certificate in client description
    UA_ByteString_clear(&config->clientDescription.applicationUri);
    status = UA_ByteString_copy(certificate, &config->clientDescription.applicationUri);
    if (status != UA_STATUSCODE_GOOD) {
      return status;
    }
  }

  // Note: Private key handling is typically done through the security policy configuration
  // which is more complex. For now, we set the basic parameters.
  // Full implementation would require setting up the security policy properly.

  return UA_STATUSCODE_GOOD;
}
