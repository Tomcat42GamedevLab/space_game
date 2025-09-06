const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;
const math = std.math;

const Game = @import("Game");
const Camera = Game.Camera;
const Position = Game.Position;
const Collider = Game.Collider;
const Direction = Game.Direction;
const w4 = @import("w4");

name: []const u8 = "",
position: Position = .{},
size: f32 = 1,
speed: f32 = 0.01,
collider: Collider = .{},

pub fn init(name: []const u8, position: Position, size: f32, speed: f32) @This() {
    return .{
        .name = name,
        .position = position,
        .size = size,
        .speed = speed,
        .collider = Collider.init(
            position,
            size,
            size,
        ),
    };
}

pub fn draw(this: *const @This(), camera: *const Camera, allocator: mem.Allocator) void {
    const posInCameraSystem = camera.worldToCamera(this.position);
    // const posCenterWorld = camera.worldToCamera(Position.init(0, 0));
    const x, const y = posInCameraSystem.normalized();

    w4.DRAW_COLORS.* = 0x0032;
    w4.oval(
        x - @as(i32, @intFromFloat(math.round(this.size) / 2)),
        y - @as(i32, @intFromFloat(math.round(this.size) / 2)),
        @intFromFloat(math.round(this.size)),
        @intFromFloat(math.round(this.size)),
    );

    // Draw the planet orbit
    // w4.DRAW_COLORS.* = 0x0020;
    // const width: u32 = @intFromFloat(math.round(this.position.distance(.{ .x = 0, .y = 0 }) * 2));
    // const height: u32 = @intFromFloat(math.round(this.position.distance(.{ .x = 0, .y = 0 }) * 2));
    // w4.oval(
    //     -@as(i32, @intCast(width / 2)) + @as(i32, @intFromFloat(posCenterWorld.x)),
    //     -@as(i32, @intCast(height / 2)) + @as(i32, @intFromFloat(posCenterWorld.y)),
    //     width,
    //     height,
    // );

    const msg = fmt.allocPrint(
        allocator,
        "{s}\nPos(x:{d},y:{d}) Size:{d}\nBox(x:{d},y:{d}) Size({d},{d})",
        .{
            this.name,
            this.size,
            this.position.x,
            this.position.y,
            this.collider.position.x,
            this.collider.position.y,
            this.collider.width,
            this.collider.height,
        },
    ) catch @panic("Failed to debug");
    defer allocator.free(msg);
    w4.trace(msg);

    // Draw the colisor bounding box
    w4.DRAW_COLORS.* = 0x0040;
    const normalized = this.collider.position;
    const cx, const cy = camera.worldToCamera(normalized).normalized();
    w4.rect(
        cx - @as(i32, @intFromFloat(math.round(this.collider.width) / 2)),
        cy - @as(i32, @intFromFloat(math.round(this.collider.height) / 2)),
        @intFromFloat(math.round(this.collider.width)),
        @intFromFloat(math.round(this.collider.height)),
    );
}

pub fn move(this: *@This(), t: usize) void {
    const angle = @as(f32, @floatFromInt(t)) * this.speed;
    const size = this.position.distance(.{ .x = 0, .y = 0 });

    const relative_x = math.cos(angle) * size;
    const relative_y = math.sin(angle) * size;

    this.position.x = relative_x;
    this.position.y = relative_y;

    this.collider.position = this.position;
}
