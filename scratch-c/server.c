#include "../vendor/open62541.h"

static void addVariable(UA_Server *server) {
  /* Define the attribute of the myInteger variable node */
  UA_VariableAttributes attr = UA_VariableAttributes_default;
  UA_Int32 myInteger = 42;
  UA_Variant_setScalar(&attr.value, &myInteger, &UA_TYPES[UA_TYPES_INT32]);
  attr.description = UA_LOCALIZEDTEXT("en-US", "the answer");
  attr.displayName = UA_LOCALIZEDTEXT("en-US", "the answer");
  attr.dataType = UA_TYPES[UA_TYPES_INT32].typeId;
  attr.accessLevel = UA_ACCESSLEVELMASK_READ | UA_ACCESSLEVELMASK_WRITE;

  /* Add the variable node to the information model */
  UA_NodeId myIntegerNodeId = UA_NODEID_STRING(1, "the.answer");
  UA_QualifiedName myIntegerName = UA_QUALIFIEDNAME(1, "the answer");
  UA_NodeId parentNodeId = UA_NODEID_NUMERIC(0, UA_NS0ID_OBJECTSFOLDER);
  UA_NodeId parentReferenceNodeId = UA_NODEID_NUMERIC(0, UA_NS0ID_ORGANIZES);
  UA_Server_addVariableNode(server, myIntegerNodeId, parentNodeId,
                            parentReferenceNodeId, myIntegerName,
                            UA_NODEID_NUMERIC(0, UA_NS0ID_BASEDATAVARIABLETYPE),
                            attr, NULL, NULL);
}

int main(void) {
  UA_Server *server = UA_Server_new();
  addVariable(server);
  UA_Server_runUntilInterrupt(server);
  UA_Server_delete(server);
  return 0;
}
