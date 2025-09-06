const std = @import("std");
const math = std.math;
const mem = std.mem;
const fmt = std.fmt;

pub const palettes = @import("palettes");
pub const sprites = @import("sprites");
const w4 = @import("w4");

const Game = @This();

pub const PLANET_COUNT = 9;

pub const Position = @import("Game/Position.zig");
pub const Direction = Position.Direction;
pub const Player = @import("Game/Player.zig");
pub const Gamepad = @import("Game/Gamepad.zig");
pub const Collider = @import("Game/Collider.zig");
pub const Hud = @import("Game/Hud.zig");
pub const Planet = @import("Game/Planet.zig");

pub const State = enum { NotStarted, Running, Paused, Win, Over };

state: State = .NotStarted,
frame: usize = 0,
player: Player = undefined,
gamepad: Gamepad = undefined,
planets: [PLANET_COUNT]Planet = undefined,
camera_position: Position = Position.init(0, 0),
hud: Hud = .{},
remaining_time: isize = 300, // in seconds

pub fn init(allocator: mem.Allocator, rng: std.Random) !@This() {
    _ = allocator; // autofix
    w4.PALETTE.* = palettes.bittersweet;

    var planets: [PLANET_COUNT]Planet = undefined;

    inline for (0..PLANET_COUNT) |i| {
        planets[i] = Planet.init(Position.init(i * 200, 100 - (i * 5 + 10) / 2), i * 8 + 10);
    }

    return @This(){
        .player = Player.init(Position.random(rng)),
        .gamepad = Gamepad.init(w4.GAMEPAD1),
        .planets = planets,
    };
}

pub fn update(this: *@This(), allocator: mem.Allocator, rng: std.Random) !void {
    _ = rng; // autofix

    loop: switch (this.state) {
        .NotStarted => continue :loop .Running,
        .Running => {
            defer this.frame += 1;
            defer {
                if (this.frame % 60 == 0) this.remaining_time -= 1;
            }

            this.input();
            try this.colide(allocator);

            this.player.draw();
            try Hud.draw(
                allocator,
                &this.player,
                this.remaining_time,
            );
            inline for (this.planets) |planets|
                planets.draw(this.camera_position);
        },
        .Paused => w4.trace("Paused"),
        .Win => w4.trace("You Win!"),
        .Over => w4.trace("Game Over"),
    }
}

fn input(this: *@This()) void {
    const state = this.gamepad.snapshot(.Hold);

    if (state.left) this.camera_position = this.player.move(.Left, this.camera_position);

    if (state.right) this.camera_position = this.player.move(.Right, this.camera_position);

    if (state.up) this.camera_position = this.player.move(.Up, this.camera_position);

    if (state.down) this.camera_position = this.player.move(.Down, this.camera_position);
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
