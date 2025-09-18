const std = @import("std");
const artemis = @import("artemis-engine");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    std.debug.print("🚀 Artemis Engine Basic Example\n");
    std.debug.print("Version: {s} \"{s}\"\n", .{ artemis.version.string, artemis.version.codename });

    var world = artemis.World.init(gpa.allocator());
    defer world.deinit();

    // Create player entity
    const player = world.entity();
    try world.set(artemis.Position, player, .{ .x = 0, .y = 0 });
    try world.set(artemis.Velocity, player, .{ .x = 100, .y = 50 });

    std.debug.print("Created player entity: {}\n", .{player});

    // Simple game loop
    for (0..5) |frame| {
        const dt: f32 = 1.0 / 60.0; // 60 FPS
        
        // Query entities with position and velocity
        var query = world.query(.{ artemis.Position, artemis.Velocity });
        while (query.next()) |entity| {
            if (world.get(artemis.Position, entity)) |pos| {
                if (world.get(artemis.Velocity, entity)) |vel| {
                    pos.x += vel.x * dt;
                    pos.y += vel.y * dt;
                    
                    std.debug.print("Frame {}: Entity {} at ({d:.2}, {d:.2})\n", 
                        .{ frame, entity, pos.x, pos.y });
                }
            }
        }
    }

    std.debug.print("✨ Basic example completed successfully!\n");
}