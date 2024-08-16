const std = @import("std");
const unicode = std.unicode;

const cli = @import("cli.zig");
const braille_conv = @import("braille_conv.zig");

pub fn main() !void {
    var input_buf: [1000]u8 = undefined;
    const input = try cli.stdinReadLine(&input_buf);

    const stdout_wrtier = std.io.getStdOut().writer();
    try braille_conv.printKorAsBraille(stdout_wrtier, input);
}
