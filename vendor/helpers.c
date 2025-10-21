#include "helpers.h"

UA_StatusCode helper_serverConfigSetDefault(UA_Server *server) {
  UA_ServerConfig *config = UA_Server_getConfig(server);
  return UA_ServerConfig_setDefault(config);
}

UA_StatusCode helper_clientConfigSetDefault(UA_Client *client) {
  UA_ClientConfig *config = UA_Client_getConfig(client);
  return UA_ClientConfig_setDefault(config);
}

typedef struct {
  UA_StatusCode status;
  UA_Server *server;
} UA_ServerResult;

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

typedef struct {
  UA_StatusCode status;
  UA_Client *client;
} UA_ClientResult;

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
