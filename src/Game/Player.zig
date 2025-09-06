const std = @import("std");
const math = std.math;

const Game = @import("Game");
const Position = Game.Position;
const Camera = Game.Camera;
const Collider = Game.Collider;
const Direction = Position.Direction;
const sprites = @import("sprites");
const spaceship = sprites.spacheship;
const w4 = @import("w4");

position: Position = .{},
direction: Direction = .Up,
speed: f32 = 0.55,
collider: Collider = .{},

pub fn init(position: Position) @This() {
    return .{
        .position = position,
        .collider = .{
            .position = position,
            .size = 8,
        },
    };
}

pub fn draw(this: *const @This(), camera: *const Camera) void {
    const posInCameraSystem = camera.worldToCamera(this.position);
    const x, const y = posInCameraSystem.normalized();

    w4.DRAW_COLORS.* = 0x0032;
    w4.blit(
        &spaceship.data,
        x - spaceship.width / 2,
        y - spaceship.height / 2,
        spaceship.width,
        spaceship.height,
        switch (this.direction) {
            .Up => spaceship.flags,
            .Down => spaceship.flags | w4.BLIT_FLIP_Y,
            .Left => spaceship.flags | w4.BLIT_ROTATE,
            .Right => spaceship.flags | w4.BLIT_ROTATE | w4.BLIT_FLIP_Y,
        },
    );
}

pub fn move(this: *@This(), dir: Direction) void {
    // if (dir.areOpposites(this.direction)) return;

    const offset = dir.getPositionOffset();

    this.direction = dir;

    this.position.x = math.clamp(
        this.position.x + offset.x * this.speed,
        -Game.WORLD_LIMIT_X,
        Game.WORLD_LIMIT_X,
    );
    this.position.y = math.clamp(
        this.position.y - offset.y * this.speed,
        -Game.WORLD_LIMIT_Y,
        Game.WORLD_LIMIT_Y,
    );
}
