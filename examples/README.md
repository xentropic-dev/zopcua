# zopcua Examples

Progressive examples demonstrating OPC UA client and server usage with zopcua.

## 📚 Getting Started

Start with the minimal examples to understand the basics, then progress to more advanced usage.

## 🖥️ Server Examples

### [server-minimal](./server-minimal/)
**The simplest possible server** - 7 lines of code

```bash
cd server-minimal && zig build run
```

Perfect first example showing:
- How to create and start a server with `runUntilInterrupt()`
- Default configuration and graceful shutdown

---

### [server-simple](./server-simple/)
**Server with one variable** - Adding your first data

```bash
cd server-simple && zig build run
```

Learn how to:
- Add a single variable to the address space
- Set display names, descriptions, and access levels
- Use `NodeId` and `Variant` types

---

### [server-advanced](./server-advanced/)
**Multiple variables with custom event loop** - Full control

```bash
cd server-advanced && zig build run
```

Demonstrates:
- Manual event loop control with `start()` and `iterate()`
- Custom signal handlers
- Multiple variable types (integers, floats, strings, booleans, arrays)
- When and why you'd need manual loop control

## 🔌 Client Examples

### [client-minimal](./client-minimal/)
**The simplest possible client** - Just connect and disconnect

```bash
cd client-minimal && zig build run
```

Perfect first example showing:
- Basic connection lifecycle
- Proper resource cleanup with `defer`

---

### [client-read](./client-read/)
**Read variable values** - Getting data from a server

```bash
cd client-read && zig build run
```

Learn how to:
- Create NodeIds with `initString()`, `initNumeric()`, etc.
- Read variable values with `readValueAttribute()`
- Handle different data types with `Variant`

---

### [client-write](./client-write/)
**Write variable values** - Modifying server data

```bash
cd client-write && zig build run -- 100
```

Demonstrates:
- Writing values to server variables
- Creating `Variant` values
- Confirming writes by reading back
- Error handling for write operations

---

### [client-server](./client-server/)
**Client and server in one process** - Complete integration example

```bash
cd client-server && zig build run
```

Demonstrates:
- Running server in a background thread
- Client operations on the local server
- Read-write-read workflow in a single process
- Useful for testing, demos, and embedded applications

## 🚀 Quick Start Guide

### 1. Hello World - Server

```bash
cd server-minimal
zig build run
```

### 2. Hello World - Client

Open a second terminal:

```bash
cd client-minimal
zig build run
```

### 3. Read/Write Data

Start the simple server:
```bash
cd server-simple
zig build run
```

In another terminal, read a value:
```bash
cd client-read
zig build run
```

Write a new value:
```bash
cd client-write
zig build run -- 999
```

## 📖 Learning Path

**Complete Beginner:**
1. `server-minimal` - See a server in action
2. `client-minimal` - Connect to it
3. `server-simple` - Add data to your server
4. `client-read` - Read that data

**Ready for More:**
5. `client-write` - Modify server data
6. `server-advanced` - Multiple variables and custom loops
7. `client-server` - See everything working together in one process

## 🎯 Example Matrix

| Example | Lines of Code | Concepts |
|---------|---------------|----------|
| server-minimal | ~7 | Server basics, `runUntilInterrupt()` |
| server-simple | ~30 | Adding variables, `Variant`, `NodeId` |
| server-advanced | ~180 | Manual loop, signal handling, multiple types |
| client-minimal | ~15 | Connection lifecycle |
| client-read | ~30 | Reading values, creating NodeIds |
| client-write | ~50 | Writing values, creating Variants, confirmation |
| client-server | ~100 | Threading, combined client/server, integration |

## 🛠️ Building All Examples

From this directory:

```bash
# Build all examples
for dir in */; do
    (cd "$dir" && echo "Building $dir..." && zig build)
done
```

## 📝 Tips

- All examples use standard error handling with `try`
- Memory is managed with `defer` for automatic cleanup
- Servers run on `opc.tcp://localhost:4840` by default
- NodeIds in server-simple and server-advanced use namespace 1 (`ns=1`)

## 🤝 Integration Testing

**Option 1: Separate processes**
1. Start any server example in one terminal
2. Run client examples in another terminal pointing to `opc.tcp://localhost:4840`
3. Use the NodeIds documented in each server's README

**Option 2: Single process**
- Run the `client-server` example to see both in action together

## 💡 Next Steps

- Check each example's README for detailed explanations
- Modify the examples to experiment
- Try connecting with other OPC UA clients (like UaExpert)
- Build your own application combining these patterns

## 📚 Additional Resources

- [zopcua API Documentation](https://xentropic-dev.github.io/zopcua/)
- [OPC UA Specification](https://opcfoundation.org/developer-tools/specifications-unified-architecture)
- [open62541 Documentation](https://www.open62541.org/)
