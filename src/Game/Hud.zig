const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;
const Game = @import("Game");
const w4 = @import("w4");

const Player = Game.Player;
const MAX_TIME = 30;

pub fn draw(allocator: mem.Allocator, player: *const Player, remaining_time: isize) !void {
    w4.DRAW_COLORS.* = 0x0002;
    const hud = try fmt.allocPrint(
        allocator,
        "x:{d:02.2}\ny:{d:02.2}\nt:{d:02.2}s",
        .{ player.position.x, player.position.y, remaining_time },
    );
    defer allocator.free(hud);

    w4.text(hud, 0, 0);
    w4.DRAW_COLORS.* = 0x0008;
    w4.rect(1, 50, 10, 100);
    w4.DRAW_COLORS.* = 0x0002;
    const time_size: i32 = @intCast(@divFloor((remaining_time) * 100, MAX_TIME));
    w4.rect(1, 150 - time_size, 10, @intCast(time_size));
}
