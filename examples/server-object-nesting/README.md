# Object Nesting Example

This example demonstrates how to organize OPC UA nodes using object nodes (folders) to create a hierarchical structure.

## What it demonstrates

- Creating object nodes using `Server.addObjectNode()`
- Organizing variables within object folders
- Creating nested folder structures (folders within folders)
- Using object nodes to represent logical organization (Equipment → Sensors/Actuators)

## Node Structure

```
Objects/
└── Equipment/
    ├── Sensors/
    │   ├── Temperature (23.5°C)
    │   ├── Pressure (101.325 kPa)
    │   └── Humidity (45.0%)
    └── Actuators/
        ├── ValvePosition (50.0%)
        └── MotorSpeed (1500.0 RPM)
```

## Running

```bash
zig build run
```

The server will start on `opc.tcp://localhost:4840`.

## Browsing

Use an OPC UA client to browse to `ns=1;s=equipment` to see the organized structure.

## Key Concepts

### Object Nodes

Object nodes act as containers for organizing other nodes. They:
- Represent physical or logical objects (e.g., equipment, devices)
- Can contain variables, methods, and other objects
- Use reference types (like `has_component`, `organizes`) to establish relationships

### Hierarchical Organization

This example shows three levels of hierarchy:
1. Root level: `Equipment` folder under the standard `Objects` folder
2. Second level: `Sensors` and `Actuators` folders under `Equipment`
3. Third level: Individual sensor/actuator variables under their respective folders

This organization makes the address space easier to navigate and understand.
