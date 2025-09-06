const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;
const Game = @import("Game");
const w4 = @import("w4");

const Player = Game.Player;

pub fn draw(allocator: mem.Allocator, player: *const Player, remaining_time: isize) !void {
    w4.DRAW_COLORS.* = 0x0002;
    const hud = try fmt.allocPrint(
        allocator,
        "x:{d:02.2}\ny:{d:02.2}\nt:{d:02.2}s",
        .{ player.position.x, player.position.y, remaining_time },
    );
    defer allocator.free(hud);

    w4.text(hud, 0, 0);
}
