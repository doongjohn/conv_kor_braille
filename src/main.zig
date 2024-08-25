const std = @import("std");
const cli = @import("cli.zig");
const braille_conv = @import("braille_conv.zig");

pub fn main() !void {
    cli.console.init();

    var input_buf: [1000]u21 = undefined;
    const input = try cli.console.readLine(&input_buf);

    const stdout_writer = std.io.getStdOut().writer();
    try braille_conv.printKorAsBraille(stdout_writer.any(), input);
}

test "single jamo" {
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

test "word abbrev" {
    const expectEqualSlices = std.testing.expectEqualSlices;

    var word_len: usize = 0;
    try expectEqualSlices(u21, braille_conv.korWordToBraille(&.{ '그', '래', '서' }, &word_len).?.asCodepoints(), &.{ '⠁', '⠎' });
    try expectEqualSlices(u21, braille_conv.korWordToBraille(&.{ '그', '러', '나' }, &word_len).?.asCodepoints(), &.{ '⠁', '⠉' });
    try expectEqualSlices(u21, braille_conv.korWordToBraille(&.{ '그', '러', '면' }, &word_len).?.asCodepoints(), &.{ '⠁', '⠒' });
    try expectEqualSlices(u21, braille_conv.korWordToBraille(&.{ '그', '러', '므', '로' }, &word_len).?.asCodepoints(), &.{ '⠁', '⠢' });
    try expectEqualSlices(u21, braille_conv.korWordToBraille(&.{ '그', '런', '데' }, &word_len).?.asCodepoints(), &.{ '⠁', '⠝' });
    try expectEqualSlices(u21, braille_conv.korWordToBraille(&.{ '그', '리', '고' }, &word_len).?.asCodepoints(), &.{ '⠁', '⠥' });
    try expectEqualSlices(u21, braille_conv.korWordToBraille(&.{ '그', '리', '하', '여' }, &word_len).?.asCodepoints(), &.{ '⠁', '⠱' });
}

test "sentence" {
    // TODO
    // const expectEqualDeep = std.testing.expectEqualDeep;
    //
    // {
    //     var arr = std.ArrayList(u21).init(std.testing.allocator);
    //     defer arr.deinit();
    //     try braille_conv.arrayListAppendKorAsBraille(&arr, "안녕하세요");
    //     try expectEqualDeep(arr.items, &.{ '⠣', '⠒', '⠉', '⠻', '⠚', '⠠', '⠝', '⠬' });
    // }
}
