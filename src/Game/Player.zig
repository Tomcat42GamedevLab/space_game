const Game = @import("Game");
const Position = Game.Position;
const Collider = Game.Collider;
const Direction = Game.Direction;
const w4 = @import("w4");

const sprites = @import("sprites");

position: Position = .{},
direction: Position = Direction.Up,
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

pub fn draw(this: *const @This()) void {
    const x, const y = this.position.normalized();
    const spaceship = sprites.spacheship;

    w4.DRAW_COLORS.* = 0x0032;
    w4.blit(
        &spaceship.data,
        x,
        y,
        spaceship.width,
        spaceship.height,
        spaceship.flags,
    );
}

pub fn move(this: *@This(), dir: Position) void {
    // Ignore the oposite direction
    // if (this.direction.x + dir.x == 0 and
    //     this.direction.y + dir.y == 0)
    //     return;

    if (dir.eql(Direction.Up) or dir.eql(Direction.Down) or
        dir.eql(Direction.Left) or dir.eql(Direction.Right))
    {
        this.direction = dir;
        this.position.x = @mod(this.position.x + dir.x * this.speed, w4.SCREEN_SIZE);
        this.position.y = @mod(this.position.y + dir.y * this.speed, w4.SCREEN_SIZE);
        this.collider.position = this.position;
    }
}
