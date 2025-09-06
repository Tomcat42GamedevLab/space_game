const std = @import("std");
const fmt = std.fmt;
const heap = std.heap;
const FixedBufferAllocator = heap.FixedBufferAllocator;
const Random = std.Random;

const Game = @import("Game");
const w4 = @import("w4");

var game: Game = undefined;

const LOCAL_MEMORY = 4096;
var buffer: [LOCAL_MEMORY]u8 = undefined;
var allocator = FixedBufferAllocator.init(&buffer);
var random = Random.DefaultPrng.init(0);

export fn start() void {
    game = Game.init(
        allocator.allocator(),
        random.random(),
    ) catch @panic("Error: Start");
}

export fn update() void {
    game.update(
        allocator.allocator(),
        random.random(),
    ) catch @panic("Error: Update");
}
