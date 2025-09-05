const std = @import("std");
const process = std.process;
const ArrayList = std.ArrayList;
const Io = std.Io;
const mem = std.mem;
const math = std.math;
const fmt = std.fmt;
const fs = std.fs;

const usage =
    \\Usage: ./generate_palettes <PALETTE_FILE>... <OUTPUT>
    \\Generates a Zig source file containing palette data from hex files.
    \\ <PALETTE_FILE>... - Paths to hex files containing palette data.
    \\ <OUTPUT> - Path to the output Zig source file.
;

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const args = try process.argsAlloc(arena);

    if (args.len < 3) {
        std.debug.print("{s}\n", .{usage});
        return;
    }

    var lines: ArrayList([]const u8) = .empty;
    for (1..args.len - 1) |i| {
        const file_name = mem.trimEnd(
            u8,
            fs.path.basename(args[i]),
            fs.path.extension(args[i]),
        );
        const file_contents = try fs.cwd().readFileAlloc(
            arena,
            args[i],
            math.maxInt(u32),
        );
        const file_colors = try hexToSlice(arena, file_contents);
        const line = try sliceToSrc(arena, file_name, file_colors);
        try lines.append(arena, line);
    }

    // write to output file
    // const output_filename = args[args.len - 1];
    const output_contents = try mem.join(
        arena,
        "\n",
        lines.items,
    );
    const output_file = args[args.len - 1];
    const output_path = try fs.cwd().createFile(
        output_file,
        .{ .truncate = true },
    );
    defer output_path.close();
    try output_path.writeAll(output_contents);
}

///Converts an zig slice into a zig src code declaration
///
///@param allocator: The allocator to use for constructing the src code.ljjjjjj
///@param name: The name of the slice variable.
///@param slice: The slice to convert.
///
///@return: A string containing the zig source code declaration of the slice.
///
///Example:
///```zig
///const slice = &.{ 0x7c3f58, 0xeb6b6f, 0xf9a875, 0xfff6d3 };
///const src = try sliceToSrc(allocator, "my_palette", slice);
///// Resulting src:
///pub const "my_palette": [4]const u32 = &.{ 0x7c3f58, 0xeb6b6f, 0xf9a875, 0xfff6d3 };
///```
fn sliceToSrc(allocator: mem.Allocator, name: []const u8, slice: []const u32) ![]const u8 {
    return fmt.allocPrint(
        allocator,
        \\pub const @"{s}": [{d}]u32 = .{any};
    ,
        .{ name, slice.len, slice },
    );
}

///Converts an ascii hex file to a slice of u32 values.
///
///@param allocator: The allocator to use for constructing the result slice.
///@param hex: The hex string to convert. It consists of one hex color in the
///format `aabbcc` per line (\n separated). Example hex file:
///
///```hex
///7c3f58
///eb6b6f
///f9a875
///fff6d3
///```
///
///@return: A slice of u32 values, each representing a hex color. Example return:
///
///```zig
///&.{ 0x7c3f58, 0xeb6b6f, 0xf9a875, 0xfff6d3}
///```
fn hexToSlice(allocator: mem.Allocator, hex: []const u8) ![]const u32 {
    var slice: ArrayList(u32) = .empty;
    var colors = mem.tokenizeAny(u8, hex, "\r\n");

    while (colors.next()) |color| try slice.append(
        allocator,
        try fmt.parseUnsigned(u32, color, 16),
    );

    return slice.toOwnedSlice(allocator);
}
