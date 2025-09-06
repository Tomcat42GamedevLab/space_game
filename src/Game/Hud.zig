const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;

const Game = @import("Game");
const Player = Game.Player;
const Planet = Game.Planet;
const w4 = @import("w4");

pub fn draw(
    allocator: mem.Allocator,
    player: *const Player,
    remaining_time: isize,
    target_planet: *const Planet,
    last_planet_visited: ?*const Planet,
    SECONDS_TO_DIE: comptime_int,
) !void {
    const hud_left = try fmt.allocPrint(
        allocator,
        "x:{d:02.1}\ny:{d:02.1}\nl:{s}",
        .{
            player.position.x,
            player.position.y,
            if (last_planet_visited) |p| p.name else "N/A",
        },
    );
    defer allocator.free(hud_left);

    const hud_right = try fmt.allocPrint(
        allocator,
        "t:{s}\nx:{d:02.1}\ny:{d:02.1}",
        .{
            target_planet.name,
            target_planet.position.x,
            target_planet.position.y,
        },
    );
    defer allocator.free(hud_right);

    w4.DRAW_COLORS.* = 0x0002;
    w4.text(hud_left, 0, 0);
    w4.text(hud_right, w4.SCREEN_SIZE - 80, 0);
    w4.DRAW_COLORS.* = 0x0008;
    w4.rect(1, 50, 10, 100);
    w4.DRAW_COLORS.* = 0x0002;
    const time_size: i32 = @intCast(@divFloor((remaining_time) * 100, SECONDS_TO_DIE));
    w4.rect(1, 150 - time_size, 10, @intCast(time_size));
}
