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

    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{});

    var converter = KorBrailleConverter{};
    try converter.printAsBrailles(&stdout_writer.interface, stdin_iter.iter(), '\n');

    try stdout_writer.interface.print("\n", .{});
    try stdout_writer.interface.flush();
}
