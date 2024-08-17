const std = @import("std");

const cli = @import("cli.zig");
const braille_conv = @import("braille_conv.zig");

pub fn main() !void {
    var input_buf: [1000]u8 = undefined;
    const input = try cli.stdinReadLine(&input_buf);

    const stdout_writer = std.io.getStdOut().writer();
    try braille_conv.printKorAsBraille(stdout_writer, input);
}

test "single jamo" {
    const expectEqualDeep = std.testing.expectEqualDeep;

    try expectEqualDeep(braille_conv.korCharToBraille('ㄱ').?.asCodepoints(), &[_]u21{ '⠿', '⠈' });
    try expectEqualDeep(braille_conv.korCharToBraille('ㄲ').?.asCodepoints(), &[_]u21{ '⠿', '⠠', '⠈' });
    try expectEqualDeep(braille_conv.korCharToBraille('ㄴ').?.asCodepoints(), &[_]u21{ '⠿', '⠉' });
    try expectEqualDeep(braille_conv.korCharToBraille('ㄷ').?.asCodepoints(), &[_]u21{ '⠿', '⠊' });
    try expectEqualDeep(braille_conv.korCharToBraille('ㄹ').?.asCodepoints(), &[_]u21{ '⠿', '⠐' });

    try expectEqualDeep(braille_conv.korCharToBraille('ㅏ').?.asCodepoints(), &[_]u21{ '⠿', '⠣' });
    try expectEqualDeep(braille_conv.korCharToBraille('ㅐ').?.asCodepoints(), &[_]u21{ '⠿', '⠗' });
    try expectEqualDeep(braille_conv.korCharToBraille('ㅒ').?.asCodepoints(), &[_]u21{ '⠿', '⠜', '⠗' });
    try expectEqualDeep(braille_conv.korCharToBraille('ㅚ').?.asCodepoints(), &[_]u21{ '⠿', '⠽' });

    try expectEqualDeep(braille_conv.korCharToBraille('ㄳ').?.asCodepoints(), &[_]u21{ '⠿', '⠁', '⠄' });
    try expectEqualDeep(braille_conv.korCharToBraille('ㄵ').?.asCodepoints(), &[_]u21{ '⠿', '⠒', '⠅' });
    try expectEqualDeep(braille_conv.korCharToBraille('ㄺ').?.asCodepoints(), &[_]u21{ '⠿', '⠂', '⠁' });
}

test "composite char" {
    const expectEqualDeep = std.testing.expectEqualDeep;

    try expectEqualDeep(braille_conv.korCharToBraille('안').?.asCodepoints(), &[_]u21{ '⠣', '⠒' });
    try expectEqualDeep(braille_conv.korCharToBraille('녕').?.asCodepoints(), &[_]u21{ '⠉', '⠱', '⠶' });
    try expectEqualDeep(braille_conv.korCharToBraille('낮').?.asCodepoints(), &[_]u21{ '⠉', '⠣', '⠅' });
    try expectEqualDeep(braille_conv.korCharToBraille('밤').?.asCodepoints(), &[_]u21{ '⠘', '⠣', '⠢' });
    try expectEqualDeep(braille_conv.korCharToBraille('았').?.asCodepoints(), &[_]u21{ '⠣', '⠌' });
    try expectEqualDeep(braille_conv.korCharToBraille('너').?.asCodepoints(), &[_]u21{ '⠉', '⠎' });
    try expectEqualDeep(braille_conv.korCharToBraille('앉').?.asCodepoints(), &[_]u21{ '⠣', '⠒', '⠅' });
    try expectEqualDeep(braille_conv.korCharToBraille('닭').?.asCodepoints(), &[_]u21{ '⠊', '⠣', '⠂', '⠁' });
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
    const expectEqualDeep = std.testing.expectEqualDeep;

    var word_len: usize = 0;
    try expectEqualDeep(braille_conv.korWordToBraille("그래서", &word_len).?.asCodepoints(), &[_]u21{ '⠁', '⠎' });
    try expectEqualDeep(braille_conv.korWordToBraille("그러나", &word_len).?.asCodepoints(), &[_]u21{ '⠁', '⠉' });
    try expectEqualDeep(braille_conv.korWordToBraille("그러면", &word_len).?.asCodepoints(), &[_]u21{ '⠁', '⠒' });
    try expectEqualDeep(braille_conv.korWordToBraille("그러므로", &word_len).?.asCodepoints(), &[_]u21{ '⠁', '⠢' });
    try expectEqualDeep(braille_conv.korWordToBraille("그런데", &word_len).?.asCodepoints(), &[_]u21{ '⠁', '⠝' });
    try expectEqualDeep(braille_conv.korWordToBraille("그리고", &word_len).?.asCodepoints(), &[_]u21{ '⠁', '⠥' });
    try expectEqualDeep(braille_conv.korWordToBraille("그리하여", &word_len).?.asCodepoints(), &[_]u21{ '⠁', '⠱' });
}

test "sentence" {
    // TODO
    // const expectEqualDeep = std.testing.expectEqualDeep;
    //
    // {
    //     var arr = std.ArrayList(u21).init(std.testing.allocator);
    //     defer arr.deinit();
    //     try braille_conv.arrayListAppendKorAsBraille(&arr, "안녕하세요");
    //     try expectEqualDeep(arr.items, &[_]u21{ '⠣', '⠒', '⠉', '⠻', '⠚', '⠠', '⠝', '⠬' });
    // }
}
