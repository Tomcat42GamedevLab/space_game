const Game = @import("Game");
const Position = Game.Position;
const Collider = Game.Collider;
const Direction = Game.Direction;
const w4 = @import("w4");

position: Position = .{},
size: u32 = 1,

pub fn init(position: Position, size: u32) @This() {
    return .{
        .position = position,
        .size = size,
    };
}

pub fn draw(this: *const @This(), offset: Position) void {
    const x, const y = this.position.normalized();
    const x_off, const y_off = offset.normalized();

    w4.DRAW_COLORS.* = 0x0032;
    w4.oval(
        x - x_off,
        y - y_off,
        this.size,
        this.size,
    );
}
