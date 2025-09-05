//! Simple Bounding Box/AABB Collider implementation
const Game = @import("Game");
const Position = Game.Position;

position: Position = .{},
size: f32 = 0,

pub fn init(position: Position, size: f32) @This() {
    return @This(){ .position = position, .size = size };
}

pub fn collides(this: *const @This(), other: *const @This()) bool {
    return (this.position.x < other.position.x + other.size) and
        (this.position.x + this.size > other.position.x) and
        (this.position.y < other.position.y + other.size) and
        (this.position.y + this.size > other.position.y);
}
