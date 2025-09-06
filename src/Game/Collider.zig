//! Simple Bounding Box/AABB Collider implementation
const std = @import("std");
const math = std.math;

const Game = @import("Game");
const Position = Game.Position;

// NOTE: I'm duplicated state. FIXME later.
position: Position = .{},
width: f64 = 0,
height: f64 = 0,

pub fn init(position: Position, width: f64, height: f64) @This() {
    return @This(){ .position = position, .width = width, .height = height };
}

pub fn collides(this: *const @This(), other: *const @This()) bool {
    const x_collision = (this.position.x < other.position.x + other.width) and
        (this.position.x + this.width > other.position.x);

    const y_collision = (this.position.y < other.position.y + other.height) and
        (this.position.y + this.height > other.position.y);

    return x_collision and y_collision;
}
