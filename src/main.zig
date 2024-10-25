const std = @import("std");
const cli = @import("cli.zig");
const kbc = @import("kor_braille_converter.zig");

const KorBrailleConverter = kbc.KorBrailleConverter;
const GenericCodepointIterator = @import("codepoint_iter.zig").GenericCodepointIterator;
const StdInCodepointIterator = GenericCodepointIterator(cli.console, cli.ConsoleReadError);

pub fn main() !void {
    cli.console.init();

    var input_buf: [4]u21 = undefined;
    var input_peek_buf: [4]u21 = undefined;

    const consoleReadCodepoint = cli.console.methods.readCodepoint;
    var stdin_iter = StdInCodepointIterator.init(undefined, &consoleReadCodepoint, &input_buf, &input_peek_buf);

    var buf_writer = std.io.bufferedWriter(std.io.getStdOut().writer());
    var writer = buf_writer.writer();

    var converter = KorBrailleConverter{};
    try converter.printAsBrailles(writer.any(), &stdin_iter, '\n');

    try writer.print("\n", .{});
    try buf_writer.flush();
}
