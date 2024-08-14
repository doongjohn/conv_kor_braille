const std = @import("std");

const chosungs = [_]u21{ 'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ' };
const jungsungs = [_]u21{ 'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', 'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ' };
const jongsungs = [_]u21{ '?', 'ㄱ', 'ㄲ', 'ᆪ', 'ᆫ', 'ᆬ', 'ᆭ', 'ㄷ', 'ㄹ', 'ᆰ', 'ᆱ', 'ᆲ', 'ᆳ', 'ᆴ', 'ᆵ', 'ᆶ', 'ㅁ', 'ㅂ', 'ᆹ', 'ᆺ', 'ᆻ', 'ᆼ', 'ᆽ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ' };

const brailles_cho = [_]u21{ '⠈', '\u{0}', '⠉', '⠊', '\u{1}', '⠐', '⠑', '⠘', '\u{2}', '⠠', '\u{3}', '⠛', '⠨', '\u{4}', '⠰', '⠋', '⠓', '⠙', '⠚' };
const brailles_cho2 = [_][2]u21{
    .{ '⠠', '⠈' }, // ㄲ
    .{ '⠠', '⠊' }, // ㄸ
    .{ '⠠', '⠘' }, // ㅃ
    .{ '⠠', '⠠' }, // ㅆ
    .{ '⠠', '⠨' }, // ㅉ
};
const brailles_jung = [_]u21{ '⠣', '⠗', '⠜', '⠜', '⠎', '⠝', '⠱', '⠌', '⠥', '⠧', '⠧', '⠽', '⠬', '⠍', '⠏', '⠏', '⠍', '⠩', '⠪', '⠺', '⠕' };
const brailles_jung2 = [_][2]u21{
    .{ '⠁', '⠁' }, // ㅒ
    .{ '⠁', '⠁' }, // ㅙ
    .{ '⠁', '⠁' }, // ㅞ
    .{ '⠁', '⠁' }, // ㅟ
};
const brailles_jong = [_]u21{ '_', '⠁', '\u{0}', '\u{1}', '⠒', '\u{2}', '\u{3}', '⠔', '⠂', '\u{4}', '\u{5}', '\u{6}', '\u{7}', '\u{8}', '\u{9}', '\u{a}', '⠢', '⠃', '\u{b}', '⠄', '⠌', '⠶', '⠅', '⠆', '⠖', '⠦', '⠲', '⠴' };
const brailles_jong2 = [_][2]u21{
    .{ '⠁', '⠁' }, // ㄲ
    .{ '⠁', '⠄' }, // ㄳ
    .{ '⠒', '⠅' }, // ㄵ
    .{ '⠒', '⠴' }, // ㄶ
    .{ '⠂', '⠁' }, // ㄺ
    .{ '⠂', '⠢' }, // ㄻ
    .{ '⠂', '⠃' }, // ㄼ
    .{ '⠂', '⠄' }, // ㄽ
    .{ '⠂', '⠦' }, // ㄾ
    .{ '⠂', '⠲' }, // ㄿ
    .{ '⠂', '⠴' }, // ㅀ
    .{ '⠃', '⠄' }, // ㅄ
};

pub const KorCharIndex = struct {
    chosung_i: u8,
    jungsung_i: u8,
    jongsung_i: u8,
};

pub const KorCharBraille = struct {
    chosung: ?[]const u21,
    jungsung: []const u21,
    jongsung: ?[]const u21,

    pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        if (self.chosung) |chosung| {
            for (chosung) |code_point| {
                try writer.print("{u}", .{code_point});
            }
        }
        for (self.jungsung) |code_point| {
            try writer.print("{u}", .{code_point});
        }
        if (self.jongsung) |jongsung| {
            for (jongsung) |code_point| {
                try writer.print("{u}", .{code_point});
            }
        }
    }
};

pub fn splitKorChar(code_point: u21) ?KorCharIndex {
    const is_kor_char = code_point >= 0xAC00 and code_point <= 0xD79D;
    if (is_kor_char) {
        const base = code_point - 0xAC00;
        const cho: u8 = @intCast(base / 28 / 21);
        const jung: u8 = @intCast(base / 28 % 21);
        const jong: u8 = @intCast(base % 28);
        return .{
            .chosung_i = cho,
            .jungsung_i = jung,
            .jongsung_i = jong,
        };
    } else {
        return null;
    }
}

pub fn chosungToBraille(index: u8) []const u21 {
    if (brailles_cho[index] <= 4) {
        return &brailles_cho2[brailles_cho[index]];
    } else {
        return brailles_cho[index .. index + 1];
    }
}

pub fn jungsungToBraille(index: u8) []const u21 {
    if (brailles_jung[index] <= 3) {
        return &brailles_jung2[brailles_jung[index]];
    } else {
        return brailles_jung[index .. index + 1];
    }
}

pub fn jongsungToBraille(index: u8) []const u21 {
    if (brailles_jong[index] <= 11) {
        return &brailles_jong2[brailles_jong[index]];
    } else {
        return brailles_jong[index .. index + 1];
    }
}

pub fn korCharToBraille(code_point: u21) ?KorCharBraille {
    if (splitKorChar(code_point)) |char_comp| {
        const braille = KorCharBraille{
            .chosung = blk: {
                if (char_comp.chosung_i == 11) {
                    break :blk null;
                } else {
                    break :blk chosungToBraille(char_comp.chosung_i);
                }
            },
            .jungsung = jungsungToBraille(char_comp.jungsung_i),
            .jongsung = blk: {
                if (char_comp.jongsung_i == 0) {
                    break :blk null;
                } else {
                    break :blk jongsungToBraille(char_comp.jongsung_i);
                }
            },
        };
        return braille;
    } else {
        return null;
    }
}
