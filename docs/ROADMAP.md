# zopcua Feature Parity Roadmap

This document tracks the implementation progress of Zig bindings for open62541, showing feature parity between the C library and the Zig wrapper.

**Overall Progress: 28%** (Core functionality in place, many advanced features pending)

> **Note:** Percentages are automatically calculated. After updating checkmarks (✅ 🟡 🔴 ❌), run `python3 scripts/update_roadmap.py` to recalculate all percentages.

---

## 1. Server Core Functionality

**Progress: 12%**

### 1.1 Server Lifecycle (100% ✅)
- ✅ `Server.init()` - Create server with default config
- ✅ `Server.initWithConfig()` - Create server with custom config
- ✅ `Server.deinit()` - Clean up server resources
- ✅ `Server.start()` - Start server (UA_Server_run_startup)
- ✅ `Server.stop()` - Stop server (UA_Server_run_shutdown)
- ✅ `Server.iterate()` - Process one event loop iteration
- ✅ `Server.runUntilInterrupt()` - Run until SIGINT

### 1.2 Node Management - Variables (17% 🔴)
- ✅ `Server.addVariableNode()` - Add variable node to address space
- ❌ `UA_Server_addVariableTypeNode` - Add variable type node
- ❌ `UA_Server_addDataSourceVariableNode` - Add variable with custom read/write callbacks
- ❌ `UA_Server_deleteNode` - Delete node from address space
- ❌ `UA_Server_addReference` - Add reference between nodes
- ❌ `UA_Server_deleteReference` - Delete reference between nodes

### 1.3 Node Management - Objects (20% 🔴)
- ✅ `Server.addObjectNode()` - Add object node to address space
- ❌ `UA_Server_addObjectTypeNode` - Add object type node
- ❌ `UA_Server_addViewNode` - Add view node
- ❌ `UA_Server_addReferenceTypeNode` - Add reference type node
- ❌ `UA_Server_addDataTypeNode` - Add data type node

### 1.4 Node Management - Methods (0% ❌)
- ❌ `UA_Server_addMethodNode` - Add method node
- ❌ `UA_Server_addMethodNodeEx` - Add method with extended options
- ❌ `UA_Server_setMethodNodeCallback` - Set method callback
- ❌ `UA_Server_call` - Call a method

### 1.5 Server Read/Write Operations (0% ❌)
- ❌ `UA_Server_read` - Generic read operation
- ❌ `UA_Server_readValue` - Read value attribute
- ❌ `UA_Server_readNodeId` - Read NodeId attribute
- ❌ `UA_Server_readBrowseName` - Read browse name attribute
- ❌ `UA_Server_readDisplayName` - Read display name attribute
- ❌ `UA_Server_readDescription` - Read description attribute
- ❌ `UA_Server_readWriteMask` - Read write mask attribute
- ❌ `UA_Server_readDataType` - Read data type attribute
- ❌ `UA_Server_readValueRank` - Read value rank attribute
- ❌ `UA_Server_readArrayDimensions` - Read array dimensions attribute
- ❌ `UA_Server_readAccessLevel` - Read access level attribute
- ❌ `UA_Server_write` - Generic write operation
- ❌ `UA_Server_writeValue` - Write value attribute
- ❌ `UA_Server_writeDisplayName` - Write display name attribute
- ❌ `UA_Server_writeDescription` - Write description attribute
- ❌ `UA_Server_writeWriteMask` - Write write mask attribute
- ❌ `UA_Server_writeDataType` - Write data type attribute
- ❌ `UA_Server_writeValueRank` - Write value rank attribute
- ❌ `UA_Server_writeArrayDimensions` - Write array dimensions attribute
- ❌ `UA_Server_writeAccessLevel` - Write access level attribute
- ❌ `UA_Server_writeDataValue` - Write data value with timestamp/status
- ❌ `UA_Server_writeObjectProperty` - Write object property

### 1.6 Server Browse Operations (0% ❌)
- ❌ `UA_Server_browse` - Browse nodes
- ❌ `UA_Server_browseNext` - Continue browse operation
- ❌ `UA_Server_browseRecursive` - Recursive browse
- ❌ `UA_Server_browseSimplifiedBrowsePath` - Browse using simplified path

### 1.7 Namespace Management (100% ✅)
- ✅ `Server.addNamespace()` - Add custom namespace
- ✅ `Server.getNamespaceByName()` - Get namespace index by URI
- ✅ `Server.getNamespaceByIndex()` - Get namespace URI by index

### 1.8 Subscriptions & Monitored Items (0% ❌)
- ❌ `UA_Server_createDataChangeMonitoredItem` - Create data change monitored item
- ❌ `UA_Server_createEventMonitoredItem` - Create event monitored item
- ❌ `UA_Server_deleteMonitoredItem` - Delete monitored item

### 1.9 Events & Alarms (0% ❌)
- ❌ `UA_Server_createEvent` - Create event
- ❌ `UA_Server_triggerEvent` - Trigger event
- ❌ `UA_Server_createCondition` - Create condition/alarm
- ❌ `UA_Server_deleteCondition` - Delete condition
- ❌ `UA_Server_triggerConditionEvent` - Trigger condition event
- ❌ `UA_Server_setConditionField` - Set condition field value
- ❌ `UA_Server_addCondition_begin` - Begin adding condition
- ❌ `UA_Server_addCondition_finish` - Finish adding condition
- ❌ `UA_Server_setLimitState` - Set limit state for alarm

### 1.10 PubSub (0% ❌)
- ❌ `UA_Server_addPubSubConnection` - Add PubSub connection
- ❌ `UA_Server_addPublishedDataSet` - Add published data set
- ❌ `UA_Server_addDataSetField` - Add field to data set
- ❌ `UA_Server_addWriterGroup` - Add writer group
- ❌ `UA_Server_addDataSetWriter` - Add data set writer
- ❌ `UA_Server_addReaderGroup` - Add reader group
- ❌ `UA_Server_addDataSetReader` - Add data set reader
- ❌ `UA_Server_addStandaloneSubscribedDataSet` - Add standalone subscribed data set
- ❌ `UA_Server_removePubSubConnection` - Remove PubSub connection
- ❌ `UA_Server_freezeWriterGroupConfiguration` - Freeze writer group
- ❌ `UA_Server_unfreezeWriterGroupConfiguration` - Unfreeze writer group

### 1.11 Discovery (0% ❌)
- ❌ `UA_Server_registerDiscovery` - Register server with discovery
- ❌ `UA_Server_deregisterDiscovery` - Deregister from discovery
- ❌ `UA_Server_setRegisterServerCallback` - Set register callback
- ❌ `UA_Server_setServerOnNetworkCallback` - Set network callback

### 1.12 Sessions & Security (0% ❌)
- ❌ `UA_Server_closeSession` - Close a session
- ❌ `UA_Server_setSessionAttribute` - Set session attribute
- ❌ `UA_Server_getSessionAttribute` - Get session attribute
- ❌ `UA_Server_deleteSessionAttribute` - Delete session attribute
- ❌ `UA_Server_updateCertificate` - Update server certificate

### 1.13 Callbacks & Lifecycle (0% ❌)
- ❌ `UA_Server_addRepeatedCallback` - Add repeated callback
- ❌ `UA_Server_addTimedCallback` - Add timed callback
- ❌ `UA_Server_changeRepeatedCallbackInterval` - Change callback interval
- ❌ `UA_Server_removeCallback` - Remove callback
- ❌ `UA_Server_setNodeTypeLifecycle` - Set node type lifecycle

### 1.14 Advanced Features (0% ❌)
- ❌ `UA_Server_forEachChildNodeCall` - Iterate over child nodes
- ❌ `UA_Server_translateBrowsePathToNodeIds` - Translate browse path
- ❌ `UA_Server_setVariableNode_dataSource` - Set custom data source
- ❌ `UA_Server_setVariableNode_valueCallback` - Set value callback
- ❌ `UA_Server_getNodeContext` - Get node context
- ❌ `UA_Server_setNodeContext` - Set node context
- ❌ `UA_Server_getConfig` - Get server config
- ❌ `UA_Server_getStatistics` - Get server statistics

---

## 2. Client Core Functionality

**Progress: 16%**

### 2.1 Client Lifecycle (100% ✅)
- ✅ `Client.init()` - Create client with default config
- ✅ `Client.initWithConfig()` - Create client with custom config
- ✅ `Client.deinit()` - Clean up client resources
- ✅ `Client.connect()` - Connect to server
- ✅ `Client.disconnect()` - Disconnect from server

### 2.2 Client Connection Management (9% 🔴)
- ✅ `UA_Client_connect` - Basic connection
- ❌ `UA_Client_connectUsername` - Connect with username/password
- ❌ `UA_Client_connectSecureChannel` - Connect secure channel only
- ❌ `UA_Client_disconnectSecureChannel` - Disconnect secure channel
- ❌ `UA_Client_connectAsync` - Async connect
- ❌ `UA_Client_disconnectAsync` - Async disconnect
- ❌ `UA_Client_activateSession` - Activate session
- ❌ `UA_Client_activateSessionAsync` - Activate session async
- ❌ `UA_Client_renewSecureChannel` - Renew secure channel
- ❌ `UA_Client_getState` - Get client state
- ❌ `UA_Client_run_iterate` - Iterate event loop

### 2.3 Client Read Operations (5% 🔴)
- ✅ `Client.readValueAttribute()` - Read value attribute
- ❌ `UA_Client_readAttribute` - Generic read attribute
- ❌ `UA_Client_readNodeIdAttribute` - Read NodeId attribute
- ❌ `UA_Client_readBrowseNameAttribute` - Read browse name
- ❌ `UA_Client_readDisplayNameAttribute` - Read display name
- ❌ `UA_Client_readDescriptionAttribute` - Read description
- ❌ `UA_Client_readWriteMaskAttribute` - Read write mask
- ❌ `UA_Client_readUserWriteMaskAttribute` - Read user write mask
- ❌ `UA_Client_readDataTypeAttribute` - Read data type
- ❌ `UA_Client_readValueRankAttribute` - Read value rank
- ❌ `UA_Client_readArrayDimensionsAttribute` - Read array dimensions
- ❌ `UA_Client_readAccessLevelAttribute` - Read access level
- ❌ `UA_Client_readUserAccessLevelAttribute` - Read user access level
- ❌ `UA_Client_readMinimumSamplingIntervalAttribute` - Read min sampling interval
- ❌ `UA_Client_readHistorizingAttribute` - Read historizing
- ❌ `UA_Client_readExecutableAttribute` - Read executable
- ❌ `UA_Client_readUserExecutableAttribute` - Read user executable
- ❌ `UA_Client_readEventNotifierAttribute` - Read event notifier
- ❌ `UA_Client_readNodeClassAttribute` - Read node class
- ❌ All async variants (`_async` suffix)

### 2.4 Client Write Operations (5% 🔴)
- ✅ `Client.writeValueAttribute()` - Write value attribute
- ❌ `UA_Client_writeAttribute` - Generic write attribute
- ❌ `UA_Client_writeNodeIdAttribute` - Write NodeId
- ❌ `UA_Client_writeBrowseNameAttribute` - Write browse name
- ❌ `UA_Client_writeDisplayNameAttribute` - Write display name
- ❌ `UA_Client_writeDescriptionAttribute` - Write description
- ❌ `UA_Client_writeWriteMaskAttribute` - Write write mask
- ❌ `UA_Client_writeUserWriteMaskAttribute` - Write user write mask
- ❌ `UA_Client_writeDataTypeAttribute` - Write data type
- ❌ `UA_Client_writeValueRankAttribute` - Write value rank
- ❌ `UA_Client_writeArrayDimensionsAttribute` - Write array dimensions
- ❌ `UA_Client_writeAccessLevelAttribute` - Write access level
- ❌ `UA_Client_writeMinimumSamplingIntervalAttribute` - Write min sampling interval
- ❌ `UA_Client_writeHistorizingAttribute` - Write historizing
- ❌ `UA_Client_writeExecutableAttribute` - Write executable
- ❌ `UA_Client_writeUserExecutableAttribute` - Write user executable
- ❌ `UA_Client_writeEventNotifierAttribute` - Write event notifier
- ❌ `UA_Client_writeValueAttributeEx` - Write with extended options
- ❌ All async variants (`_async` suffix)

### 2.5 Client Browse Operations (100% ✅)
- ✅ `Client.browse()` - Browse nodes with defaults
- ✅ `Client.browseWithDescription()` - Browse with full control
- ✅ `Client.browseNext()` - Continue browse with continuation point

### 2.6 Client Node Management (0% ❌)
- ❌ `UA_Client_addNode` - Add node to server
- ❌ `UA_Client_addVariableNode` - Add variable node
- ❌ `UA_Client_addObjectNode` - Add object node
- ❌ `UA_Client_addMethodNode` - Add method node
- ❌ `UA_Client_addViewNode` - Add view node
- ❌ `UA_Client_addReferenceTypeNode` - Add reference type
- ❌ `UA_Client_addDataTypeNode` - Add data type
- ❌ `UA_Client_addVariableTypeNode` - Add variable type
- ❌ `UA_Client_addObjectTypeNode` - Add object type
- ❌ `UA_Client_deleteNode` - Delete node
- ❌ `UA_Client_addReference` - Add reference
- ❌ `UA_Client_deleteReference` - Delete reference
- ❌ All async variants

### 2.7 Client Method Calls (0% ❌)
- ❌ `UA_Client_call` - Call server method
- ❌ `UA_Client_call_async` - Async method call

### 2.8 Client Subscriptions (33% 🟡)
- ✅ `Client.createSubscription()` - Create subscription
- ✅ `Client.deleteSubscription()` - Delete single subscription
- ❌ `UA_Client_Subscriptions_delete` - Delete multiple subscriptions
- ❌ `UA_Client_Subscriptions_modify` - Modify subscription
- ❌ `UA_Client_Subscriptions_setPublishingMode` - Set publishing mode
- ❌ All async variants

### 2.9 Client Monitored Items (27% 🔴)
- ✅ `Client.createMonitoredItem()` - Create data change monitored item (polling)
- ✅ `Client.createMonitoredItemWithCallback()` - Create with callback support
- ✅ `Client.deleteMonitoredItem()` - Delete single monitored item
- ❌ `UA_Client_MonitoredItems_createDataChanges` - Create multiple data change items
- ❌ `UA_Client_MonitoredItems_createEvent` - Create event monitored item
- ❌ `UA_Client_MonitoredItems_createEvents` - Create multiple event items
- ❌ `UA_Client_MonitoredItems_delete` - Delete multiple monitored items
- ❌ `UA_Client_MonitoredItems_modify` - Modify monitored items
- ❌ `UA_Client_MonitoredItems_setMonitoringMode` - Set monitoring mode
- ❌ `UA_Client_MonitoredItems_setTriggering` - Set triggering
- ❌ All async variants

### 2.10 Client History (0% ❌)
- ❌ `UA_Client_HistoryRead_raw` - Read raw history
- ❌ `UA_Client_HistoryRead_modified` - Read modified history
- ❌ `UA_Client_HistoryRead_events` - Read event history
- ❌ `UA_Client_HistoryUpdate_insert` - Insert history values
- ❌ `UA_Client_HistoryUpdate_replace` - Replace history values
- ❌ `UA_Client_HistoryUpdate_update` - Update history values
- ❌ `UA_Client_HistoryUpdate_deleteRaw` - Delete raw history

### 2.11 Client Discovery (0% ❌)
- ❌ `UA_Client_findServers` - Find servers
- ❌ `UA_Client_findServersOnNetwork` - Find servers on network
- ❌ `UA_Client_getEndpoints` - Get server endpoints

### 2.12 Client Advanced (11% 🔴)
- ❌ `UA_Client_Service_*` - Low-level service calls
- ❌ `UA_Client_forEachChildNodeCall` - Iterate child nodes
- ✅ `Client.getNamespaceByName()` - Get namespace index from URI
- ❌ `UA_Client_addTimedCallback` - Add timed callback
- ❌ `UA_Client_addRepeatedCallback` - Add repeated callback
- ❌ `UA_Client_removeCallback` - Remove callback
- ❌ `UA_Client_changeRepeatedCallbackInterval` - Change interval
- ❌ `UA_Client_getConfig` - Get client config
- ❌ `UA_Client_getContext` - Get client context

---

## 3. Data Types & Structures

**Progress: 49%**

### 3.1 Core Types (100% ✅)
- ✅ `NodeId` - Node identifier (numeric, string, GUID, bytestring)
- ✅ `QualifiedName` - Qualified name with namespace
- ✅ `ExpandedNodeId` - Node ID with server/namespace URI
- ✅ `Guid` - Global unique identifier
- ✅ `LocalizedText` - Localized text with locale
- ✅ `String` - OPC UA string wrapper
- ✅ `BrowseDirection` - Browse direction enum
- ✅ `NodeClass` - Node class enum

### 3.2 Variant Types (38% 🟡)
- ✅ All scalar types (boolean, integers, floats, string, datetime, guid, bytestring, nodeid, statuscode, localizedtext)
- ✅ Most array types (boolean, integers, floats, datetime, statuscode)
- 🟡 String arrays (partial - marked as not yet supported in toC)
- 🟡 NodeId arrays (partial - marked as not yet supported in toC)
- ❌ XmlElement
- ❌ ExtensionObject arrays
- ❌ Multi-dimensional arrays
- ❌ Matrix support

### 3.3 Attribute Types (45% 🟡)
- ✅ `VariableAttributes` - Variable node attributes
- ✅ `ObjectAttributes` - Object node attributes
- ✅ `AccessLevel` - Access level flags
- ✅ `EventNotifier` - Event notifier flags
- ✅ `AttributeWriteMask` - Write mask flags
- ❌ `MethodAttributes` - Method node attributes
- ❌ `ViewAttributes` - View node attributes
- ❌ `DataTypeAttributes` - Data type attributes
- ❌ `ReferenceTypeAttributes` - Reference type attributes
- ❌ `VariableTypeAttributes` - Variable type attributes
- ❌ `ObjectTypeAttributes` - Object type attributes

### 3.4 Browse Types (100% ✅)
- ✅ `BrowseDescription` - Browse operation parameters
- ✅ `BrowseResult` - Browse operation results
- ✅ `ReferenceDescription` - Reference description
- ✅ `NodeClassMask` - Node class filter mask
- ✅ `BrowseResultMask` - Result mask for browse

### 3.5 Advanced Types (0% ❌)
- ❌ `DataValue` - Value with timestamp and quality
- ❌ `DiagnosticInfo` - Diagnostic information
- ❌ `ExtensionObject` - Generic extension object
- ❌ `Argument` - Method argument
- ❌ `Range` - Numeric range
- ❌ `EUInformation` - Engineering unit information
- ❌ `ApplicationDescription` - Application description
- ❌ `UserTokenPolicy` - User token policy
- ❌ `EndpointDescription` - Endpoint description
- ❌ `ServerStatusDataType` - Server status
- ❌ `BuildInfo` - Build information

---

## 4. Configuration & Security

**Progress: 21%**

### 4.1 Server Configuration (23% 🔴)
- ✅ `ServerConfig` struct
- ✅ Port configuration
- ✅ Security mode (None, Sign, SignAndEncrypt)
- ❌ Certificate configuration
- ❌ Private key configuration
- ❌ Trust list configuration
- ❌ User authentication configuration
- ❌ Access control configuration
- ❌ Network layer configuration
- ❌ Custom hostname
- ❌ Endpoint configuration
- ❌ Server description
- ❌ Application URI

### 4.2 Client Configuration (27% 🔴)
- ✅ `ClientConfig` struct
- ✅ Timeout configuration
- ✅ Security mode
- ❌ Certificate configuration
- ❌ Private key configuration
- ❌ Trust list configuration
- ❌ Session timeout
- ❌ Secure channel lifetime
- ❌ Request timeout
- ❌ Connection retry
- ❌ User identity token

### 4.3 Security Policies (0% ❌)
- ❌ SecurityPolicy configuration
- ❌ Certificate validation
- ❌ User authentication callbacks
- ❌ Access control callbacks
- ❌ Encryption configuration

---

## 5. Error Handling

**Progress: 86%**

### 5.1 Error Types (100% ✅)
- ✅ `AddNodeError` - Node addition errors
- ✅ `NamespaceError` - Namespace operation errors
- ✅ `ReadAttributeError` - Read operation errors
- ✅ `WriteAttributeError` - Write operation errors
- ✅ `BrowseError` - Browse operation errors
- ✅ `OpcUaError` - Generic OPC UA status code errors

### 5.2 Error Mapping (70% 🟡)
- ✅ Server errors mapped to specific types
- ✅ Client errors mapped to specific types
- ✅ Browse errors mapped
- 🟡 Some edge cases may need refinement
- ❌ Diagnostic info not captured

---

## 6. Testing & Examples

**Progress: 72%**

### 6.1 Examples (76% 🟡)
- ✅ `server-minimal` - Minimal server
- ✅ `server-simple` - Simple server with variables
- ✅ `server-advanced` - Advanced server features
- ✅ `server-namespace` - Namespace management
- ✅ `server-custom-config` - Custom configuration
- ✅ `server-object-nesting` - Nested objects
- ✅ `client-minimal` - Minimal client
- ✅ `client-read` - Read operations
- ✅ `client-write` - Write operations
- ✅ `client-custom-config` - Custom configuration
- ✅ `client-server` - Combined client-server
- ✅ `client-namespace` - Namespace discovery
- ✅ `client-callback` - Subscription with callback notifications
- ❌ Method call examples
- ❌ Event examples
- ❌ PubSub examples
- ❌ History examples

### 6.2 Unit Tests (73% 🟡)
- ✅ NodeId tests
- ✅ QualifiedName tests
- ✅ Variant tests
- ✅ Browse tests
- ✅ Server namespace tests
- ✅ Server node addition tests
- ✅ Client tests (basic)
- ✅ Subscription unit tests
- ❌ Method tests
- ❌ Event tests
- ❌ Security tests

### 6.3 Integration Tests (62% 🟡)
- ✅ Client-server communication
- ✅ Browse operations
- ✅ Read/write operations
- ✅ Variant serialization
- ✅ Subscription integration tests
- ❌ Security tests
- ❌ PubSub tests
- ❌ Performance tests

---

## 7. Documentation

**Progress: 38%**

### 7.1 API Documentation (75% 🟡)
- ✅ Comprehensive inline documentation for Server
- ✅ Comprehensive inline documentation for Client
- ✅ Comprehensive inline documentation for types
- ✅ Error documentation
- 🟡 Some advanced features lack docs
- ❌ API reference generation

### 7.2 Guides & Tutorials (7% 🔴)
- 🟡 README.md with basic info
- ❌ Getting started guide
- ❌ Architecture overview
- ❌ Migration guide from C
- ❌ Best practices guide
- ❌ Security guide
- ❌ Performance tuning guide

---

## Feature Categories Summary

| Category | Progress | Status |
|----------|----------|--------|
| Server Core | 12% | 🔴 Minimal |
| Client Core | 16% | 🔴 Minimal |
| Data Types | 49% | 🟡 Partial |
| Configuration | 21% | 🔴 Minimal |
| Error Handling | 82% | ✅ Good |
| Testing | 72% | ✅ Good |
| Documentation | 35% | 🔴 Minimal |
| **Overall** | **28%** | 🔴 Early |

---

## Contributing

Areas most in need of contribution:
1. 🟡 Subscriptions & Monitored Items - Basic support complete, async variants and advanced features needed
2. 🔴 Method Calls - High priority, straightforward
3. 🔴 Events & Alarms - Medium priority, complex implementation
4. 🔴 PubSub - Lower priority, very complex
5. 🟡 Documentation - Always welcome

---

## Notes

- **✅ Complete** - Feature fully implemented and tested
- **🟡 Partial** - Feature partially implemented or needs refinement
- **🔴 Minimal** - Feature barely started
- **❌ Missing** - Feature not yet implemented

Percentages are estimates based on function count and complexity. Some functions are more critical than others, so lower percentages don't necessarily mean less usability for common use cases.

The current implementation (25% overall) provides a solid foundation for basic OPC UA client-server applications with read/write/browse capabilities. The focus has been on correctness and memory safety over feature completeness.
