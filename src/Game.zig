const std = @import("std");
const math = std.math;
const mem = std.mem;
const fmt = std.fmt;

pub const palettes = @import("palettes");
pub const sprites = @import("sprites");
const w4 = @import("w4");

const Game = @This();

pub const Position = @import("Game/Position.zig");
pub const Direction = Position.Direction;
pub const Player = @import("Game/Player.zig");
pub const Gamepad = @import("Game/Gamepad.zig");
pub const Collider = @import("Game/Collider.zig");
pub const Hud = @import("Game/Hud.zig");

pub const State = enum { NotStarted, Running, Paused, Win, Over };

state: State = .NotStarted,
frame: usize = 0,
player: Player = undefined,
gamepad: Gamepad = undefined,
hud: Hud = .{},
remaining_time: isize = 300, // in seconds

pub fn init(allocator: mem.Allocator, rng: std.Random) !@This() {
    _ = allocator; // autofix
    w4.PALETTE.* = palettes.bittersweet;

    return @This(){
        .player = Player.init(Position.random(rng)),
        .gamepad = Gamepad.init(w4.GAMEPAD1),
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
        },
        .Paused => w4.trace("Paused"),
        .Win => w4.trace("You Win!"),
        .Over => w4.trace("Game Over"),
    }
}

fn input(this: *@This()) void {
    const state = this.gamepad.snapshot(.Hold);

    if (state.left) this.player.move(.Left);

    if (state.right) this.player.move(.Right);

    if (state.up) this.player.move(.Up);

    if (state.down) this.player.move(.Down);
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
