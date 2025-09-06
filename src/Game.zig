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
pub const Sound = @import("Game/sound.zig");

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

endSound: i32 = 0,
timeSound: f32 = 0,
canPlaySound: bool = true,
panicSoundOn: bool = false,
pub const END_SOUND_LEN: usize = 3;
pub const PANIC_SOUND_LEN: usize = 2;

const panicSound: [2]Sound = .{
    Sound.init(100, 100, 0, 36, 14, 14, 30, 1, 2),
    Sound.init(200, 200, 0, 36, 14, 14, 30, 1, 2),
};
const loseSound: [3]Sound = .{
    Sound.init(150, 150, 70, 36, 14, 14, 30, 1, 2),
    Sound.init(100, 100, 70, 36, 14, 14, 30, 1, 2),
    Sound.init(50, 50, 70, 36, 14, 14, 30, 1, 2),
};

pub fn init(allocator: mem.Allocator, rng: std.Random) !@This() {
    _ = rng; // autofix
    _ = allocator; // autofix
    w4.PALETTE.* = palettes.bittersweet;

    const planets: [PLANET_COUNT]Planet = .{
        Planet.init(
            "Bet II",
            .{ .x = 0, .y = 0 },
            80,
            0.0,
        ),
        Planet.init(
            "Alder",
            .{ .x = 100, .y = 0 },
            15,
            0.03,
        ),
    };

    return @This(){
        .player = Player.init(.{ .x = 0, .y = 0 }),
        .camera = Camera.init(.{ .x = 0, .y = 0 }),
        .gamepad = Gamepad.init(w4.GAMEPAD1),
        .planets = planets,
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
                \\Press X to start
            , .{this.planets[0].name});
            defer allocator.free(msg);
            w4.text(msg, 1, 1);
            _ = this.input(rng);
        },
        .Running => {
            defer {
                // if (this.panicSoundOn) {
                //     this.timeSound = this.timeSound + 1;
                //     if (this.t) {
                //         Sound.playSound(panicSound[0]);
                //     } else {
                //         Sound.playSound(panicSound[1]);
                //     }
                //     this.timeSound = false;
                // }
                this.frame += 1;
                if (this.frame % 60 == 0) {
                    this.canPlaySound = true;
                    this.remaining_time -= 1;
                    if (this.remaining_time <= 10) {
                        w4.PALETTE.*[1] = 0xFF0000;
                    }
                }
            }

            inline for (&this.planets) |*p| {
                p.move(this.frame);
                p.draw(&this.camera);
            }

            if (this.remaining_time <= 0) {
                this.state = .Over;
                //Sound.playSound(790, 320, 70, 36, 14, 14, 30, 0, 2);

                continue :loop this.state;
            }

            const keyPressed = this.input(rng);
            try this.colide(allocator);

            if (keyPressed) {
                Sound.playSound(Sound.init(10, 15, 0, 10, 14, 14, 5, 0, 0));
            }
            this.player.draw(&this.camera, keyPressed);

            inline for (0..PLANET_COUNT) |i| {
                this.planets[i].draw(&this.camera);
            }
            this.camera.move(this.player.position);
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
                \\Press X to reset
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
                \\Press X to reset
            ;
            w4.text(msg, w4.SCREEN_SIZE / 2 - 60, w4.SCREEN_SIZE / 2 - 10);
            this.timeSound += 1;
            if (this.canPlaySound) {
                if (this.endSound < END_SOUND_LEN) {
                    Sound.playSound(loseSound[@intCast(this.endSound)]);
                    this.endSound = this.endSound + 1;
                    this.canPlaySound = false;
                }
            }
            if (@mod(this.timeSound, 60) == 0) {
                this.timeSound = 0;
                this.canPlaySound = true;
            }
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
    for (&this.planets) |*p| {
        const msg = try fmt.allocPrint(allocator, "Player Colisor: x:{d:02.1} y:{d:02.1}\nPlanet Colisor: x:{d:02.1} y:{d:02.1}\n", .{
            this.player.collider.position.x,
            this.player.collider.position.y,
            p.collider.position.x,
            p.collider.position.y,
        });
        defer allocator.free(msg);
        w4.trace(msg);

        // Print the tgt planet
        const msgs = try fmt.allocPrint(allocator, "Target Planet: {s}\n", .{this.target_planet.name});
        defer allocator.free(msgs);
        w4.trace(msgs);

        if (this.player.collider.collides(&p.collider)) {
            w4.trace("Colision Detected!\n");
            this.last_planet_visited = p;
            if (p == this.target_planet) this.state = .Win;
        }
    }
}
