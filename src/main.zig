const std = @import("std");
const unicode = std.unicode;

const cli = @import("cli.zig");
const braille_conv = @import("braille_conv.zig");

pub fn main() !void {
    var input_buf: [1000]u8 = undefined;
    const input = try cli.stdinReadLine(&input_buf);

    var i: usize = 0;
    var iter_utf8 = (try unicode.Utf8View.init(input)).iterator();
    while (iter_utf8.nextCodepointSlice()) |code_point_slice| {
        var offset = code_point_slice.len;
        defer i += offset;

        if (braille_conv.korWordToBraille(input[i..], &offset)) |braille| {
            std.debug.print("{s}", .{braille});
            for (0..offset / 3 - 1) |_| {
                _ = iter_utf8.nextCodepointSlice();
            }
            continue;
        }

        const code_point = try unicode.utf8Decode(code_point_slice);
        if (braille_conv.korCharToBraille(code_point)) |braille| {
            std.debug.print("{s}", .{braille});
        } else {
            std.debug.print("{u}", .{code_point});
        }
    }
    std.debug.print("\n", .{});
}
