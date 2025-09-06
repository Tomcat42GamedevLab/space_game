const std = @import("std");
const Game = @import("Game");
const Position = Game.Position;
const math = std.math;

const w4 = @import("w4");

pub const Direction = enum {
    Up,
    Down,
    Left,
    Right,

    pub fn getPositionOffset(dir: Direction) Position {
        return switch (dir) {
            .Up => .{ .x = 0, .y = -1 },
            .Down => .{ .x = 0, .y = 1 },
            .Left => .{ .x = -1, .y = 0 },
            .Right => .{ .x = 1, .y = 0 },
        };
    }

    pub fn areOpposites(this: Direction, other: Direction) bool {
        return switch (this) {
            .Up => other == .Down,
            .Down => other == .Up,
            .Left => other == .Right,
            .Right => other == .Left,
        };
    }
};

x: f32 = 0,
y: f32 = 0,

pub fn init(x: f32, y: f32) @This() {
    return @This(){ .x = x, .y = y };
}

pub fn eql(this: @This(), other: @This()) bool {
    const x1, const y1 = this.normalized();
    const x2, const y2 = other.normalized();
    return x1 == x2 and y1 == y2;
}

pub fn random(rng: std.Random) @This() {
    const max = w4.SCREEN_SIZE;
    return @This(){
        .x = rng.float(f32) * max,
        .y = rng.float(f32) * max,
    };
}

/// Normalized into integer coordinates
pub fn normalized(this: @This()) struct { i32, i32 } {
    return .{
        @intFromFloat(math.round(this.x)),
        @intFromFloat(math.round(this.y)),
    };
}
