const std = @import("std");
const cli = @import("cli.zig");
const ckb = @import("conv_kor_braille.zig");

const CodepointIterator = @import("codepoint_iter.zig").CodepointIterator;
const StdInCodepointIterator = CodepointIterator(cli.console, cli.ConsoleReadError);

pub fn main() !void {
    cli.console.init();

    var input_buf: [4]u21 = undefined;
    var input_peek_buf: [4]u21 = undefined;

    const console_read_codepoint = cli.console.methods.readCodepoint;
    var stdin_iter = StdInCodepointIterator.init(undefined, &console_read_codepoint, &input_buf, &input_peek_buf);

    var buf_writer = std.io.bufferedWriter(std.io.getStdOut().writer());
    var writer = buf_writer.writer();

    var converter = ckb.BrailleConverter{};
    try converter.printUntilDelimiter(writer.any(), &stdin_iter, &.{ '\r', '\n' });

    try writer.print("\n", .{});
    try buf_writer.flush();
}
