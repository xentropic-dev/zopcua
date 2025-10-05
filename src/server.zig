const std = @import("std");
const c = @import("c.zig");
const helpers = @import("helpers.zig");
const types = @import("types.zig");
const ua_error = @import("ua_error.zig");
const VariableAttributes = @import("variable_attributes.zig").VariableAttributes;
const Variant = @import("variant.zig").Variant;
const LocalizedText = @import("localized_text.zig").LocalizedText;
const NodeId = @import("types.zig").NodeId;
const QualifiedName = @import("types.zig").QualifiedName;

pub const Server = struct {
    handle: *c.UA_Server,

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
        const result = helpers.UA_Server_newDefaultWithStatus();
        if (result.status == c.UA_STATUSCODE_BADOUTOFMEMORY) {
            return error.BadOutOfMemory;
        }

        if (result.status != c.UA_STATUSCODE_GOOD) {
            return error.BadInternalError;
        }
        return .{ .handle = result.server.? };
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

    //     UA_VariableAttributes attr = UA_VariableAttributes_default;
    // UA_Int32 myInteger = 42;
    // UA_Variant_setScalar(&attr.value, &myInteger, &UA_TYPES[UA_TYPES_INT32]);
    // attr.description = UA_LOCALIZEDTEXT("en-US", "the answer");
    // attr.displayName = UA_LOCALIZEDTEXT("en-US", "the answer");
    // attr.dataType = UA_TYPES[UA_TYPES_INT32].typeId;
    // attr.accessLevel = UA_ACCESSLEVELMASK_READ | UA_ACCESSLEVELMASK_WRITE;
    //
    // /* Add the variable node to the information model */
    // UA_NodeId parentNodeId = UA_NODEID_NUMERIC(0, UA_NS0ID_OBJECTSFOLDER);
    // UA_NodeId parentReferenceNodeId = UA_NODEID_NUMERIC(0, UA_NS0ID_ORGANIZES);
    // UA_Server_addVariableNode(server, myIntegerNodeId, parentNodeId,
    //                           parentReferenceNodeId, myIntegerName,
    //                           UA_NODEID_NUMERIC(0, UA_NS0ID_BASEDATAVARIABLETYPE),
    //                           attr, NULL, NULL);
    pub fn addVariable(self: *Server, allocator: std.mem.Allocator) !NodeId {
        const attrs = VariableAttributes{
            .value = Variant.scalar(i32, 42),
            .description = LocalizedText.init("en-US", "the answer"),
            .display_name = LocalizedText.init("en-US", "the answer"),
            .data_type = NodeId.initNumeric(0, c.UA_TYPES[c.UA_TYPES_INT32].typeId.identifier.numeric),
            .access_level = .{ .read = true, .write = true },
        };

        const integer_node_id = NodeId.initString(1, "the.answer");
        const integer_name = QualifiedName.init(1, "the answer");
        const parent_node_id = NodeId.initNumeric(0, c.UA_NS0ID_OBJECTSFOLDER);
        const parent_ref_node_id = NodeId.initNumeric(0, c.UA_NS0ID_ORGANIZES);
        const type_definition = NodeId.initNumeric(0, c.UA_NS0ID_BASEDATAVARIABLETYPE);

        // Convert to C types
        const c_attrs = try attrs.toC(allocator);
        defer {
            Variant.freeCVariant(c_attrs.value, allocator);
            if (c_attrs.arrayDimensionsSize > 0) {
                allocator.free(c_attrs.arrayDimensions[0..c_attrs.arrayDimensionsSize]);
            }
        }

        var out_node_id: c.UA_NodeId = undefined;
        const status = c.UA_Server_addVariableNode(
            self.handle,
            integer_node_id.toC(),
            parent_node_id.toC(),
            parent_ref_node_id.toC(),
            integer_name.toC(),
            type_definition.toC(),
            c_attrs,
            null, // nodeContext
            &out_node_id,
        );

        if (status != c.UA_STATUSCODE_GOOD) {
            return error.AddVariableNodeFailed;
        }

        return NodeId.fromC(out_node_id);
    }
};
