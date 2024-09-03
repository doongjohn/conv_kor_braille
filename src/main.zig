const std = @import("std");
const cli = @import("cli.zig");
const console = cli.console;
const ckb = @import("conv_kor_braille.zig");

const CodepointIterator = @import("codepoint_iter.zig").CodepointIterator;
const StdInCodepointIterator = CodepointIterator(console, cli.ConsoleReadError);

pub fn main() !void {
    console.init();

    var input_buf: [4]u21 = undefined;
    var input_peek_buf: [4]u21 = undefined;
    var stdin_iter = StdInCodepointIterator.init(.{}, &console.methods.readCodepoint, &input_buf, &input_peek_buf);

    var converter = ckb.BrailleConverter{};
    var buf = std.io.bufferedWriter(std.io.getStdOut().writer());
    try converter.printUntilDelimiter(buf.writer().any(), &stdin_iter, &.{ '\r', '\n' });
    try buf.flush();

    try console.print("\n", .{});
}

// Tests
const expectEqualSlices = std.testing.expectEqualSlices;
const expect = std.testing.expect;
const AnyCodepointIterator = CodepointIterator(std.io.AnyReader, std.io.AnyReader.Error);

fn readCodepoint(reader: std.io.AnyReader) !u21 {
    const builtin = @import("builtin");
    return @truncate(try reader.readInt(u32, builtin.cpu.arch.endian()));
}

test "jamo" {
    try expectEqualSlices(u21, ckb.korCharToBraille('ㄱ').?.asCodepoints(), &.{ '⠿', '⠈' });
    try expectEqualSlices(u21, ckb.korCharToBraille('ㄲ').?.asCodepoints(), &.{ '⠿', '⠠', '⠈' });
    try expectEqualSlices(u21, ckb.korCharToBraille('ㄴ').?.asCodepoints(), &.{ '⠿', '⠉' });
    try expectEqualSlices(u21, ckb.korCharToBraille('ㄷ').?.asCodepoints(), &.{ '⠿', '⠊' });
    try expectEqualSlices(u21, ckb.korCharToBraille('ㄹ').?.asCodepoints(), &.{ '⠿', '⠐' });

    try expectEqualSlices(u21, ckb.korCharToBraille('ㅏ').?.asCodepoints(), &.{ '⠿', '⠣' });
    try expectEqualSlices(u21, ckb.korCharToBraille('ㅐ').?.asCodepoints(), &.{ '⠿', '⠗' });
    try expectEqualSlices(u21, ckb.korCharToBraille('ㅒ').?.asCodepoints(), &.{ '⠿', '⠜', '⠗' });
    try expectEqualSlices(u21, ckb.korCharToBraille('ㅚ').?.asCodepoints(), &.{ '⠿', '⠽' });

    try expectEqualSlices(u21, ckb.korCharToBraille('ㄳ').?.asCodepoints(), &.{ '⠿', '⠁', '⠄' });
    try expectEqualSlices(u21, ckb.korCharToBraille('ㄵ').?.asCodepoints(), &.{ '⠿', '⠒', '⠅' });
    try expectEqualSlices(u21, ckb.korCharToBraille('ㄺ').?.asCodepoints(), &.{ '⠿', '⠂', '⠁' });
}

test "composite char" {
    try expectEqualSlices(u21, ckb.korCharToBraille('안').?.asCodepoints(), &.{ '⠣', '⠒' });
    try expectEqualSlices(u21, ckb.korCharToBraille('녕').?.asCodepoints(), &.{ '⠉', '⠱', '⠶' });
    try expectEqualSlices(u21, ckb.korCharToBraille('낮').?.asCodepoints(), &.{ '⠉', '⠣', '⠅' });
    try expectEqualSlices(u21, ckb.korCharToBraille('밤').?.asCodepoints(), &.{ '⠘', '⠣', '⠢' });
    try expectEqualSlices(u21, ckb.korCharToBraille('았').?.asCodepoints(), &.{ '⠣', '⠌' });
    try expectEqualSlices(u21, ckb.korCharToBraille('너').?.asCodepoints(), &.{ '⠉', '⠎' });
    try expectEqualSlices(u21, ckb.korCharToBraille('앉').?.asCodepoints(), &.{ '⠣', '⠒', '⠅' });
    try expectEqualSlices(u21, ckb.korCharToBraille('닭').?.asCodepoints(), &.{ '⠊', '⠣', '⠂', '⠁' });
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

test "word abbrev" {
    var fbs = std.io.fixedBufferStream(&[_]u8{});
    const fbs_reader = fbs.reader();

    var input_buf: [4]u21 = undefined;
    var input_peek_buf: [4]u21 = undefined;
    var input_iter = AnyCodepointIterator.init(fbs_reader.any(), &readCodepoint, &input_buf, &input_peek_buf);

    const inputs = [_][]const u21{
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

    for (inputs, outputs) |input, output| {
        fbs.buffer = std.mem.sliceAsBytes(input);
        fbs.reset();
        try expectEqualSlices(u21, (try ckb.korWordToBraille(&input_iter, &.{})).?.asCodepoints(), output);
    }
}

test "sentence" {
    var fbs = std.io.fixedBufferStream(&[_]u8{});
    const fbs_reader = fbs.reader();

    var input_buf: [4]u21 = undefined;
    var input_peek_buf: [4]u21 = undefined;
    var input_iter = AnyCodepointIterator.init(fbs_reader.any(), &readCodepoint, &input_buf, &input_peek_buf);

    const inputs = [_][]const u32{
        &.{ '안', '녕', '하', '세', '요' },
        &.{ '감', '사', '합', '니', '다' },
    };
    const outputs = [_][]const u21{
        &.{ '⠣', '⠒', '⠉', '⠱', '⠶', '⠚', '⠣', '⠠', '⠝', '⠬' }, // 안녕하세요
        &.{ '⠈', '⠣', '⠢', '⠠', '⠣', '⠚', '⠣', '⠃', '⠉', '⠕', '⠊', '⠣' }, // 감사합니다
    };

    var converter = ckb.BrailleConverter{};

    for (inputs, outputs) |input, output| {
        fbs.buffer = std.mem.sliceAsBytes(input);
        fbs.reset();

        converter.reset();
        var i: usize = 0;
        while (try converter.convertUntilDelimiter(&input_iter, &.{})) |braille| {
            const codepoints = braille.asCodepoints();
            defer i += codepoints.len;

            // std.debug.print("{s}\n", .{braille});
            try expectEqualSlices(u21, output[i .. i + codepoints.len], codepoints);
        }
        try expect(i == output.len);
    }
}
