const std = @import("std");
const unicode = std.unicode;

const cli = @import("cli.zig");
const braille_conv = @import("braille_conv.zig");

pub fn main() !void {
    var input_buf: [1000]u8 = undefined;
    const input = try cli.stdinReadLine(&input_buf);

    var iter_utf8 = (try unicode.Utf8View.init(input)).iterator();
    while (iter_utf8.nextCodepoint()) |code_point| {
        if (braille_conv.korCharToBraille(code_point)) |braille| {
            std.debug.print("{s}\n", .{braille});
        } else {
            std.debug.print("failed to convert to braille\n", .{});
        }
    }
}
