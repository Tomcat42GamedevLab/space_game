const std = @import("std");
const math = std.math;

const Game = @import("Game");
const Gamepad = @import("Gamepad.zig");
const Position = Game.Position;
const Camera = Game.Camera;
const Collider = Game.Collider;
const Direction = Position.Direction;
const sprites = @import("sprites");
const spritesheet = sprites.spritesheet;

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

pub fn draw(this: *const @This(), camera: *const Camera, isForward: bool) void {
    const posInCameraSystem = camera.worldToCamera(this.position);
    const x, const y = posInCameraSystem.normalized();
    var spriteY: u32 = undefined;
    if (isForward) {
        spriteY = 40;
    } else {
        spriteY = 0;
    }

    w4.DRAW_COLORS.* = 0x0032;
    switch (this.direction) {
        .Up, .Down, .Left, .Right => {
            w4.blitSub(
                &spritesheet.data,
                x - 16,
                y - 16,
                29,
                35,
                0,
                spriteY,
                68,
                switch (this.direction) {
                    .Up => spritesheet.flags,
                    .Down => spritesheet.flags | w4.BLIT_FLIP_Y,
                    .Left => spritesheet.flags | w4.BLIT_ROTATE,
                    .Right => spritesheet.flags | w4.BLIT_ROTATE | w4.BLIT_FLIP_Y,
                    .UR => spritesheet.flags,
                    .UL => spritesheet.flags | w4.BLIT_FLIP_Y,
                    .DR => spritesheet.flags | w4.BLIT_ROTATE,
                    .DL => spritesheet.flags | w4.BLIT_ROTATE | w4.BLIT_FLIP_Y,
                },
            );

            // w4.blit(
            //     &spaceship.data,
            //     x - spaceship.width / 2,
            //     y - spaceship.height / 2,
            //     spaceship.width,
            //     spaceship.height,
            //     switch (this.direction) {
            //         .Up => spaceship.flags,
            //         .Down => spaceship.flags | w4.BLIT_FLIP_Y,
            //         .Left => spaceship.flags | w4.BLIT_ROTATE,
            //         .Right => spaceship.flags | w4.BLIT_ROTATE | w4.BLIT_FLIP_Y,
            //         .UR => spaceshipR.flags,
            //         .UL => spaceshipR.flags | w4.BLIT_FLIP_Y,
            //         .DR => spaceshipR.flags | w4.BLIT_ROTATE,
            //         .DL => spaceshipR.flags | w4.BLIT_ROTATE | w4.BLIT_FLIP_Y,
            //     },
            // );
        },
        .UR, .UL, .DR, .DL => {
            w4.blitSub(
                &spritesheet.data,
                x - 20,
                y - 20,
                40,
                40,
                28,
                spriteY,
                68,
                switch (this.direction) {
                    .Up => spritesheet.flags,
                    .Down => spritesheet.flags | w4.BLIT_FLIP_Y,
                    .Left => spritesheet.flags | w4.BLIT_ROTATE,
                    .Right => spritesheet.flags | w4.BLIT_ROTATE | w4.BLIT_FLIP_Y,
                    .UR => spritesheet.flags,
                    .UL => spritesheet.flags | w4.BLIT_ROTATE,
                    .DR => spritesheet.flags | w4.BLIT_FLIP_Y,
                    .DL => spritesheet.flags | w4.BLIT_FLIP_Y | w4.BLIT_FLIP_X,
                },
            );
            // w4.blit(
            //     &spaceshipR.data,
            //     x - spaceshipR.width / 2,
            //     y - spaceshipR.height / 2,
            //     spaceshipR.width,
            //     spaceshipR.height,
            //     switch (this.direction) {
            //         .Up => spaceshipR.flags,
            //         .Down => spaceship.flags | w4.BLIT_FLIP_Y,
            //         .Left => spaceshipR.flags | w4.BLIT_ROTATE,
            //         .Right => spaceship.flags | w4.BLIT_ROTATE | w4.BLIT_FLIP_Y,
            //         .UR => spaceshipR.flags,
            //         .UL => spaceshipR.flags | w4.BLIT_ROTATE,
            //         .DR => spaceshipR.flags | w4.BLIT_FLIP_Y,
            //         .DL => spaceshipR.flags | w4.BLIT_FLIP_Y | w4.BLIT_FLIP_X,
            //     },
            // );
        },
    }
}

pub fn move(this: *@This(), dir: Direction, gamepad: Gamepad) void {
    // if (dir.areOpposites(this.direction)) return;

    if (gamepad.state & 0x60 == 0x60) {
        this.direction = Direction.UR;
    } else if (gamepad.state & 0x50 == 0x50) {
        this.direction = Direction.UL;
    } else if (gamepad.state & 0xA0 == 0xA0) {
        this.direction = Direction.DR;
    } else if (gamepad.state & 0x90 == 0x90) {
        this.direction = Direction.DL;
    } else if (gamepad.state & 0x40 == 0x40) {
        this.direction = Direction.Up;
    } else if (gamepad.state & 0x80 == 0x80) {
        this.direction = Direction.Down;
    } else if (gamepad.state & 0x10 == 0x10) {
        this.direction = Direction.Left;
    } else {
        this.direction = Direction.Right;
    }
    const offset = dir.getPositionOffset();

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
