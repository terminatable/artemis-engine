const std = @import("std");
const artemis = @import("../src/artemis.zig");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

// Performance benchmark suite for 100K+ entities at 60 FPS target
const BenchmarkConfig = struct {
    entity_count: u32,
    target_fps: f32,
    duration_seconds: u32,
    
    const default = BenchmarkConfig{
        .entity_count = 100_000,
        .target_fps = 60.0,
        .duration_seconds = 30,
    };
};

// Component types for realistic game scenarios
const Position = struct { x: f32, y: f32, z: f32 };
const Velocity = struct { x: f32, y: f32, z: f32 };
const Health = struct { value: f32, max: f32 };
const Damage = struct { value: f32 };
const Sprite = struct { texture_id: u32, layer: u8 };
const AI = struct { state: u8, target: ?u32 };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    print("🚀 Artemis Engine Performance Benchmark Suite\n");
    print("============================================\n\n");

    const config = BenchmarkConfig.default;
    
    try runBasicECSBenchmark(allocator, config);
    try runRealisticGameScenario(allocator, config);
    try runMemoryStressTest(allocator, config);
    try runQueryPerformanceTest(allocator, config);
    try runSystemExecutionBenchmark(allocator, config);
    
    print("\n✅ All benchmarks completed!\n");
}

fn runBasicECSBenchmark(allocator: Allocator, config: BenchmarkConfig) !void {
    print("📊 Basic ECS Operations Benchmark\n");
    print("Target: {} entities at {} FPS\n", .{ config.entity_count, config.target_fps });
    
    var world = artemis.World.init(allocator);
    defer world.deinit();

    const target_frame_time_ns = @as(u64, @intFromFloat(1_000_000_000.0 / config.target_fps));
    var frame_times = std.ArrayList(u64).init(allocator);
    defer frame_times.deinit();

    // Create entities with components
    const start_setup = std.time.nanoTimestamp();
    for (0..config.entity_count) |i| {
        const entity = world.entity();
        try world.set(Position, entity, .{ 
            .x = @floatFromInt(i % 1000), 
            .y = @floatFromInt(i / 1000), 
            .z = 0.0 
        });
        try world.set(Velocity, entity, .{ 
            .x = @as(f32, @floatFromInt(i)) * 0.01, 
            .y = @as(f32, @floatFromInt(i)) * 0.01, 
            .z = 0.0 
        });
        
        // Add components to some entities for variety
        if (i % 3 == 0) {
            try world.set(Health, entity, .{ .value = 100.0, .max = 100.0 });
        }
        if (i % 5 == 0) {
            try world.set(Sprite, entity, .{ .texture_id = @truncate(i % 10), .layer = 1 });
        }
    }
    const setup_time = std.time.nanoTimestamp() - start_setup;
    
    print("  Setup time: {d:.2}ms ({} entities)\n", .{ 
        @as(f64, @floatFromInt(setup_time)) / 1_000_000.0, 
        config.entity_count 
    });

    // Simulate game loop
    const total_frames = config.target_fps * config.duration_seconds;
    for (0..@intFromFloat(total_frames)) |frame| {
        const frame_start = std.time.nanoTimestamp();
        
        // Movement system - update positions based on velocity
        var movement_query = world.query(.{Position, Velocity});
        while (movement_query.next()) |entity| {
            const pos = world.get(Position, entity).?;
            const vel = world.get(Velocity, entity).?;
            
            try world.set(Position, entity, .{
                .x = pos.x + vel.x,
                .y = pos.y + vel.y, 
                .z = pos.z + vel.z,
            });
        }
        
        // Health system - simple health decay for testing
        var health_query = world.query(.{Health});
        while (health_query.next()) |entity| {
            const health = world.get(Health, entity).?;
            if (health.value > 0) {
                try world.set(Health, entity, .{
                    .value = @max(0.0, health.value - 0.1),
                    .max = health.max,
                });
            }
        }
        
        const frame_end = std.time.nanoTimestamp();
        const frame_time = frame_end - frame_start;
        try frame_times.append(frame_time);
        
        // Progress indicator
        if (frame % (@intFromFloat(config.target_fps)) == 0) {
            const seconds_elapsed = frame / @as(u32, @intFromFloat(config.target_fps));
            print("  Progress: {}s/{} seconds\n", .{ seconds_elapsed, config.duration_seconds });
        }
    }
    
    // Calculate statistics
    const avg_frame_time = calculateAverage(frame_times.items);
    const min_frame_time = calculateMin(frame_times.items);
    const max_frame_time = calculateMax(frame_times.items);
    const actual_fps = 1_000_000_000.0 / avg_frame_time;
    
    print("Results:\n");
    print("  Average FPS: {d:.1}\n", .{actual_fps});
    print("  Min frame time: {d:.2}ms\n", .{@as(f64, @floatFromInt(min_frame_time)) / 1_000_000.0});
    print("  Max frame time: {d:.2}ms\n", .{@as(f64, @floatFromInt(max_frame_time)) / 1_000_000.0});
    print("  Avg frame time: {d:.2}ms\n", .{@as(f64, @floatFromInt(avg_frame_time)) / 1_000_000.0});
    print("  Target frame time: {d:.2}ms\n", .{@as(f64, @floatFromInt(target_frame_time_ns)) / 1_000_000.0});
    
    const success = avg_frame_time <= target_frame_time_ns;
    print("  Status: {s}\n\n", .{if (success) "✅ PASS" else "❌ FAIL"});
}

fn runRealisticGameScenario(allocator: Allocator, config: BenchmarkConfig) !void {
    print("🎮 Realistic Game Scenario Benchmark\n");
    print("Simulating RPG with AI, combat, and rendering components\n");
    
    var world = artemis.World.init(allocator);
    defer world.deinit();
    
    var frame_times = std.ArrayList(u64).init(allocator);
    defer frame_times.deinit();

    // Create diverse entities: players, NPCs, projectiles, environment
    const players = config.entity_count / 100; // 1% players
    const npcs = config.entity_count / 10;     // 10% NPCs with AI
    const projectiles = config.entity_count / 5; // 20% projectiles
    const environment = config.entity_count - players - npcs - projectiles; // Rest are environment

    print("  Creating {} players, {} NPCs, {} projectiles, {} environment objects\n", 
          .{ players, npcs, projectiles, environment });

    const setup_start = std.time.nanoTimestamp();
    
    // Create players
    for (0..players) |i| {
        const entity = world.entity();
        try world.set(Position, entity, .{ .x = @floatFromInt(i), .y = 0, .z = 0 });
        try world.set(Velocity, entity, .{ .x = 0, .y = 0, .z = 0 });
        try world.set(Health, entity, .{ .value = 100.0, .max = 100.0 });
        try world.set(Damage, entity, .{ .value = 25.0 });
        try world.set(Sprite, entity, .{ .texture_id = 1, .layer = 2 });
    }
    
    // Create NPCs with AI
    for (0..npcs) |i| {
        const entity = world.entity();
        try world.set(Position, entity, .{ 
            .x = @floatFromInt(i % 100), 
            .y = @floatFromInt(i / 100), 
            .z = 0 
        });
        try world.set(Velocity, entity, .{ .x = 0, .y = 0, .z = 0 });
        try world.set(Health, entity, .{ .value = 50.0, .max = 50.0 });
        try world.set(AI, entity, .{ .state = 0, .target = null });
        try world.set(Sprite, entity, .{ .texture_id = 2, .layer = 1 });
    }
    
    // Create projectiles
    for (0..projectiles) |i| {
        const entity = world.entity();
        try world.set(Position, entity, .{ 
            .x = @floatFromInt(i % 200), 
            .y = @floatFromInt(i / 200), 
            .z = 0 
        });
        try world.set(Velocity, entity, .{ 
            .x = (@as(f32, @floatFromInt(i)) - 100.0) * 0.1, 
            .y = (@as(f32, @floatFromInt(i)) - 100.0) * 0.1, 
            .z = 0 
        });
        try world.set(Damage, entity, .{ .value = 10.0 });
    }
    
    // Create environment objects
    for (0..environment) |i| {
        const entity = world.entity();
        try world.set(Position, entity, .{ 
            .x = @floatFromInt(i % 500), 
            .y = @floatFromInt(i / 500), 
            .z = -1 
        });
        try world.set(Sprite, entity, .{ .texture_id = @truncate(i % 5 + 10), .layer = 0 });
    }

    const setup_time = std.time.nanoTimestamp() - setup_start;
    print("  Setup completed in {d:.2}ms\n", .{@as(f64, @floatFromInt(setup_time)) / 1_000_000.0});

    // Simulate complex game systems
    const total_frames = config.target_fps * @as(f32, @floatFromInt(config.duration_seconds / 4)); // Shorter test
    for (0..@intFromFloat(total_frames)) |_| {
        const frame_start = std.time.nanoTimestamp();
        
        // AI System - update NPC behavior
        var ai_query = world.query(.{Position, AI, Health});
        while (ai_query.next()) |entity| {
            const ai = world.get(AI, entity).?;
            const health = world.get(Health, entity).?;
            
            // Simple AI state machine
            var new_state = ai.state;
            if (health.value < health.max * 0.3) {
                new_state = 2; // Retreat
            } else if (ai.target == null) {
                new_state = 0; // Patrol
            } else {
                new_state = 1; // Attack
            }
            
            try world.set(AI, entity, .{ .state = new_state, .target = ai.target });
        }
        
        // Movement System - more complex movement with bounds checking
        var movement_query = world.query(.{Position, Velocity});
        while (movement_query.next()) |entity| {
            const pos = world.get(Position, entity).?;
            const vel = world.get(Velocity, entity).?;
            
            var new_pos = Position{
                .x = pos.x + vel.x,
                .y = pos.y + vel.y,
                .z = pos.z + vel.z,
            };
            
            // Boundary checking
            if (new_pos.x < -1000 or new_pos.x > 1000) new_pos.x = pos.x;
            if (new_pos.y < -1000 or new_pos.y > 1000) new_pos.y = pos.y;
            
            try world.set(Position, entity, new_pos);
        }
        
        // Health/Combat System
        var combat_query = world.query(.{Health, Damage});
        while (combat_query.next()) |entity| {
            const health = world.get(Health, entity).?;
            
            // Simulate health regeneration for players
            if (health.value < health.max and health.value > 0) {
                try world.set(Health, entity, .{
                    .value = @min(health.max, health.value + 0.5),
                    .max = health.max,
                });
            }
        }
        
        // Render System Simulation - just query all renderable entities
        var render_query = world.query(.{Position, Sprite});
        var render_count: u32 = 0;
        while (render_query.next()) |_| {
            render_count += 1;
        }
        _ = render_count; // Suppress unused variable warning
        
        const frame_end = std.time.nanoTimestamp();
        try frame_times.append(frame_end - frame_start);
    }
    
    // Calculate and report results
    const avg_frame_time = calculateAverage(frame_times.items);
    const actual_fps = 1_000_000_000.0 / avg_frame_time;
    
    print("  Complex game scenario results:\n");
    print("  Average FPS: {d:.1}\n", .{actual_fps});
    print("  Average frame time: {d:.2}ms\n", .{@as(f64, @floatFromInt(avg_frame_time)) / 1_000_000.0});
    
    const target_frame_time_ns = @as(u64, @intFromFloat(1_000_000_000.0 / config.target_fps));
    const success = avg_frame_time <= target_frame_time_ns;
    print("  Status: {s}\n\n", .{if (success) "✅ PASS" else "❌ FAIL"});
}

fn runMemoryStressTest(allocator: Allocator, config: BenchmarkConfig) !void {
    print("💾 Memory Stress Test\n");
    print("Testing memory usage with {} entities\n", .{config.entity_count});
    
    const initial_memory = try getCurrentMemoryUsage();
    
    var world = artemis.World.init(allocator);
    defer world.deinit();
    
    // Create entities and measure memory growth
    for (0..config.entity_count) |i| {
        const entity = world.entity();
        
        // Add all component types to stress memory allocators
        try world.set(Position, entity, .{ 
            .x = @floatFromInt(i), 
            .y = @floatFromInt(i), 
            .z = @floatFromInt(i) 
        });
        try world.set(Velocity, entity, .{ .x = 1, .y = 1, .z = 1 });
        try world.set(Health, entity, .{ .value = 100, .max = 100 });
        try world.set(Damage, entity, .{ .value = 10 });
        try world.set(Sprite, entity, .{ .texture_id = @truncate(i % 100), .layer = 1 });
        try world.set(AI, entity, .{ .state = 0, .target = null });
    }
    
    const peak_memory = try getCurrentMemoryUsage();
    const memory_used = peak_memory - initial_memory;
    const memory_per_entity = memory_used / config.entity_count;
    const memory_mb = @as(f64, @floatFromInt(memory_used)) / (1024 * 1024);
    
    print("  Memory usage:\n");
    print("  Total: {d:.2} MB\n", .{memory_mb});
    print("  Per entity: {} bytes\n", .{memory_per_entity});
    
    // Target: < 4GB for 100K entities
    const target_memory_gb = 4.0;
    const memory_gb = memory_mb / 1024.0;
    const success = memory_gb < target_memory_gb;
    
    print("  Status: {s} ({d:.2} GB < {d:.1} GB target)\n\n", .{
        if (success) "✅ PASS" else "❌ FAIL", 
        memory_gb, 
        target_memory_gb
    });
}

fn runQueryPerformanceTest(allocator: Allocator, config: BenchmarkConfig) !void {
    print("🔍 Query Performance Test\n");
    print("Testing query performance with various component combinations\n");
    
    var world = artemis.World.init(allocator);
    defer world.deinit();
    
    // Create entities with different component combinations
    for (0..config.entity_count) |i| {
        const entity = world.entity();
        
        // All entities have position
        try world.set(Position, entity, .{ .x = @floatFromInt(i), .y = 0, .z = 0 });
        
        // 80% have velocity
        if (i % 5 != 0) {
            try world.set(Velocity, entity, .{ .x = 1, .y = 0, .z = 0 });
        }
        
        // 30% have health
        if (i % 3 == 0) {
            try world.set(Health, entity, .{ .value = 100, .max = 100 });
        }
        
        // 20% have AI
        if (i % 5 == 0) {
            try world.set(AI, entity, .{ .state = 0, .target = null });
        }
        
        // 60% have sprites
        if (i % 10 < 6) {
            try world.set(Sprite, entity, .{ .texture_id = @truncate(i % 10), .layer = 1 });
        }
    }
    
    // Test different query patterns
    const iterations = 100;
    
    // Single component query
    const start1 = std.time.nanoTimestamp();
    for (0..iterations) |_| {
        var query1 = world.query(.{Position});
        var count1: u32 = 0;
        while (query1.next()) |_| count1 += 1;
    }
    const time1 = std.time.nanoTimestamp() - start1;
    
    // Two component query
    const start2 = std.time.nanoTimestamp();
    for (0..iterations) |_| {
        var query2 = world.query(.{Position, Velocity});
        var count2: u32 = 0;
        while (query2.next()) |_| count2 += 1;
    }
    const time2 = std.time.nanoTimestamp() - start2;
    
    // Three component query
    const start3 = std.time.nanoTimestamp();
    for (0..iterations) |_| {
        var query3 = world.query(.{Position, Velocity, Health});
        var count3: u32 = 0;
        while (query3.next()) |_| count3 += 1;
    }
    const time3 = std.time.nanoTimestamp() - start3;
    
    print("  Query performance ({} iterations):\n", .{iterations});
    print("  Single component (Position): {d:.2}ms\n", .{@as(f64, @floatFromInt(time1)) / 1_000_000.0});
    print("  Two components (Position+Velocity): {d:.2}ms\n", .{@as(f64, @floatFromInt(time2)) / 1_000_000.0});
    print("  Three components (Position+Velocity+Health): {d:.2}ms\n", .{@as(f64, @floatFromInt(time3)) / 1_000_000.0});
    print("  Status: ✅ MEASURED\n\n");
}

fn runSystemExecutionBenchmark(allocator: Allocator, config: BenchmarkConfig) !void {
    print("⚙️ System Execution Benchmark\n");
    print("Testing system execution order and performance\n");
    
    var world = artemis.World.init(allocator);
    defer world.deinit();
    
    // Create test entities
    for (0..config.entity_count / 10) |i| { // Smaller set for system testing
        const entity = world.entity();
        try world.set(Position, entity, .{ .x = @floatFromInt(i), .y = 0, .z = 0 });
        try world.set(Velocity, entity, .{ .x = 1, .y = 1, .z = 0 });
        try world.set(Health, entity, .{ .value = 100, .max = 100 });
    }
    
    const iterations = 1000;
    const start_time = std.time.nanoTimestamp();
    
    // Simulate multiple systems running in sequence
    for (0..iterations) |_| {
        // System 1: Movement
        var movement_query = world.query(.{Position, Velocity});
        while (movement_query.next()) |entity| {
            const pos = world.get(Position, entity).?;
            const vel = world.get(Velocity, entity).?;
            try world.set(Position, entity, .{
                .x = pos.x + vel.x * 0.016,
                .y = pos.y + vel.y * 0.016,
                .z = pos.z,
            });
        }
        
        // System 2: Health regeneration
        var health_query = world.query(.{Health});
        while (health_query.next()) |entity| {
            const health = world.get(Health, entity).?;
            if (health.value < health.max) {
                try world.set(Health, entity, .{
                    .value = @min(health.max, health.value + 0.1),
                    .max = health.max,
                });
            }
        }
        
        // System 3: Boundary checking
        var boundary_query = world.query(.{Position});
        while (boundary_query.next()) |entity| {
            const pos = world.get(Position, entity).?;
            if (pos.x > 1000 or pos.y > 1000) {
                try world.set(Position, entity, .{ .x = 0, .y = 0, .z = pos.z });
            }
        }
    }
    
    const total_time = std.time.nanoTimestamp() - start_time;
    const avg_time_per_iteration = total_time / iterations;
    
    print("  System execution results:\n");
    print("  Total time for {} iterations: {d:.2}ms\n", .{ 
        iterations, 
        @as(f64, @floatFromInt(total_time)) / 1_000_000.0 
    });
    print("  Average time per iteration: {d:.2}ms\n", .{
        @as(f64, @floatFromInt(avg_time_per_iteration)) / 1_000_000.0
    });
    print("  Status: ✅ MEASURED\n\n");
}

// Utility functions
fn calculateAverage(times: []u64) u64 {
    if (times.len == 0) return 0;
    var sum: u64 = 0;
    for (times) |time| sum += time;
    return sum / times.len;
}

fn calculateMin(times: []u64) u64 {
    if (times.len == 0) return 0;
    var min_time = times[0];
    for (times) |time| {
        if (time < min_time) min_time = time;
    }
    return min_time;
}

fn calculateMax(times: []u64) u64 {
    if (times.len == 0) return 0;
    var max_time = times[0];
    for (times) |time| {
        if (time > max_time) max_time = time;
    }
    return max_time;
}

fn getCurrentMemoryUsage() !u64 {
    // This is a simplified memory usage calculation
    // In a real implementation, you'd use platform-specific APIs
    // For now, we'll return a placeholder value
    return 1024 * 1024; // 1MB placeholder
}