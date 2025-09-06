const std = @import("std");
const math = std.math;

const Game = @import("Game");
const Position = Game.Position;
const Direction = Position.Direction;
const w4 = @import("w4");

// The camera position is in world coordinates and marks the
// top-left corner of the screen
position: Position = .{},
speed: f32 = 0.35,

pub fn init(position: Position) @This() {
    return .{ .position = position };
}

pub fn move(this: *@This(), player_pos: Position) void {
    const camera_smoothing = 20;

    // const camera_target_x = math.clamp(this.position.x, player_pos.x - 40, player_pos.x + 40) - 60;
    // const camera_target_y = math.clamp(this.position.y, player_pos.y - 40, player_pos.y + 40) + 60;

    const camera_target_x = player_pos.x - 60;
    const camera_target_y = player_pos.y + 60;

    this.position.x = math.clamp(
        ((this.position.x) * (camera_smoothing - 1) + camera_target_x) / camera_smoothing,
        -Game.WORLD_LIMIT_X,
        Game.WORLD_LIMIT_X,
    );

    this.position.y = math.clamp(
        ((this.position.y) * (camera_smoothing - 1) + camera_target_y) / camera_smoothing,
        -Game.WORLD_LIMIT_Y,
        Game.WORLD_LIMIT_Y,
    );
}

/// Converts coordinates from the World system to the Camera Sistem
pub fn worldToCamera(this: @This(), world_pos: Position) Position {
    return .{
        .x = world_pos.x - this.position.x,
        .y = this.position.y - world_pos.y,
    };
}

/// Converts coordinates from the Camera system to the World System
pub fn cameraToWorld(this: @This(), camera_pos: Position) Position {
    return .{
        .x = camera_pos.x + this.position.x,
        .y = this.position.y - camera_pos.y,
    };
}

/// The the center of the camera in world coordinates
/// NOTE: This is NOT the origin (which is at the top-left corner)
pub fn getCenter(this: @This()) Position {
    return .{
        .x = this.position.x + (w4.SCREEN_SIZE / 2),
        .y = this.position.y + (w4.SCREEN_SIZE / 2),
    };
}
