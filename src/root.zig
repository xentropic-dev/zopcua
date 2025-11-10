const std = @import("std");

pub const c = @import("c.zig");
pub const helpers = @import("helpers.zig");
pub const ua_error = @import("ua_error.zig");

const types_module = @import("types.zig");
const variant_module = @import("variant.zig");
const variable_attributes_module = @import("variable_attributes.zig");
const localized_text_module = @import("localized_text.zig");
const server_module = @import("server.zig");
const client_module = @import("client.zig");
const server_config_module = @import("server_config.zig");
const client_config_module = @import("client_config.zig");

pub const Server = server_module.Server;
pub const ServerConfig = server_config_module.ServerConfig;

pub const Client = client_module.Client;
pub const ClientConfig = client_config_module.ClientConfig;

pub const SecurityMode = server_config_module.SecurityMode;

pub const NodeId = types_module.NodeId;
pub const QualifiedName = types_module.QualifiedName;
pub const Guid = types_module.Guid;
pub const String = types_module.String;

pub const StandardNodeId = types_module.StandardNodeId;
pub const ReferenceType = types_module.ReferenceType;

pub const Variant = variant_module.Variant;

pub const VariableAttributes = variable_attributes_module.VariableAttributes;
pub const AccessLevel = variable_attributes_module.AccessLevel;

pub const LocalizedText = localized_text_module.LocalizedText;

pub const AddNodeError = server_module.AddNodeError;

pub const types = types_module;
pub const variant = variant_module;
pub const server = server_module;
pub const client = client_module;

test {
    _ = @import("ua_error.zig");
    _ = @import("variant.zig");
    _ = @import("variable_attributes.zig");
    _ = @import("types.zig");
    _ = @import("server_config.zig");
    _ = @import("client_config.zig");
}
