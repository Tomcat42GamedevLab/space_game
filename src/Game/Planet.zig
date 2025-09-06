const std = @import("std");
const math = std.math;

const Game = @import("Game");
const Camera = Game.Camera;
const Position = Game.Position;
const Collider = Game.Collider;
const Direction = Game.Direction;
const w4 = @import("w4");

position: Position = .{},
size: u32 = 1,
speed: f32 = 0.01,

pub fn init(position: Position, size: u32) @This() {
    return .{
        .position = position,
        .size = size,
    };
}

pub fn draw(this: *const @This(), camera: *const Camera) void {
    const posInCameraSystem = camera.worldToCamera(this.position);
    const posCenterWorld = camera.worldToCamera(Position.init(0, 0));
    const x, const y = posInCameraSystem.normalized();

    w4.DRAW_COLORS.* = 0x0032;
    w4.oval(
        x - @as(i32, @intCast(@divTrunc(this.size, 2))),
        y - @as(i32, @intCast(@divTrunc(this.size, 2))),
        this.size,
        this.size,
    );

    // Draw the planet orbit
    w4.DRAW_COLORS.* = 0x0020;
    const width: u32 = @intFromFloat(math.round(this.position.distance(.{ .x = 0, .y = 0 }) * 2));
    const height: u32 = @intFromFloat(math.round(this.position.distance(.{ .x = 0, .y = 0 }) * 2));
    w4.oval(
        -@as(i32, @intCast(width / 2)) + @as(i32, @intFromFloat(posCenterWorld.x)),
        -@as(i32, @intCast(height / 2)) + @as(i32, @intFromFloat(posCenterWorld.y)),
        width,
        height,
    );
}

pub fn move(this: *@This(), t: usize) void {
    const angle = @as(f32, @floatFromInt(t)) * this.speed;
    const size = this.position.distance(.{ .x = 0, .y = 0 });

    const relative_x = math.cos(angle) * size;
    const relative_y = math.sin(angle) * size;

    this.position.x = relative_x;
    this.position.y = relative_y;
}
