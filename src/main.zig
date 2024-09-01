const std = @import("std");
const cli = @import("cli.zig");
const braille_conv = @import("braille_conv.zig");

const CodepointIterator = @import("codepoint_iter.zig").CodepointIterator;
const StdInCodepointIterator = CodepointIterator(cli.console, cli.ConsoleReadError);

pub fn main() !void {
    cli.console.init();

    var input_buf: [4]u21 = undefined;
    var input_peek_buf: [4]u21 = undefined;
    var stdin_iter = StdInCodepointIterator.init(
        undefined,
        &cli.console.methods.readCodepoint,
        &input_buf,
        &input_peek_buf,
    );

    const stdout_writer = std.io.getStdOut().writer();
    try braille_conv.writeUntilDelimiter(stdout_writer.any(), &stdin_iter, &.{'\n'});
    try cli.console.print("\n", .{});
}

test "jamo" {
    const expectEqualSlices = std.testing.expectEqualSlices;

    try expectEqualSlices(u21, braille_conv.korCharToBraille('ㄱ').?.asCodepoints(), &.{ '⠿', '⠈' });
    try expectEqualSlices(u21, braille_conv.korCharToBraille('ㄲ').?.asCodepoints(), &.{ '⠿', '⠠', '⠈' });
    try expectEqualSlices(u21, braille_conv.korCharToBraille('ㄴ').?.asCodepoints(), &.{ '⠿', '⠉' });
    try expectEqualSlices(u21, braille_conv.korCharToBraille('ㄷ').?.asCodepoints(), &.{ '⠿', '⠊' });
    try expectEqualSlices(u21, braille_conv.korCharToBraille('ㄹ').?.asCodepoints(), &.{ '⠿', '⠐' });

    try expectEqualSlices(u21, braille_conv.korCharToBraille('ㅏ').?.asCodepoints(), &.{ '⠿', '⠣' });
    try expectEqualSlices(u21, braille_conv.korCharToBraille('ㅐ').?.asCodepoints(), &.{ '⠿', '⠗' });
    try expectEqualSlices(u21, braille_conv.korCharToBraille('ㅒ').?.asCodepoints(), &.{ '⠿', '⠜', '⠗' });
    try expectEqualSlices(u21, braille_conv.korCharToBraille('ㅚ').?.asCodepoints(), &.{ '⠿', '⠽' });

    try expectEqualSlices(u21, braille_conv.korCharToBraille('ㄳ').?.asCodepoints(), &.{ '⠿', '⠁', '⠄' });
    try expectEqualSlices(u21, braille_conv.korCharToBraille('ㄵ').?.asCodepoints(), &.{ '⠿', '⠒', '⠅' });
    try expectEqualSlices(u21, braille_conv.korCharToBraille('ㄺ').?.asCodepoints(), &.{ '⠿', '⠂', '⠁' });
}

test "composite char" {
    const expectEqualSlices = std.testing.expectEqualSlices;

    try expectEqualSlices(u21, braille_conv.korCharToBraille('안').?.asCodepoints(), &.{ '⠣', '⠒' });
    try expectEqualSlices(u21, braille_conv.korCharToBraille('녕').?.asCodepoints(), &.{ '⠉', '⠱', '⠶' });
    try expectEqualSlices(u21, braille_conv.korCharToBraille('낮').?.asCodepoints(), &.{ '⠉', '⠣', '⠅' });
    try expectEqualSlices(u21, braille_conv.korCharToBraille('밤').?.asCodepoints(), &.{ '⠘', '⠣', '⠢' });
    try expectEqualSlices(u21, braille_conv.korCharToBraille('았').?.asCodepoints(), &.{ '⠣', '⠌' });
    try expectEqualSlices(u21, braille_conv.korCharToBraille('너').?.asCodepoints(), &.{ '⠉', '⠎' });
    try expectEqualSlices(u21, braille_conv.korCharToBraille('앉').?.asCodepoints(), &.{ '⠣', '⠒', '⠅' });
    try expectEqualSlices(u21, braille_conv.korCharToBraille('닭').?.asCodepoints(), &.{ '⠊', '⠣', '⠂', '⠁' });
}

test "char abbrev" {
    // TODO
    // 가 나 다 마 바 사 자 카 타 파 하
    // 팠
    // 억 언 얼 연 열 영 옥 온 옹 운 울 은 을 인 것
    // 까 싸 껏
    // 껐
    // 성 썽 정 쩡 청
}

fn readCodepoint(reader: std.io.AnyReader) !u21 {
    const builtin = @import("builtin");
    return @truncate(try reader.readInt(u32, builtin.cpu.arch.endian()));
}

test "word abbrev" {
    const TestCodepointIterator = CodepointIterator(std.io.AnyReader, std.io.AnyReader.Error);

    var buffer: [16]u8 align(@alignOf(u32)) = undefined;
    const buffer_ptr: [*]u32 = @ptrCast(&buffer);

    var fbs = std.io.fixedBufferStream(&buffer);
    const reader = fbs.reader();

    var input_buf: [4]u21 = undefined;
    var input_peek_buf: [4]u21 = undefined;
    var input_iter = TestCodepointIterator.init(
        reader.any(),
        &readCodepoint,
        &input_buf,
        &input_peek_buf,
    );

    const inputs = [_][]const u32{
        &.{ '그', '래', '서' },
        &.{ '그', '러', '나' },
        &.{ '그', '러', '면' },
        &.{ '그', '러', '므', '로' },
        &.{ '그', '런', '데' },
        &.{ '그', '리', '고' },
        &.{ '그', '리', '하', '여' },
    };
    const outputs = [_][]const u21{
        &.{ '⠁', '⠎' }, // 그래서
        &.{ '⠁', '⠉' }, // 그러나
        &.{ '⠁', '⠒' }, // 그러면
        &.{ '⠁', '⠢' }, // 그러므로
        &.{ '⠁', '⠝' }, // 그런데
        &.{ '⠁', '⠥' }, // 그리고
        &.{ '⠁', '⠱' }, // 그리하여
    };

    const expectEqualSlices = std.testing.expectEqualSlices;

    for (inputs, outputs) |input, output| {
        fbs.reset();
        input_iter.reset();
        @memcpy(buffer_ptr, input);
        try expectEqualSlices(u21, (try braille_conv.korWordToBraille(&input_iter)).?.asCodepoints(), output);
    }
}

test "sentence" {
    // const TestCodepointIterator = CodepointIterator(std.io.AnyReader, std.io.AnyReader.Error);
    //
    // var buffer: [16]u8 align(@alignOf(u32)) = undefined;
    // const buffer_ptr: [*]u32 = @ptrCast(&buffer);
    //
    // var fbs = std.io.fixedBufferStream(&buffer);
    // const reader = fbs.reader();
    //
    // var input_buf: [4]u21 = undefined;
    // var input_peek_buf: [4]u21 = undefined;
    // var input_iter = TestCodepointIterator.init(
    //     reader.any(),
    //     &readCodepoint,
    //     &input_buf,
    //     &input_peek_buf,
    // );
    //
    // const inputs = [_][]const u32{
    //     &.{ '안', '녕', '하', '세', '요' },
    // };
    // const outputs = [_][]const u21{
    //     &.{ '⠣', '⠒', '⠉', '⠻', '⠚', '⠠', '⠝', '⠬' }, // 안녕하세요
    // };
    //
    // for (inputs, outputs) |input, output| {
    //     fbs.reset();
    //     input_iter.reset();
    //     @memcpy(buffer_ptr, input);
    //     // TODO
    // }
}
