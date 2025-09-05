const Game = @import("Game");
const Position = Game.Position;

pub const Up = Position.init(0, -1);
pub const Down = Position.init(0, 1);
pub const Left = Position.init(-1, 0);
pub const Right = Position.init(1, 0);
