# Artemis Engine

[![Zig Version](https://img.shields.io/badge/zig-0.15.1-orange)](https://ziglang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)]()

**A modern, high-performance Entity-Component-System (ECS) game engine written in Zig.**

> **🎉 Status**: **PRODUCTION READY** - Artemis Engine 1.0.0 is officially released! Stable, tested, and ready for game development.

## ✨ What is Artemis Engine?

Artemis Engine is a blazingly fast, memory-safe ECS game engine designed for both indie developers and large-scale projects. Built from the ground up in Zig, it provides zero-cost abstractions with compile-time safety guarantees.

### Key Features

- **🚀 Ultra-fast ECS**: Handle 100K+ entities with minimal overhead
- **🛡️ Memory Safety**: Zero-cost abstractions with Zig's safety guarantees  
- **🔒 Type Safety**: Compile-time component and system validation
- **👩‍💻 Developer Friendly**: Clear APIs, comprehensive tests, detailed documentation
- **⚡ High Performance**: Optimized for modern hardware and parallel processing
- **🔧 Modular Design**: Use only what you need, extend with plugins
- **🎮 Production Ready**: Battle-tested architecture used in real games

## 🚀 Quick Start

### Prerequisites
- **Zig 0.15.1+** (required for compatibility)
- **Git** for cloning

### 30-Second Setup
```bash
# Add as dependency in build.zig.zon
.{
    .name = "my-game",
    .version = "0.1.0",
    .dependencies = .{
        .artemis = .{
            .url = "https://github.com/terminatable/artemis-engine/archive/v1.0.0.tar.gz",
            .hash = "...", // zig will provide this
        },
    },
}
```

Or clone directly:
```bash
git clone https://github.com/terminatable/artemis-engine.git
cd artemis-engine

# Verify everything works
zig build                 # Build engine  
zig build test           # Run test suite
zig build bench          # Run benchmarks
```

## 🎮 Your First Game

```zig
const std = @import("std");
const artemis = @import("artemis-engine");

// Define components
const Position = struct { x: f32, y: f32 };
const Velocity = struct { x: f32, y: f32 };

// Create movement system
const MovementSystem = struct {
    pub fn update(world: *artemis.World, dt: f32) !void {
        var query = world.query(.{ Position, Velocity });
        while (query.next()) |entity| {
            const pos = world.get(Position, entity).?;
            const vel = world.get(Velocity, entity).?;
            
            pos.x += vel.x * dt;
            pos.y += vel.y * dt;
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var world = artemis.World.init(gpa.allocator());
    defer world.deinit();

    // Create player
    const player = world.entity();
    try world.set(Position, player, .{ .x = 0, .y = 0 });
    try world.set(Velocity, player, .{ .x = 100, .y = 50 });

    // Game loop
    var timer = std.time.Timer.start() catch unreachable;
    while (true) {
        const dt = @as(f32, @floatFromInt(timer.lap())) / std.time.ns_per_s;
        
        try MovementSystem.update(&world, dt);
        
        // Your rendering code here...
        
        std.time.sleep(16 * std.time.ns_per_ms); // ~60 FPS
    }
}
```

## 🛠️ Development Commands

```bash
# Essential commands
zig build                 # Build engine
zig build test           # Run all tests  
zig build bench          # Run benchmarks

# Development workflow  
zig build test-minimal   # Quick compatibility check
zig fmt .                # Format code

# Optimized builds
zig build -Doptimize=ReleaseFast  # Maximum performance
zig build -Doptimize=ReleaseSmall # Minimum size
```

## 📚 Examples & Learning

The examples/ directory contains comprehensive examples:

- **basic.zig** - Your first ECS program
- **systems.zig** - Building game systems
- **queries.zig** - Advanced query patterns
- **plugins.zig** - Creating plugins
- **networking.zig** - Multiplayer foundations

```bash
# Run examples
zig build run-example -- basic
zig build run-example -- systems
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Artemis Engine** - Fast, Safe, Modular ECS for Zig  
*Part of the [Terminatable](https://github.com/terminatable) open source game development ecosystem.*

**Ready to build?** Start with our [Quick Start Guide](#-quick-start) and join the community!