const std = @import("std");

pub const c = @import("c.zig");
pub const helpers = @import("helpers.zig");
pub const ua_error = @import("ua_error.zig");

const types_module = @import("types.zig");
const variant_module = @import("variant.zig");
const variable_attributes_module = @import("variable_attributes.zig");
const object_attributes_module = @import("object_attributes.zig");
const localized_text_module = @import("localized_text.zig");
const data_value_module = @import("data_value.zig");
const attributes_module = @import("attributes.zig");
const standard_data_types_module = @import("standard_data_types.zig");
const server_module = @import("server.zig");
const client_module = @import("client.zig");
const server_config_module = @import("server_config.zig");
const client_config_module = @import("client_config.zig");
const browse_module = @import("browse.zig");
const subscription_module = @import("subscription.zig");

pub const Server = server_module.Server;
pub const ServerConfig = server_config_module.ServerConfig;

pub const Client = client_module.Client;
pub const ClientConfig = client_config_module.ClientConfig;

pub const SecurityMode = server_config_module.SecurityMode;

pub const NodeId = types_module.NodeId;
pub const ExpandedNodeId = types_module.ExpandedNodeId;
pub const QualifiedName = types_module.QualifiedName;
pub const Guid = types_module.Guid;
pub const String = types_module.String;
pub const BrowseDirection = types_module.BrowseDirection;
pub const NodeClass = types_module.NodeClass;

pub const StandardNodeId = types_module.StandardNodeId;
pub const ReferenceType = types_module.ReferenceType;

pub const Variant = variant_module.Variant;
pub const DataValue = data_value_module.DataValue;

pub const VariableAttributes = variable_attributes_module.VariableAttributes;
pub const AccessLevel = variable_attributes_module.AccessLevel;
pub const AttributeWriteMask = variable_attributes_module.AttributeWriteMask;

pub const ObjectAttributes = object_attributes_module.ObjectAttributes;
pub const EventNotifier = object_attributes_module.EventNotifier;

pub const LocalizedText = localized_text_module.LocalizedText;

pub const AttributeId = attributes_module.AttributeId;
pub const AttributeValue = attributes_module.AttributeValue;

pub const StandardDataType = standard_data_types_module.StandardDataType;
pub const getDataTypeName = standard_data_types_module.getDataTypeName;

pub const AddNodeError = server_module.AddNodeError;
pub const NamespaceError = server_module.NamespaceError;
pub const BrowseError = client_module.BrowseError;
pub const SubscriptionError = client_module.SubscriptionError;
pub const MonitoredItemError = client_module.MonitoredItemError;

pub const SubscriptionParameters = subscription_module.SubscriptionParameters;
pub const SubscriptionId = subscription_module.SubscriptionId;
pub const MonitoredItemParameters = subscription_module.MonitoredItemParameters;
pub const MonitoredItemId = subscription_module.MonitoredItemId;
pub const MonitoringMode = subscription_module.MonitoringMode;
pub const DataChangeCallback = subscription_module.DataChangeCallback;

pub const BrowseDescription = browse_module.BrowseDescription;
pub const BrowseResult = browse_module.BrowseResult;
pub const ReferenceDescription = browse_module.ReferenceDescription;
pub const NodeClassMask = browse_module.NodeClassMask;
pub const BrowseResultMask = browse_module.BrowseResultMask;

pub const types = types_module;
pub const variant = variant_module;
pub const server = server_module;
pub const client = client_module;
pub const browse = browse_module;
pub const subscription = subscription_module;
pub const attributes = attributes_module;
pub const standard_data_types = standard_data_types_module;

test {
    _ = @import("ua_error.zig");
    _ = @import("variant.zig");
    _ = @import("variable_attributes.zig");
    _ = @import("object_attributes.zig");
    _ = @import("event_notifier.zig");
    _ = @import("types.zig");
    _ = @import("server_config.zig");
    _ = @import("client_config.zig");
    _ = @import("browse.zig");
    _ = @import("subscription.zig");
    _ = @import("data_value.zig");
    _ = @import("attributes.zig");
    _ = @import("standard_data_types.zig");
}
