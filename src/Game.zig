const std = @import("std");
const math = std.math;
const mem = std.mem;
const fmt = std.fmt;

pub const palettes = @import("palettes");
pub const sprites = @import("sprites");
const w4 = @import("w4");

pub const Camera = @import("Game/Camera.zig");
pub const Collider = @import("Game/Collider.zig");
pub const Gamepad = @import("Game/Gamepad.zig");
pub const Hud = @import("Game/Hud.zig");
pub const Planet = @import("Game/Planet.zig");
pub const Player = @import("Game/Player.zig");
pub const Position = @import("Game/Position.zig");
pub const Direction = Position.Direction;

const Game = @This();
pub const PLANET_COUNT = 6;
pub const WORLD_LIMIT_X = 5000;
pub const WORLD_LIMIT_Y = 5000;

pub const State = enum { NotStarted, Running, Win, Over };

const SECONDS_TO_DIE = 300;

state: State = .NotStarted,
frame: usize = 0,
player: Player = .{},
camera: Camera = .{},
gamepad: Gamepad = undefined,
planets: [PLANET_COUNT]Planet = undefined,
hud: Hud = .{},
remaining_time: isize = SECONDS_TO_DIE,

pub fn init(allocator: mem.Allocator, rng: std.Random) !@This() {
    _ = rng; // autofix
    _ = allocator; // autofix
    w4.PALETTE.* = palettes.bittersweet;

    const planets: [PLANET_COUNT]Planet = .{
        .{
            .position = .{ .x = 0, .y = 0 },
            .size = 80,
            .speed = 0.0,
        },
        .{
            .position = .{ .x = 60, .y = 0 },
            .size = 15,
            .speed = 0.02,
        },
        .{
            .position = .{ .x = 90, .y = 0 },
            .size = 20,
            .speed = 0.011,
        },
        .{
            .position = .{ .x = 130, .y = 0 },
            .size = 10,
            .speed = 0.0065,
        },
        .{
            .position = .{ .x = 180, .y = 0 },
            .size = 8,
            .speed = 0.004,
        },
        .{
            .position = .{ .x = 300, .y = 0 },
            .size = 40,
            .speed = 0.0018,
        },
    };

    return @This(){
        .player = Player.init(.{ .x = 0, .y = 0 }),
        .camera = Camera.init(.{ .x = 0, .y = 0 }),
        .gamepad = Gamepad.init(w4.GAMEPAD1),
        .planets = planets,
    };
}

pub fn update(this: *@This(), allocator: mem.Allocator, rng: std.Random) !void {
    loop: switch (this.state) {
        .NotStarted => continue :loop .Running,
        .Running => {
            defer {
                this.frame += 1;
                if (this.frame % 60 == 0) this.remaining_time -= 1;
            }

            inline for (&this.planets) |*p| {
                p.move(this.frame);
                p.draw(&this.camera);
            }

            if (this.remaining_time <= 0) {
                this.state = .Over;
                continue :loop this.state;
            }

            this.input(rng);
            try this.colide(allocator);

            this.player.draw(&this.camera);

            try Hud.draw(
                allocator,
                &this.player,
                this.remaining_time,
            );

            inline for (0..PLANET_COUNT) |i| {
                this.planets[i].draw(&this.camera);
            }
            this.camera.move(this.player.position);
        },
        .Win => {
            const msg = try fmt.allocPrint(
                allocator,
                \\You Win!!!
                \\Time Left: {d}
                \\Press 1 to reset
            ,
                .{
                    this.remaining_time,
                },
            );
            defer allocator.free(msg);

            w4.text(msg, w4.SCREEN_SIZE / 2 - 60, w4.SCREEN_SIZE / 2 - 10);
            this.input(rng);
        },

        .Over => {
            const msg =
                \\Game Over!!!
                \\Press 1 to reset
            ;
            w4.text(msg, w4.SCREEN_SIZE / 2 - 60, w4.SCREEN_SIZE / 2 - 10);
            this.input(rng);
        },
    }
}

fn reset(this: *@This(), rng: std.Random) void {
    this.state = .NotStarted;
    this.frame = 0;
    this.remaining_time = SECONDS_TO_DIE;
    this.player = Player.init(Position.random(rng));
}

fn input(this: *@This(), rng: std.Random) void {
    const gamepadState = this.gamepad.snapshot(.Hold);
    const gameState = this.state;

    if (gamepadState.@"1" and (gameState == .Over or gameState == .Win))
        this.reset(rng);

    if (gamepadState.left) this.player.move(.Left, this.gamepad);

    if (gamepadState.right) this.player.move(.Right, this.gamepad);

    if (gamepadState.up) this.player.move(.Up, this.gamepad);

    if (gamepadState.down) this.player.move(.Down, this.gamepad);
}

fn colide(this: *@This(), allocator: mem.Allocator) !void {
    // Check collisions with player 1
    const player = this.player;
    const x1, const y1 = player.position.normalized();
    const x2, const y2 = this.camera.position.normalized();

    const msg = try fmt.allocPrint(
        allocator,
        "Player: ({}, {}) Camera: ({}, {}) dir: {}",
        .{ x1, y1, x2, y2, player.direction },
    );
    defer allocator.free(msg);
    w4.trace(msg);
}
