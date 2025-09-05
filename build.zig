const std = @import("std");
const fmt = std.fmt;
const ArrayList = std.ArrayList;
const mem = std.mem;
const SemanticVersion = std.SemanticVersion;
const zon = std.zon;
const fs = std.fs;
const log = std.log;
const Build = std.Build;
const Step = Build.Step;
const Module = Build.Module;
const Import = Module.Import;
const builtin = @import("builtin");

pub fn build(b: *std.Build) !void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSmall,
    });

    // Modules and Dependencies
    const wasm4_mod = b.createModule(.{
        .root_source_file = b.path("src/wasm4.zig"),
        .target = target,
        .optimize = optimize,
    });
    const game_mod = b.createModule(.{
        .root_source_file = b.path("src/Game.zig"),
        .target = target,
        .optimize = optimize,
    });

    assets: {
        const assets_path = "assets/";
        const tools_path = "tools/";

        palettes: {
            const generate_palettes = b.addRunArtifact(b.addExecutable(.{
                .name = "generate_palettes",
                .root_module = b.createModule(
                    .{
                        .root_source_file = b.path(tools_path ++ "generate_palettes.zig"),
                        .target = b.graph.host,
                    },
                ),
            }));

            const palettes_path = assets_path ++ "palettes/";
            var palettes_dir = try fs.cwd().openDir(palettes_path, .{ .iterate = true });
            defer palettes_dir.close();

            var walker = try palettes_dir.walk(b.allocator);
            defer walker.deinit();

            while (try walker.next()) |entry| switch (entry.kind) {
                .file, .sym_link => generate_palettes.addFileArg(b.path(try fs.path.join(b.allocator, &.{ palettes_path, entry.path }))),
                else => continue,
            };

            const palettes_src = generate_palettes.addOutputFileArg("palettes.zig");
            game_mod.addAnonymousImport("palettes", .{ .root_source_file = palettes_src });

            break :palettes;
        }

        sprites: {
            const convert_sprites = b.addSystemCommand(&.{
                "w4",
                "png2src",
                "--zig",
                "-t",
                assets_path ++ "sprite.mustache",
            });

            const sprites_path = assets_path ++ "sprites/";
            var sprites_dir = try fs.cwd().openDir(sprites_path, .{ .iterate = true });
            defer sprites_dir.close();

            var walker = try sprites_dir.walk(b.allocator);
            defer walker.deinit();

            while (try walker.next()) |entry| switch (entry.kind) {
                .file, .sym_link => convert_sprites.addFileArg(b.path(try fs.path.join(b.allocator, &.{ sprites_path, entry.path }))),
                else => continue,
            };

            const palettes_src = convert_sprites.addPrefixedOutputFileArg("-o", "sprites.zig");
            game_mod.addAnonymousImport("sprites", .{ .root_source_file = palettes_src });

            break :sprites;
        }
        break :assets;
    }

    const game_deps: []const Import = &.{
        .{ .name = "Game", .module = game_mod },
        .{ .name = "w4", .module = wasm4_mod },
    };

    for (game_deps) |dep| game_mod.addImport(dep.name, dep.module);

    // Targets
    const game_exe = b.addExecutable(.{
        .name = "cart",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .optimize = optimize,
            .target = target,
            .imports = &.{
                .{ .name = "Game", .module = game_mod },
                .{ .name = "w4", .module = wasm4_mod },
            },
        }),
    });
    game_exe.entry = .disabled;
    game_exe.root_module.export_symbol_names = &[_][]const u8{ "start", "update" };
    game_exe.import_memory = true;
    game_exe.initial_memory = 65536;
    game_exe.max_memory = 65536;
    game_exe.stack_size = 14752;

    // Check
    const game_check = b.addLibrary(.{
        .root_module = game_mod,
        .linkage = .static,
        .name = "game",
    });
    const check_step = b.step("check", "Check that the build artifacts are up-to-date");
    check_step.dependOn(&game_check.step);

    // Install
    b.installArtifact(game_exe);

    // Run
    const run_exe = b.addSystemCommand(&.{ "w4", "run-native" });
    run_exe.addArtifactArg(game_exe);
    const step_run = b.step("run", "compile and run the cart");
    step_run.dependOn(&run_exe.step);

    // Clean
    const clean_step = b.step("clean", "Remove build artifacts");
    clean_step.dependOn(&b.addRemoveDirTree(b.path(fs.path.basename(b.install_path))).step);
    if (builtin.os.tag != .windows)
        clean_step.dependOn(&b.addRemoveDirTree(b.path(".zig-cache")).step);
}
