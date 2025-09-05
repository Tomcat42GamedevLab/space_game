const w4 = @import("w4");

gamepad: *const u8,
state: u8 = 0,

pub const State = struct {
    left: bool = false,
    right: bool = false,
    up: bool = false,
    down: bool = false,
    @"1": bool = false,
    @"2": bool = false,
};

pub const Type = enum { Hold, PressAndRelease };

pub fn init(gamepad: *const u8) @This() {
    return .{ .gamepad = gamepad };
}

pub fn snapshot(this: *@This(), @"type": Type) State {
    const state = this.gamepad.*;
    defer this.state = state;

    const pressed = switch (@"type") {
        .Hold => state & (state | this.state),
        .PressAndRelease => state & (state ^ this.state),
    };

    return State{
        .left = (pressed & w4.BUTTON_LEFT) != 0,
        .right = (pressed & w4.BUTTON_RIGHT) != 0,
        .up = (pressed & w4.BUTTON_UP) != 0,
        .down = (pressed & w4.BUTTON_DOWN) != 0,
        .@"1" = (pressed & w4.BUTTON_1) != 0,
        .@"2" = (pressed & w4.BUTTON_2) != 0,
    };
}
