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

pub fn init(position: Position, size: u32) @This() {
    return .{
        .position = position,
        .size = size,
    };
}

pub fn draw(this: *const @This(), camera: *const Camera) void {
    const posInCameraSystem = camera.worldToCamera(this.position);
    const x, const y = posInCameraSystem.normalized();

    w4.DRAW_COLORS.* = 0x0032;
    w4.oval(x, y, this.size, this.size);
}
