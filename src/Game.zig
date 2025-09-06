const std = @import("std");
const Random = std.Random;
const math = std.math;
const mem = std.mem;
const fmt = std.fmt;

pub const palettes = @import("palettes");
pub const sprites = @import("sprites");
const w4 = @import("w4");

pub const Camera = @import("Game/Camera.zig");
pub const Collider = @import("Game/Collider.zig");
pub const Gamepad = @import("Game/Gamepad.zig");
pub const Hud = @import("Game/Hud.zig");
pub const Planet = @import("Game/Planet.zig");
pub const Player = @import("Game/Player.zig");
pub const Position = @import("Game/Position.zig");
pub const Direction = Position.Direction;

const Game = @This();
pub const PLANET_COUNT = 2;
pub const WORLD_LIMIT_X = 5000;
pub const WORLD_LIMIT_Y = 5000;

pub const State = enum { NotStarted, Running, Win, Over };

const SECONDS_TO_DIE = 80;

state: State = .NotStarted,
frame: usize = 0,
player: Player = .{},
camera: Camera = .{},
gamepad: Gamepad = undefined,
planets: [PLANET_COUNT]Planet = undefined,
target_planet: *const Planet = undefined,
last_planet_visited: ?*const Planet = null,
hud: Hud = .{},
remaining_time: isize = SECONDS_TO_DIE,

pub fn init(allocator: mem.Allocator, rng: std.Random) !@This() {
    _ = allocator; // autofix
    w4.PALETTE.* = palettes.bittersweet;

    const planets: [PLANET_COUNT]Planet = .{
        Planet.init("Bettelgeuse II", .{ .x = 0, .y = 0 }, 160, 0.0),
        Planet.init("Tatooine", .{ .x = 520, .y = 0 }, 100, 0.02),
        // Planet.init("Hoth", .{ .x = 180, .y = 0 }, 40, 0.011),
        // Planet.init("Dagobah", .{ .x = 360, .y = 0 }, 80, 0.0065),
        // Planet.init("Endor", .{ .x = 360, .y = 0 }, 16, 0.004),
        // Planet.init("Yavin IV", .{ .x = 600, .y = 0 }, 80, 0.0018),
    };

    return @This(){
        .player = Player.init(.{ .x = 0, .y = 0 }),
        .camera = Camera.init(.{ .x = 0, .y = 0 }),
        .gamepad = Gamepad.init(w4.GAMEPAD1),
        .planets = planets,
        .target_planet = planet: {
            const rnd = rng.intRangeAtMost(usize, 1, PLANET_COUNT - 1);
            break :planet &planets[rnd];
        },
    };
}

pub fn update(this: *@This(), allocator: mem.Allocator, rng: std.Random) !void {
    loop: switch (this.state) {
        .NotStarted => {
            this.frame += 1;
            const msg = try fmt.allocPrint(allocator,
                \\You are a citizen
                \\of a long gone and 
                \\far away system
                \\orbiting the Mighty
                \\{s}.
                \\
                \\Oxygen is running 
                \\low. Do you think 
                \\that you can beat
                \\the clock?
                \\
                \\Find a planet with 
                \\oxygen so you can 
                \\survive.
                \\
                \\Use Arrow Keys to
                \\move around
                \\
                \\Press 1 to start
            , .{this.planets[0].name});
            defer allocator.free(msg);
            w4.text(msg, 1, 1);
            this.input(rng);
        },
        .Running => {
            defer {
                this.frame += 1;
                if (this.frame % 60 == 0) {
                    this.remaining_time -= 1;
                    if (this.remaining_time <= 10) {
                        w4.PALETTE.*[1] = 0xFF0000;
                    }
                }
            }

            inline for (&this.planets) |*p|
                p.draw(&this.camera, allocator);

            this.player.draw(&this.camera);

            if (this.remaining_time <= 0) {
                this.state = .Over;
                continue :loop this.state;
            }

            const keyPressed = this.input(rng);
            try this.colide(allocator);

            this.player.draw(&this.camera, keyPressed);

            inline for (0..PLANET_COUNT) |i| {
                this.planets[i].draw(&this.camera);
            }
            this.camera.move(this.player.position);
            // inline for (0..PLANET_COUNT) |i| this.planets[i].move(this.frame);
            try Hud.draw(
                allocator,
                &this.player,
                this.remaining_time,
                this.target_planet,
                this.last_planet_visited,
                SECONDS_TO_DIE,
            );
        },
        .Win => {
            const msg = try fmt.allocPrint(
                allocator,
                \\You Win!!!
                \\Time Left: {d}
                \\Press 1 to reset
            ,
                .{
                    this.remaining_time,
                },
            );
            defer allocator.free(msg);

            w4.text(msg, w4.SCREEN_SIZE / 2 - 60, w4.SCREEN_SIZE / 2 - 10);
            _ = this.input(rng);
        },

        .Over => {
            const msg =
                \\Game Over!!!
                \\Press 1 to reset
            ;
            w4.text(msg, w4.SCREEN_SIZE / 2 - 60, w4.SCREEN_SIZE / 2 - 10);
            _ = this.input(rng);
        },
    }
}

fn reset(this: *@This(), rng: std.Random) void {
    this.state = .NotStarted;
    this.frame = 0;
    this.remaining_time = SECONDS_TO_DIE;
    this.player = Player.init(Position.random(rng));
    w4.PALETTE.* = palettes.bittersweet;
}

fn input(this: *@This(), rng: std.Random) bool {
    const gamepadState = this.gamepad.snapshot(.Hold);
    const gameState = this.state;
    var keyPressed = false;

    if (gamepadState.@"1" and gameState == .NotStarted) {
        // TODO: I'm a hack, FIXME later.
        var prng_base: *Random.DefaultPrng = @ptrCast(@alignCast(rng.ptr));
        prng_base.seed(this.frame);

        const srcPlanetIndex = rng.intRangeAtMost(usize, 1, PLANET_COUNT - 1);
        this.player.position = this.planets[srcPlanetIndex].position;

        const dstPlanetIndex = rng.intRangeAtMost(usize, 1, PLANET_COUNT - 1);
        this.target_planet = &this.planets[dstPlanetIndex];

        this.frame = 0;
        this.state = .Running;
    }

    if (gamepadState.@"1" and (gameState == .Over or gameState == .Win))
        _ = this.reset(rng);

    if (gamepadState.left) {
        this.player.move(.Left, this.gamepad);
        keyPressed = true;
    }

    if (gamepadState.right) {
        this.player.move(.Right, this.gamepad);
        keyPressed = true;
    }

    if (gamepadState.up) {
        this.player.move(.Up, this.gamepad);
        keyPressed = true;
    }

    if (gamepadState.down) {
        this.player.move(.Down, this.gamepad);
        keyPressed = true;
    }
    return keyPressed;
}

fn colide(this: *@This(), allocator: mem.Allocator) !void {
    _ = allocator; // autofix
    const player = this.player;
    const planets = this.planets;
    // const target_planet = this.target_planet;
    inline for (&planets) |*planet| {
        if (player.collider.collides(&planet.collider)) {
            this.last_planet_visited = planet;
            w4.trace("collision");
            // this.state = .Win;
            return;
        }
    }
}
