const std = @import("std");
const ckb = @import("conv_kor_braille.zig");

const CodepointIterator = @import("codepoint_iter.zig").CodepointIterator;
const AnyCodepointIterator = CodepointIterator(std.io.AnyReader, std.io.AnyReader.Error);

const expect = std.testing.expect;
const expectEqualSlices = std.testing.expectEqualSlices;

fn readCodepoint(reader: std.io.AnyReader) !u21 {
    const builtin = @import("builtin");
    return @truncate(try reader.readInt(u32, builtin.cpu.arch.endian()));
}

test "jamo" {
    try expectEqualSlices(u21, ckb.korCharToBraille('ㄱ').?.asSlice(), &.{ '⠿', '⠈' });
    try expectEqualSlices(u21, ckb.korCharToBraille('ㄲ').?.asSlice(), &.{ '⠿', '⠠', '⠈' });
    try expectEqualSlices(u21, ckb.korCharToBraille('ㄴ').?.asSlice(), &.{ '⠿', '⠉' });
    try expectEqualSlices(u21, ckb.korCharToBraille('ㄷ').?.asSlice(), &.{ '⠿', '⠊' });
    try expectEqualSlices(u21, ckb.korCharToBraille('ㄹ').?.asSlice(), &.{ '⠿', '⠐' });

    try expectEqualSlices(u21, ckb.korCharToBraille('ㅏ').?.asSlice(), &.{ '⠿', '⠣' });
    try expectEqualSlices(u21, ckb.korCharToBraille('ㅐ').?.asSlice(), &.{ '⠿', '⠗' });
    try expectEqualSlices(u21, ckb.korCharToBraille('ㅒ').?.asSlice(), &.{ '⠿', '⠜', '⠗' });
    try expectEqualSlices(u21, ckb.korCharToBraille('ㅚ').?.asSlice(), &.{ '⠿', '⠽' });

    try expectEqualSlices(u21, ckb.korCharToBraille('ㄳ').?.asSlice(), &.{ '⠿', '⠁', '⠄' });
    try expectEqualSlices(u21, ckb.korCharToBraille('ㄵ').?.asSlice(), &.{ '⠿', '⠒', '⠅' });
    try expectEqualSlices(u21, ckb.korCharToBraille('ㄺ').?.asSlice(), &.{ '⠿', '⠂', '⠁' });
}

test "composite char" {
    try expectEqualSlices(u21, ckb.korCharToBraille('안').?.asSlice(), &.{ '⠣', '⠒' });
    try expectEqualSlices(u21, ckb.korCharToBraille('녕').?.asSlice(), &.{ '⠉', '⠱', '⠶' });
    try expectEqualSlices(u21, ckb.korCharToBraille('낮').?.asSlice(), &.{ '⠉', '⠣', '⠅' });
    try expectEqualSlices(u21, ckb.korCharToBraille('밤').?.asSlice(), &.{ '⠘', '⠣', '⠢' });
    try expectEqualSlices(u21, ckb.korCharToBraille('았').?.asSlice(), &.{ '⠣', '⠌' });
    try expectEqualSlices(u21, ckb.korCharToBraille('너').?.asSlice(), &.{ '⠉', '⠎' });
    try expectEqualSlices(u21, ckb.korCharToBraille('앉').?.asSlice(), &.{ '⠣', '⠒', '⠅' });
    try expectEqualSlices(u21, ckb.korCharToBraille('닭').?.asSlice(), &.{ '⠊', '⠣', '⠂', '⠁' });
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
        fbs.reset();
        fbs.buffer = std.mem.sliceAsBytes(input);

        var last_codepoint: u21 = undefined;
        try expectEqualSlices(u21, (try ckb.korWordToBraille(&input_iter, 0, &last_codepoint)).?.asSlice(), output);
    }
}

test "sentence" {
    var fbs = std.io.fixedBufferStream(&[_]u8{});
    const fbs_reader = fbs.reader();

    var input_buf: [4]u21 = undefined;
    var input_peek_buf: [4]u21 = undefined;
    var input_iter = AnyCodepointIterator.init(fbs_reader.any(), &readCodepoint, &input_buf, &input_peek_buf);

    const inputs = [_][]const u21{
        &.{ '안', '녕', '하', '세', '요' },
        &.{ '감', '사', '합', '니', '다' },
    };
    const outputs = [_][]const u21{
        &.{ '⠣', '⠒', '⠉', '⠱', '⠶', '⠚', '⠣', '⠠', '⠝', '⠬' }, // 안녕하세요
        &.{ '⠈', '⠣', '⠢', '⠠', '⠣', '⠚', '⠣', '⠃', '⠉', '⠕', '⠊', '⠣' }, // 감사합니다
    };

    for (inputs, outputs) |input, output| {
        fbs.reset();
        fbs.buffer = std.mem.sliceAsBytes(input);

        var converter = ckb.BrailleConverter{};
        var i: usize = 0;
        while (try converter.convertNextBraille(&input_iter, 0)) |braille| {
            const brailles = braille.asSlice();
            defer i += brailles.len;
            try expectEqualSlices(u21, output[i .. i + brailles.len], brailles);
        }
        try expect(i == output.len);
    }
}
