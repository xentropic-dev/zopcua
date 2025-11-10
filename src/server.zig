const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");
const types = @import("types.zig");
const ua_error = @import("ua_error.zig");
const VariableAttributes = @import("variable_attributes.zig").VariableAttributes;
const ObjectAttributes = @import("object_attributes.zig").ObjectAttributes;
const Variant = @import("variant.zig").Variant;
const LocalizedText = @import("localized_text.zig").LocalizedText;
const NodeId = @import("types.zig").NodeId;
const StandardNodeId = @import("types.zig").StandardNodeId;
const ReferenceType = @import("types.zig").ReferenceType;
const QualifiedName = @import("types.zig").QualifiedName;
const ServerConfig = @import("server_config.zig").ServerConfig;

/// Errors that can occur during namespace operations
pub const NamespaceError = error{
    /// The namespace URI is invalid or empty
    InvalidNamespaceUri,
    /// The namespace was not found
    NamespaceNotFound,
    /// Maximum namespaces exceeded (rare)
    TooManyNamespaces,
    /// Out of memory
    OutOfMemory,
    /// Internal server error
    InternalError,
};

/// Errors that can occur when adding a variable node
pub const AddNodeError = error{
    /// The requested NodeId already exists in the address space
    NodeIdExists,
    /// The parent NodeId is invalid or doesn't exist
    InvalidParentNodeId,
    /// The reference type is not allowed for this operation
    ReferenceNotAllowed,
    /// Type mismatch in attributes (e.g., wrong ValueRank for the data)
    TypeMismatch,
    /// The node class is invalid
    InvalidNodeClass,
    /// One or more node attributes are invalid
    InvalidNodeAttributes,
    /// The type definition NodeId is invalid or doesn't exist
    InvalidTypeDefinition,
    /// The browse name is invalid
    InvalidBrowseName,
    /// A node with this browse name already exists under the parent
    DuplicateBrowseName,
    /// The NodeId could not be found (internal error)
    NodeIdUnknown,
    /// Insufficient memory to complete the operation
    OutOfMemory,
    /// Too many operations requested
    TooManyOperations,
    /// An internal server error occurred
    InternalError,
    /// Unknown error from the OPC UA server
    Unknown,
    /// No space left on device (allocation error)
    NoSpaceLeft,
};

pub const Server = struct {
    handle: *c.UA_Server,

    /// Create a new server with a custom configuration.
    ///
    /// This allows full control over server settings including port, security,
    /// and other options. The server is created but not started.
    ///
    /// Example usage:
    /// ```zig
    /// var server = try Server.initWithConfig(.{ .port = 8080 });
    /// defer server.deinit();
    /// try server.start();
    /// // ... do work ...
    /// try server.stop();
    /// ```
    ///
    /// **Errors:**
    /// - `BadOutOfMemory` - Memory allocation failed during initialization
    /// - `BadInternalError` - Server creation or configuration failed
    pub fn initWithConfig(config: ServerConfig) !Server {
        // SAFETY: Immediately initialized to zero bytes by @memset on next line
        var c_config: c.UA_ServerConfig = undefined;
        @memset(std.mem.asBytes(&c_config), 0);

        // Use arena allocator for temporary C conversions
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();

        // Apply Zig config to C config
        try config.applyToC(arena.allocator(), &c_config);

        // Create server with the configured settings
        const server = c.UA_Server_newWithConfig(&c_config);
        if (server == null) return error.BadInternalError;

        return .{ .handle = server.? };
    }

    /// Create a new server with a default configuration that adds plugins for
    /// networking, security, logging and so on. The default configuration can
    /// be used as the starting point to adjust the server configuration to
    /// individual needs.
    ///
    /// The server is created but not started. Call `start()` to begin accepting connections.
    ///
    /// Typical usage:
    /// ```zig
    /// var server = try Server.init();
    /// defer server.deinit();
    /// try server.start();
    /// // ... do work ...
    /// try server.stop();
    /// ```
    ///
    /// **Errors:**
    /// - `BadOutOfMemory` - Memory allocation failed during initialization (event loop,
    ///   security policies, endpoints, access control, or server creation)
    /// - `BadInternalError` - Internal error during setup (event loop start failed,
    ///   epoll creation failed, invalid configuration, or server creation failed) pm
    pub fn init() !Server {
        // Use default configuration
        return initWithConfig(.{});
    }

    /// Cleans up and deallocates the server.
    ///
    /// **Important:** The server must be fully stopped (via `stop()`) before calling
    /// this function. Calling `deinit()` on a running server will leak resources.
    ///
    /// This function does not return errors as per Zig conventions for `deinit` methods,
    /// which must be usable in `defer` statements. The underlying `UA_Server_delete`
    /// can only fail if the server pointer is null (which cannot happen given our
    /// lifecycle management) or if the server is not stopped (which is the caller's
    /// responsibility to ensure).
    pub fn deinit(self: *Server) void {
        _ = c.UA_Server_delete(self.handle);
    }

    /// Starts the server, making it ready to accept connections.
    ///
    /// This initializes the server's internal state and begins listening on
    /// configured endpoints. After calling this, you must call `iterate()`
    /// repeatedly to process events, or use `runUntilInterrupt()` which handles
    /// the iteration loop automatically.
    ///
    /// Performs the following operations:
    /// - Starts the event loop (if not already started)
    /// - Verifies server configuration (certificates, endpoints, user tokens)
    /// - Adds housekeeping callback for maintenance tasks
    /// - Starts all server components
    /// - Sets server lifecycle state to STARTED
    ///
    /// Must be called after `init()` and before `iterate()` or `stop()`.
    ///
    /// **Errors:**
    /// - `BadInternalError` - Server startup failed (server already started, no event
    ///   loop configured, no user identity policies, binary protocol component failed,
    ///   certificate verification failed, or other initialization errors)
    pub fn start(self: *Server) error{BadInternalError}!void {
        const status = c.UA_Server_run_startup(self.handle);
        if (status != c.UA_STATUSCODE_GOOD) {
            return error.BadInternalError;
        }
    }

    /// Processes one iteration of the server's event loop.
    ///
    /// This method processes timed callbacks and network events for a single cycle.
    /// You must call this repeatedly (typically in a loop) to keep the server running.
    /// The server must be started via `start()` before calling this method.
    ///
    /// The `wait_internal` parameter controls blocking behavior:
    /// - `true`: Blocks until events occur or callbacks are due (recommended for most cases)
    /// - `false`: Returns immediately, allowing tight integration with custom event loops
    ///
    /// Returns the number of milliseconds until the next scheduled callback is due.
    /// This can be used to optimize polling intervals in custom event loops.
    ///
    /// Example usage:
    /// ```zig
    /// var server = try Server.init();
    /// defer server.deinit();
    /// try server.start();
    ///
    /// var running = true;
    /// while (running) {
    ///     _ = server.iterate(true);
    ///     // Check your shutdown condition
    ///     if (should_stop) running = false;
    /// }
    ///
    /// try server.stop();
    /// ```
    ///
    /// **Note:** This method does not return errors. The event loop handles errors internally.
    pub fn iterate(self: *Server, wait_internal: bool) u16 {
        return c.UA_Server_run_iterate(self.handle, wait_internal);
    }

    /// Stops the server gracefully, shutting down all running components.
    ///
    /// This performs an orderly shutdown by:
    /// - Stopping housekeeping tasks
    /// - Shutting down PubSub (if enabled)
    /// - Stopping all server components
    /// - Iterating the event loop until all components are stopped
    /// - Stopping the event loop (if not externally managed)
    ///
    /// **Important:** Must be called before `deinit()`. A typical usage pattern:
    /// ```zig
    /// var server = try Server.init();
    /// defer server.deinit();
    /// try server.start();
    /// // ... do work ...
    /// try server.stop();
    /// ```
    ///
    /// **Errors:**
    /// - `BadInternalError` - Server is not in a started state, the event loop is
    ///   in an invalid state, or the event loop encountered an error (such as
    ///   epoll failure) during shutdown iteration
    pub fn stop(self: *Server) error{BadInternalError}!void {
        const status = c.UA_Server_run_shutdown(self.handle);
        if (status != c.UA_STATUSCODE_GOOD) {
            return error.BadInternalError;
        }
    }

    /// Convenience method that runs the server until receiving SIGINT (Ctrl-C).
    ///
    /// This method blocks until interrupted and handles the complete server lifecycle:
    /// - Registers interrupt handler for SIGINT
    /// - Starts the server (`UA_Server_run_startup`)
    /// - Runs the event loop until interrupted (`UA_Server_run_iterate`)
    /// - Shuts down the server (`UA_Server_run_shutdown`)
    /// - Deregisters the interrupt handler
    ///
    /// **Use this when:** Building a simple, standalone server application that should
    /// run until the user presses Ctrl-C.
    ///
    /// **Use explicit lifecycle methods when:** You need programmatic control over
    /// server lifetime, non-blocking operation, custom shutdown logic, or integration
    /// with other systems.
    ///
    /// Example usage:
    /// ```zig
    /// var server = try Server.init();
    /// defer server.deinit();
    /// try server.runUntilInterrupt(); // Blocks here until Ctrl-C
    /// ```
    ///
    /// **Note:** This method is implemented differently per platform (POSIX/Windows).
    ///
    /// **Errors:**
    /// - `BadInternalError` - Server startup failed (invalid state, no event loop,
    ///   configuration errors, binary protocol component failure), or shutdown failed
    pub fn runUntilInterrupt(self: *Server) error{BadInternalError}!void {
        const status = c.UA_Server_runUntilInterrupt(self.handle);
        if (status != c.UA_STATUSCODE_GOOD) {
            return error.BadInternalError;
        }
    }

    /// Add a variable node to the OPC UA server
    ///
    /// Creates a new variable node in the server's address space with the specified
    /// attributes and relationships.
    ///
    /// Parameters:
    ///   - node_id: The desired NodeId for the new variable. Use NodeId.initNumeric()
    ///              or NodeId.initString() to create. The server may assign a different
    ///              ID if this one is already in use.
    ///   - parent_node_id: The NodeId of the parent node (e.g., StandardNodeId.objects_folder)
    ///   - parent_ref_node_id: The reference type connecting to parent (e.g., ReferenceType.organizes)
    ///   - name: The qualified name (browse name) for the variable
    ///   - type_definition: The type definition NodeId (e.g., StandardNodeId.base_data_variable_type)
    ///   - attrs: Variable attributes including value, display name, description, etc.
    ///
    /// Returns:
    ///   - The actual NodeId assigned by the server (may differ from requested node_id)
    ///
    /// Errors:
    ///   - NodeIdExists: The requested NodeId is already in use
    ///   - InvalidParentNodeId: The parent node doesn't exist
    ///   - TypeMismatch: The value doesn't match the declared type (check value_rank and array_dimensions!)
    ///   - InvalidTypeDefinition: The type definition node doesn't exist
    ///   - OutOfMemory: Allocation failed during conversion
    ///   - (see AddNodeError for complete list)
    ///
    /// Examples:
    /// Scalar variable:
    /// ```zig
    /// const temp_node = try server.addVariableNode(
    ///     NodeId.initString(1, "temperature"),
    ///     StandardNodeId.objects_folder,
    ///     ReferenceType.organizes,
    ///     QualifiedName.init(1, "Temperature"),
    ///     StandardNodeId.base_data_variable_type,
    ///     .{
    ///         .value = Variant.scalar(f64, 23.5),
    ///         .display_name = LocalizedText.init("en-US", "Temperature"),
    ///         .description = LocalizedText.initText("Current temperature in Celsius"),
    ///         .access_level = .{ .read = true, .write = true },
    ///         // value_rank defaults to -1 (scalar), data_type is auto-inferred
    ///     },
    /// );
    /// ```
    ///
    /// Array variable:
    /// ```zig
    /// const measurements = [_]f64{ 10.1, 20.2, 30.3, 40.4, 50.5 };
    /// const array_dims = [_]u32{5};
    /// const array_node = try server.addVariableNode(
    ///     NodeId.initString(1, "measurements"),
    ///     StandardNodeId.objects_folder,
    ///     ReferenceType.organizes,
    ///     QualifiedName.init(1, "Measurements"),
    ///     StandardNodeId.base_data_variable_type,
    ///     .{
    ///         .value = Variant.array(f64, &measurements),
    ///         .display_name = LocalizedText.init("en-US", "Measurements"),
    ///         .access_level = .{ .read = true },
    ///         .value_rank = 1, // One-dimensional array
    ///         .array_dimensions = &array_dims, // Must match value_rank
    ///     },
    /// );
    /// ```
    pub fn addVariableNode(
        self: *Server,
        node_id: NodeId,
        parent_node_id: NodeId,
        parent_ref_node_id: NodeId,
        name: QualifiedName,
        type_definition: NodeId,
        attrs: VariableAttributes,
    ) AddNodeError!NodeId {
        // Use internal arena for temporary C conversions
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();

        const arena_allocator = arena.allocator();

        // Convert to C types
        const c_attrs = attrs.toC(arena_allocator) catch return AddNodeError.OutOfMemory;

        // SAFETY: out_node_id is written to by UA_Server_addVariableNode before being read
        var out_node_id: c.UA_NodeId = undefined;

        // Convert NodeIds and QualifiedName to C representation
        const c_node_id = try node_id.toC(arena_allocator);
        const c_parent_node_id = try parent_node_id.toC(arena_allocator);
        const c_parent_ref_node_id = try parent_ref_node_id.toC(arena_allocator);
        const c_name = try name.toC(arena_allocator);
        const c_type_definition = try type_definition.toC(arena_allocator);

        const status = c.UA_Server_addVariableNode(
            self.handle,
            c_node_id,
            c_parent_node_id,
            c_parent_ref_node_id,
            c_name,
            c_type_definition,
            c_attrs,
            null, // nodeContext
            &out_node_id,
        );

        // Map status codes to specific errors
        return switch (status) {
            c.UA_STATUSCODE_GOOD => NodeId.fromC(out_node_id),
            c.UA_STATUSCODE_BADNODEIDEXISTS => AddNodeError.NodeIdExists,
            c.UA_STATUSCODE_BADPARENTNODEIDINVALID => AddNodeError.InvalidParentNodeId,
            c.UA_STATUSCODE_BADREFERENCENOTALLOWED => AddNodeError.ReferenceNotAllowed,
            c.UA_STATUSCODE_BADTYPEMISMATCH => AddNodeError.TypeMismatch,
            c.UA_STATUSCODE_BADNODECLASSINVALID => AddNodeError.InvalidNodeClass,
            c.UA_STATUSCODE_BADNODEATTRIBUTESINVALID => AddNodeError.InvalidNodeAttributes,
            c.UA_STATUSCODE_BADTYPEDEFINITIONINVALID => AddNodeError.InvalidTypeDefinition,
            c.UA_STATUSCODE_BADBROWSENAMEINVALID => AddNodeError.InvalidBrowseName,
            c.UA_STATUSCODE_BADBROWSENAMEDUPLICATED => AddNodeError.DuplicateBrowseName,
            c.UA_STATUSCODE_BADNODEIDUNKNOWN => AddNodeError.NodeIdUnknown,
            c.UA_STATUSCODE_BADOUTOFMEMORY => AddNodeError.OutOfMemory,
            c.UA_STATUSCODE_BADTOOMANYOPERATIONS => AddNodeError.TooManyOperations,
            c.UA_STATUSCODE_BADINTERNALERROR => AddNodeError.InternalError,
            else => AddNodeError.Unknown,
        };
    }

    /// Add an object node to the OPC UA server
    ///
    /// Creates a new object node in the server's address space. Object nodes serve as
    /// containers for organizing other nodes (variables, methods, other objects) and
    /// represent physical or logical objects in the system.
    ///
    /// Parameters:
    ///   - node_id: The desired NodeId for the new object. Use NodeId.initNumeric()
    ///              or NodeId.initString() to create. The server may assign a different
    ///              ID if this one is already in use.
    ///   - parent_node_id: The NodeId of the parent node (e.g., StandardNodeId.objects_folder)
    ///   - parent_ref_node_id: The reference type connecting to parent (e.g., ReferenceType.organizes)
    ///   - name: The qualified name (browse name) for the object
    ///   - type_definition: The type definition NodeId (e.g., StandardNodeId.base_object_type)
    ///   - attrs: Object attributes including display name, description, event notifier
    ///
    /// Returns:
    ///   - The actual NodeId assigned by the server (may differ from requested node_id)
    ///
    /// Errors:
    ///   - NodeIdExists: The requested NodeId is already in use
    ///   - InvalidParentNodeId: The parent node doesn't exist
    ///   - InvalidTypeDefinition: The type definition node doesn't exist
    ///   - OutOfMemory: Allocation failed during conversion
    ///   - (see AddNodeError for complete list)
    ///
    /// Example:
    /// ```zig
    /// // Create a "Sensors" folder object to organize sensor variables
    /// const sensors_folder = try server.addObjectNode(
    ///     NodeId.initString(1, "sensors"),
    ///     StandardNodeId.objects_folder,
    ///     ReferenceType.organizes,
    ///     QualifiedName.init(1, "Sensors"),
    ///     StandardNodeId.folder_type,
    ///     .{
    ///         .display_name = LocalizedText.init("en-US", "Sensors"),
    ///         .description = LocalizedText.initText("Folder containing all sensor nodes"),
    ///     },
    /// );
    ///
    /// // Now add variables under the sensors folder
    /// _ = try server.addVariableNode(
    ///     allocator,
    ///     NodeId.initString(1, "temperature"),
    ///     sensors_folder,  // parent is the sensors folder
    ///     ReferenceType.has_component,
    ///     QualifiedName.init(1, "Temperature"),
    ///     StandardNodeId.base_data_variable_type,
    ///     .{
    ///         .value = Variant.scalar(f64, 23.5),
    ///         .display_name = LocalizedText.init("en-US", "Temperature"),
    ///         .access_level = .{ .read = true },
    ///     },
    /// );
    /// ```
    pub fn addObjectNode(
        self: *Server,
        node_id: NodeId,
        parent_node_id: NodeId,
        parent_ref_node_id: NodeId,
        name: QualifiedName,
        type_definition: NodeId,
        attrs: ObjectAttributes,
    ) AddNodeError!NodeId {
        // Use internal arena for temporary C conversions
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();

        const arena_allocator = arena.allocator();

        // Convert to C types
        const c_attrs = attrs.toC();

        // SAFETY: out_node_id is written to by UA_Server_addObjectNode before being read
        var out_node_id: c.UA_NodeId = undefined;

        // Convert NodeIds and QualifiedName to C representation
        const c_node_id = try node_id.toC(arena_allocator);
        const c_parent_node_id = try parent_node_id.toC(arena_allocator);
        const c_parent_ref_node_id = try parent_ref_node_id.toC(arena_allocator);
        const c_name = try name.toC(arena_allocator);
        const c_type_definition = try type_definition.toC(arena_allocator);

        const status = c.UA_Server_addObjectNode(
            self.handle,
            c_node_id,
            c_parent_node_id,
            c_parent_ref_node_id,
            c_name,
            c_type_definition,
            c_attrs,
            null, // nodeContext
            &out_node_id,
        );

        // Map status codes to specific errors
        return switch (status) {
            c.UA_STATUSCODE_GOOD => NodeId.fromC(out_node_id),
            c.UA_STATUSCODE_BADNODEIDEXISTS => AddNodeError.NodeIdExists,
            c.UA_STATUSCODE_BADPARENTNODEIDINVALID => AddNodeError.InvalidParentNodeId,
            c.UA_STATUSCODE_BADREFERENCENOTALLOWED => AddNodeError.ReferenceNotAllowed,
            c.UA_STATUSCODE_BADTYPEMISMATCH => AddNodeError.TypeMismatch,
            c.UA_STATUSCODE_BADNODECLASSINVALID => AddNodeError.InvalidNodeClass,
            c.UA_STATUSCODE_BADNODEATTRIBUTESINVALID => AddNodeError.InvalidNodeAttributes,
            c.UA_STATUSCODE_BADTYPEDEFINITIONINVALID => AddNodeError.InvalidTypeDefinition,
            c.UA_STATUSCODE_BADBROWSENAMEINVALID => AddNodeError.InvalidBrowseName,
            c.UA_STATUSCODE_BADBROWSENAMEDUPLICATED => AddNodeError.DuplicateBrowseName,
            c.UA_STATUSCODE_BADNODEIDUNKNOWN => AddNodeError.NodeIdUnknown,
            c.UA_STATUSCODE_BADOUTOFMEMORY => AddNodeError.OutOfMemory,
            c.UA_STATUSCODE_BADTOOMANYOPERATIONS => AddNodeError.TooManyOperations,
            c.UA_STATUSCODE_BADINTERNALERROR => AddNodeError.InternalError,
            else => AddNodeError.Unknown,
        };
    }

    /// Add a new namespace to the server.
    ///
    /// Namespaces allow organizing nodes into logical groups and avoiding naming conflicts.
    /// The server starts with two pre-defined namespaces:
    /// - Index 0: "http://opcfoundation.org/UA/" (OPC UA standard namespace)
    /// - Index 1: "urn:open62541:server:default" (server's default namespace)
    ///
    /// New namespaces are assigned sequential indices starting from 2.
    ///
    /// **Important**: Namespaces must be added before `start()` is called. Adding namespaces
    /// after startup may cause undefined behavior.
    ///
    /// Parameters:
    ///   - namespace_uri: URI string identifying the namespace (e.g., "http://example.com/myapp")
    ///
    /// Returns:
    ///   - The assigned namespace index (u16), typically 2 or higher
    ///
    /// Errors:
    ///   - `InvalidNamespaceUri`: Empty or null URI
    ///   - `TooManyNamespaces`: Exceeded maximum namespace count (very rare)
    ///   - `OutOfMemory`: Allocation failed
    ///
    /// Example:
    /// ```zig
    /// var server = try Server.init();
    /// defer server.deinit();
    ///
    /// const ns_idx = try server.addNamespace("http://example.com/sensors");
    /// // ns_idx will be 2 (first custom namespace)
    ///
    /// // Now use ns_idx when creating nodes:
    /// const node = try server.addVariableNode(
    ///     allocator,
    ///     NodeId.initString(ns_idx, "temperature"),
    ///     // ... other params
    /// );
    /// ```
    pub fn addNamespace(
        self: *Server,
        namespace_uri: []const u8,
    ) NamespaceError!u16 {
        // Validation
        if (namespace_uri.len == 0) return NamespaceError.InvalidNamespaceUri;

        // Use internal arena for temporary C string conversion
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();

        // Convert to null-terminated C string
        const c_uri = arena.allocator().allocSentinel(u8, namespace_uri.len, 0) catch {
            return NamespaceError.OutOfMemory;
        };
        @memcpy(c_uri, namespace_uri);

        // Call C API
        const index = c.UA_Server_addNamespace(self.handle, c_uri.ptr);

        // Check for failure (C API returns 0 on error for user namespaces)
        // Note: 0 is valid for standard namespace, but addNamespace never returns 0 for new namespaces
        if (index == 0) return NamespaceError.InternalError;

        return index;
    }

    /// Get the namespace index for a given URI.
    ///
    /// Searches the server's namespace table for a matching URI and returns its index.
    ///
    /// Parameters:
    ///   - namespace_uri: URI string to search for
    ///
    /// Returns:
    ///   - The namespace index if found
    ///
    /// Errors:
    ///   - `NamespaceNotFound`: No namespace with this URI exists
    ///   - `InvalidNamespaceUri`: Empty or null URI
    ///
    /// Example:
    /// ```zig
    /// const idx = try server.getNamespaceByName("http://opcfoundation.org/UA/");
    /// // idx will be 0 (standard namespace)
    /// ```
    pub fn getNamespaceByName(
        self: *Server,
        namespace_uri: []const u8,
    ) NamespaceError!u16 {
        if (namespace_uri.len == 0) return NamespaceError.InvalidNamespaceUri;

        // Convert URI to UA_String
        const c_uri = c.UA_String{
            .length = namespace_uri.len,
            .data = @constCast(namespace_uri.ptr),
        };

        var found_index: usize = 0;
        const status = c.UA_Server_getNamespaceByName(
            self.handle,
            c_uri,
            &found_index,
        );

        return switch (status) {
            c.UA_STATUSCODE_GOOD => @intCast(found_index),
            c.UA_STATUSCODE_BADNOTFOUND => NamespaceError.NamespaceNotFound,
            c.UA_STATUSCODE_BADOUTOFMEMORY => NamespaceError.OutOfMemory,
            else => NamespaceError.InternalError,
        };
    }

    /// Get the namespace URI for a given index.
    ///
    /// Retrieves the URI string associated with a namespace index. The returned
    /// string is owned by the caller and must be freed using the provided allocator.
    ///
    /// Parameters:
    ///   - allocator: Memory allocator for the returned string
    ///   - namespace_index: Index to look up (0 = standard OPC UA namespace)
    ///
    /// Returns:
    ///   - Owned string containing the namespace URI (caller must free)
    ///
    /// Errors:
    ///   - `NamespaceNotFound`: Index out of range or doesn't exist
    ///   - `OutOfMemory`: Allocation failed
    ///
    /// Example:
    /// ```zig
    /// const uri = try server.getNamespaceByIndex(allocator, 0);
    /// defer allocator.free(uri);
    /// // uri will be "http://opcfoundation.org/UA/"
    /// ```
    pub fn getNamespaceByIndex(
        self: *Server,
        allocator: std.mem.Allocator,
        namespace_index: u16,
    ) NamespaceError![]const u8 {
        // SAFETY: foundUri is initialized by UA_Server_getNamespaceByIndex
        var found_uri: c.UA_String = undefined;

        const status = c.UA_Server_getNamespaceByIndex(
            self.handle,
            @intCast(namespace_index),
            &found_uri,
        );

        if (status != c.UA_STATUSCODE_GOOD) {
            return switch (status) {
                c.UA_STATUSCODE_BADNOTFOUND => NamespaceError.NamespaceNotFound,
                c.UA_STATUSCODE_BADOUTOFMEMORY => NamespaceError.OutOfMemory,
                else => NamespaceError.InternalError,
            };
        }

        // Copy the string data (C API owns the original)
        const slice = if (found_uri.data) |data|
            data[0..found_uri.length]
        else
            return NamespaceError.InternalError;

        return allocator.dupe(u8, slice);
    }
};

test "Server.addNamespace basic functionality" {
    const testing = std.testing;
    std.testing.refAllDecls(@This());

    var server = try Server.init();
    defer server.deinit();

    // First custom namespace should be index 2
    const idx1 = try server.addNamespace("http://example.com/test");
    try testing.expectEqual(@as(u16, 2), idx1);

    // Second should be index 3
    const idx2 = try server.addNamespace("http://example.com/other");
    try testing.expectEqual(@as(u16, 3), idx2);
}

test "Server.addNamespace rejects empty URI" {
    const testing = std.testing;

    var server = try Server.init();
    defer server.deinit();

    const result = server.addNamespace("");
    try testing.expectError(NamespaceError.InvalidNamespaceUri, result);
}

test "Server.getNamespaceByName finds standard namespace" {
    const testing = std.testing;

    var server = try Server.init();
    defer server.deinit();

    const idx = try server.getNamespaceByName("http://opcfoundation.org/UA/");
    try testing.expectEqual(@as(u16, 0), idx);
}

test "Server.getNamespaceByName finds custom namespace" {
    const testing = std.testing;

    var server = try Server.init();
    defer server.deinit();

    const added_idx = try server.addNamespace("http://example.com/test");
    const found_idx = try server.getNamespaceByName("http://example.com/test");
    try testing.expectEqual(added_idx, found_idx);
}

test "Server.getNamespaceByName returns error for unknown namespace" {
    const testing = std.testing;

    var server = try Server.init();
    defer server.deinit();

    const result = server.getNamespaceByName("http://nonexistent.com/");
    try testing.expectError(NamespaceError.NamespaceNotFound, result);
}

test "Server.getNamespaceByIndex retrieves standard namespace" {
    const testing = std.testing;

    var server = try Server.init();
    defer server.deinit();

    const uri = try server.getNamespaceByIndex(testing.allocator, 0);
    defer testing.allocator.free(uri);

    try testing.expectEqualStrings("http://opcfoundation.org/UA/", uri);
}

test "Server.getNamespaceByIndex retrieves custom namespace" {
    const testing = std.testing;

    var server = try Server.init();
    defer server.deinit();

    const test_uri = "http://example.com/custom";
    const idx = try server.addNamespace(test_uri);

    const retrieved_uri = try server.getNamespaceByIndex(testing.allocator, idx);
    defer testing.allocator.free(retrieved_uri);

    try testing.expectEqualStrings(test_uri, retrieved_uri);
}

test "Server.getNamespaceByIndex returns error for invalid index" {
    const testing = std.testing;

    var server = try Server.init();
    defer server.deinit();

    const result = server.getNamespaceByIndex(testing.allocator, 999);
    try testing.expectError(NamespaceError.NamespaceNotFound, result);
}

test "Server.addObjectNode basic functionality" {
    const testing = std.testing;

    var server = try Server.init();
    defer server.deinit();

    // Create a basic folder object
    const folder = try server.addObjectNode(
        NodeId.initString(1, "my_folder"),
        StandardNodeId.objects_folder,
        ReferenceType.organizes,
        QualifiedName.init(1, "MyFolder"),
        StandardNodeId.folder_type,
        .{
            .display_name = LocalizedText.init("en-US", "My Folder"),
            .description = LocalizedText.initText("A test folder"),
        },
    );

    // Verify we got a NodeId back
    try testing.expectEqual(@as(u16, 1), folder.namespace);
}

test "Server.addObjectNode with nested variable" {
    const testing = std.testing;

    var server = try Server.init();
    defer server.deinit();

    // Create a "Sensors" folder object
    const sensors_folder = try server.addObjectNode(
        NodeId.initString(1, "sensors"),
        StandardNodeId.objects_folder,
        ReferenceType.organizes,
        QualifiedName.init(1, "Sensors"),
        StandardNodeId.folder_type,
        .{
            .display_name = LocalizedText.init("en-US", "Sensors"),
            .description = LocalizedText.initText("Folder containing all sensor nodes"),
        },
    );

    // Add a temperature variable under the sensors folder
    const temp_var = try server.addVariableNode(
        NodeId.initString(1, "temperature"),
        sensors_folder, // parent is the sensors folder
        ReferenceType.has_component,
        QualifiedName.init(1, "Temperature"),
        StandardNodeId.base_data_variable_type,
        .{
            .value = Variant.scalar(f64, 23.5),
            .display_name = LocalizedText.init("en-US", "Temperature"),
            .access_level = .{ .read = true },
        },
    );

    // Verify both nodes were created
    try testing.expectEqual(@as(u16, 1), sensors_folder.namespace);
    try testing.expectEqual(@as(u16, 1), temp_var.namespace);
}

test "Server.addObjectNode rejects duplicate NodeId" {
    const testing = std.testing;

    var server = try Server.init();
    defer server.deinit();

    // Create first object
    _ = try server.addObjectNode(
        NodeId.initString(1, "duplicate"),
        StandardNodeId.objects_folder,
        ReferenceType.organizes,
        QualifiedName.init(1, "First"),
        StandardNodeId.folder_type,
        .{
            .display_name = LocalizedText.init("en-US", "First"),
        },
    );

    // Try to create another with same NodeId
    const result = server.addObjectNode(
        NodeId.initString(1, "duplicate"),
        StandardNodeId.objects_folder,
        ReferenceType.organizes,
        QualifiedName.init(1, "Second"),
        StandardNodeId.folder_type,
        .{
            .display_name = LocalizedText.init("en-US", "Second"),
        },
    );

    try testing.expectError(AddNodeError.NodeIdExists, result);
}
