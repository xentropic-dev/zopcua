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
