const std = @import("std");
const math = std.math;
const mem = std.mem;
const fmt = std.fmt;

pub const palettes = @import("palettes");
pub const sprites = @import("sprites");
const w4 = @import("w4");

const Game = @This();

pub const PLANET_COUNT = 2;
pub const WORLD_LIMIT_X = 5000;
pub const WORLD_LIMIT_Y = 5000;

pub const Position = @import("Game/Position.zig");
pub const Direction = Position.Direction;
pub const Player = @import("Game/Player.zig");
pub const Gamepad = @import("Game/Gamepad.zig");
pub const Collider = @import("Game/Collider.zig");
pub const Camera = @import("Game/Camera.zig");
pub const Hud = @import("Game/Hud.zig");
pub const Planet = @import("Game/Planet.zig");

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
        .{ .position = .{ .x = 0, .y = 0 }, .size = 10 },
        .{ .position = .{ .x = 30, .y = 30 }, .size = 4 },
    };

    return @This(){
        .player = Player.init(.{ .x = 31, .y = 31 }),
        .camera = Camera.init(.{ .x = 31, .y = 31 }),
        .gamepad = Gamepad.init(w4.GAMEPAD1),
        .planets = planets,
    };
}

pub fn update(this: *@This(), allocator: mem.Allocator, rng: std.Random) !void {
    loop: switch (this.state) {
        .NotStarted => continue :loop .Running,
        .Running => {
            defer this.frame += 1;
            defer {
                if (this.frame % 60 == 0) this.remaining_time -= 1;
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

    if (gamepadState.left) this.player.move(.Left);

    if (gamepadState.right) this.player.move(.Right);

    if (gamepadState.up) this.player.move(.Up);

    if (gamepadState.down) this.player.move(.Down);
}

fn colide(this: *@This(), allocator: mem.Allocator) !void {
    // Check collisions with player 1
    const player = this.player;
    const x1, const y1 = player.position.normalized();

    const msg = try fmt.allocPrint(
        allocator,
        "Player: ({}, {})",
        .{ x1, y1 },
    );
    defer allocator.free(msg);
    w4.trace(msg);
}
