const std = @import("std");
const math = std.math;
const mem = std.mem;
const fmt = std.fmt;

pub const palettes = @import("palettes");
pub const sprites = @import("sprites");
const w4 = @import("w4");

const Game = @This();

pub const PIXEL_SIZE = 8;
pub const PLAYER_COUNT = 2;

pub const Position = @import("Game/Position.zig");
pub const Direction = @import("Game/Direction.zig");
pub const Player = @import("Game/Player.zig");
pub const Gamepad = @import("Game/Gamepad.zig");
pub const Collider = @import("Game/Collider.zig");

pub const State = enum { NotStarted, Running, Paused, Win, Over };

state: State = .NotStarted,
frame: usize = 0,
players: [PLAYER_COUNT]Player = undefined,
gamepads: [PLAYER_COUNT]Gamepad = undefined,

pub fn init(allocator: mem.Allocator, rng: std.Random) !@This() {
    _ = allocator; // autofix
    w4.PALETTE.* = palettes.bittersweet;

    const players, const gamepads = players: {
        var p: [PLAYER_COUNT]Player = undefined;
        var g: [PLAYER_COUNT]Gamepad = undefined;

        inline for (0..PLAYER_COUNT) |i| {
            p[i] = Player.init(Position.random(rng));
            g[i] = Gamepad.init(@ptrFromInt(@intFromPtr(w4.GAMEPAD1) + i));
        }
        break :players .{ p, g };
    };
    return @This(){
        .players = players,
        .gamepads = gamepads,
    };
}

pub fn update(this: *@This(), allocator: mem.Allocator, rng: std.Random) !void {
    _ = rng; // autofix

    loop: switch (this.state) {
        .NotStarted => continue :loop .Running,
        .Running => {
            defer this.frame += 1;

            this.input();
            try this.colide(allocator);

            inline for (this.players) |player|
                player.draw();
        },
        .Paused => w4.trace("Paused"),
        .Win => w4.trace("You Win!"),
        .Over => w4.trace("Game Over"),
    }
}

fn input(this: *@This()) void {
    inline for (&this.gamepads, 0..) |*gamepad, i| {
        const state = gamepad.snapshot(.Hold);

        if (state.left)
            this.players[i].move(Direction.Left);

        if (state.right)
            this.players[i].move(Direction.Right);

        if (state.up)
            this.players[i].move(Direction.Up);

        if (state.down)
            this.players[i].move(Direction.Down);
    }
}

fn colide(this: *@This(), allocator: mem.Allocator) !void {
    // Check collisions with player 1
    const p1 = &this.players[0];
    const p2 = &this.players[1];

    const x1, const y1 = p1.position.normalized();
    const x2, const y2 = p2.position.normalized();

    const msg = try fmt.allocPrint(
        allocator,
        "P1: ({}, {}) P2: ({}, {})",
        .{ x1, y1, x2, y2 },
    );
    defer allocator.free(msg);
    w4.trace(msg);

    if (p1.collider.collides(&p2.collider)) {
        w4.trace("Collision");
    }
}
