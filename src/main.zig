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

    try expectEqualDeep(braille_conv.korCharToBraille('ㄱ').?.asCodepointSlice(), &[_]u21{ '⠿', '⠈' });
    try expectEqualDeep(braille_conv.korCharToBraille('ㄲ').?.asCodepointSlice(), &[_]u21{ '⠿', '⠠', '⠈' });
    try expectEqualDeep(braille_conv.korCharToBraille('ㄴ').?.asCodepointSlice(), &[_]u21{ '⠿', '⠉' });
    try expectEqualDeep(braille_conv.korCharToBraille('ㄷ').?.asCodepointSlice(), &[_]u21{ '⠿', '⠊' });
    try expectEqualDeep(braille_conv.korCharToBraille('ㄹ').?.asCodepointSlice(), &[_]u21{ '⠿', '⠐' });

    try expectEqualDeep(braille_conv.korCharToBraille('ㅏ').?.asCodepointSlice(), &[_]u21{ '⠿', '⠣' });
    try expectEqualDeep(braille_conv.korCharToBraille('ㅐ').?.asCodepointSlice(), &[_]u21{ '⠿', '⠗' });
    try expectEqualDeep(braille_conv.korCharToBraille('ㅒ').?.asCodepointSlice(), &[_]u21{ '⠿', '⠜', '⠗' });
    try expectEqualDeep(braille_conv.korCharToBraille('ㅚ').?.asCodepointSlice(), &[_]u21{ '⠿', '⠽' });

    try expectEqualDeep(braille_conv.korCharToBraille('ㄳ').?.asCodepointSlice(), &[_]u21{ '⠿', '⠁', '⠄' });
    try expectEqualDeep(braille_conv.korCharToBraille('ㄵ').?.asCodepointSlice(), &[_]u21{ '⠿', '⠒', '⠅' });
    try expectEqualDeep(braille_conv.korCharToBraille('ㄺ').?.asCodepointSlice(), &[_]u21{ '⠿', '⠂', '⠁' });
}

test "composite char" {
    const expectEqualDeep = std.testing.expectEqualDeep;

    try expectEqualDeep(braille_conv.korCharToBraille('안').?.asCodepointSlice(), &[_]u21{ '⠣', '⠒' });
    try expectEqualDeep(braille_conv.korCharToBraille('녕').?.asCodepointSlice(), &[_]u21{ '⠉', '⠱', '⠶' });
    try expectEqualDeep(braille_conv.korCharToBraille('낮').?.asCodepointSlice(), &[_]u21{ '⠉', '⠣', '⠅' });
    try expectEqualDeep(braille_conv.korCharToBraille('밤').?.asCodepointSlice(), &[_]u21{ '⠘', '⠣', '⠢' });
    try expectEqualDeep(braille_conv.korCharToBraille('았').?.asCodepointSlice(), &[_]u21{ '⠣', '⠌' });
    try expectEqualDeep(braille_conv.korCharToBraille('너').?.asCodepointSlice(), &[_]u21{ '⠉', '⠎' });
    try expectEqualDeep(braille_conv.korCharToBraille('앉').?.asCodepointSlice(), &[_]u21{ '⠣', '⠒', '⠅' });
    try expectEqualDeep(braille_conv.korCharToBraille('닭').?.asCodepointSlice(), &[_]u21{ '⠊', '⠣', '⠂', '⠁' });
}

test "char abbrev" {
    // TODO
}

test "word abbrev" {
    const expectEqualDeep = std.testing.expectEqualDeep;

    var word_len: usize = 0;
    try expectEqualDeep(braille_conv.korWordToBraille("그래서", &word_len).?.asCodepointSlice(), &[_]u21{ '⠁', '⠎' });
    try expectEqualDeep(braille_conv.korWordToBraille("그러나", &word_len).?.asCodepointSlice(), &[_]u21{ '⠁', '⠉' });
    try expectEqualDeep(braille_conv.korWordToBraille("그러면", &word_len).?.asCodepointSlice(), &[_]u21{ '⠁', '⠒' });
    try expectEqualDeep(braille_conv.korWordToBraille("그러므로", &word_len).?.asCodepointSlice(), &[_]u21{ '⠁', '⠢' });
    try expectEqualDeep(braille_conv.korWordToBraille("그런데", &word_len).?.asCodepointSlice(), &[_]u21{ '⠁', '⠝' });
    try expectEqualDeep(braille_conv.korWordToBraille("그리고", &word_len).?.asCodepointSlice(), &[_]u21{ '⠁', '⠥' });
    try expectEqualDeep(braille_conv.korWordToBraille("그리하여", &word_len).?.asCodepointSlice(), &[_]u21{ '⠁', '⠱' });
}

test "sentence" {
    // TODO
}
