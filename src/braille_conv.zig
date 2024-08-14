const std = @import("std");

const chosungs = [_]u21{ 'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ' };
const jungsungs = [_]u21{ 'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', 'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ' };
const jongsungs = [_]u21{ '?', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ' };

const brailles_cho = [_]u21{ '⠈', 0, '⠉', '⠊', 1, '⠐', '⠑', '⠘', 2, '⠠', 3, '⠛', '⠨', 4, '⠰', '⠋', '⠓', '⠙', '⠚' };
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
const brailles_jong = [_]u21{ '_', '⠁', 0, 1, '⠒', 2, 3, '⠔', '⠂', 4, 5, 6, 7, 8, 9, 10, '⠢', '⠃', 11, '⠄', '⠌', '⠶', '⠅', '⠆', '⠖', '⠦', '⠲', '⠴' };
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

pub const KorCharIndex = union(enum) {
    chosung: struct {
        i: u8,
    },
    jungsung: struct {
        i: u8,
    },
    jongsung: struct {
        i: u8,
    },
    composite: struct {
        chosung_i: u8,
        jungsung_i: u8,
        jongsung_i: u8,
    },
};

pub const KorCharBraille = struct {
    is_single: bool = false,
    chosung: ?[]const u21,
    jungsung: []const u21,
    jongsung: ?[]const u21,

    pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        if (self.is_single) {
            try writer.print("⠿", .{});
            if (self.chosung == null and self.jongsung == null) {
                for (self.jungsung) |code_point| {
                    try writer.print("{u}", .{code_point});
                }
            } else if (self.chosung) |chosung| {
                for (chosung) |code_point| {
                    try writer.print("{u}", .{code_point});
                }
            } else if (self.jongsung) |jongsung| {
                for (jongsung) |code_point| {
                    try writer.print("{u}", .{code_point});
                }
            }
        } else {
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
    }
};

pub fn korCharToIndex(code_point: u21) ?KorCharIndex {
    const is_single = code_point >= 0x3131 and code_point <= 0x3163;
    const is_composite = code_point >= 0xAC00 and code_point <= 0xD79D;
    if (is_single) {
        if (std.mem.indexOf(u21, &chosungs, &.{code_point})) |i| {
            return .{ .chosung = .{ .i = @intCast(i) } };
        }
        if (std.mem.indexOf(u21, &jungsungs, &.{code_point})) |i| {
            return .{ .jungsung = .{ .i = @intCast(i) } };
        }
        if (std.mem.indexOf(u21, &jongsungs, &.{code_point})) |i| {
            return .{ .jongsung = .{ .i = @intCast(i) } };
        }
    } else if (is_composite) {
        const base = code_point - 0xAC00;
        const cho: u8 = @intCast(base / 28 / 21);
        const jung: u8 = @intCast(base / 28 % 21);
        const jong: u8 = @intCast(base % 28);
        return .{ .composite = .{
            .chosung_i = cho,
            .jungsung_i = jung,
            .jongsung_i = jong,
        } };
    }
    return null;
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
    if (korCharToIndex(code_point)) |char_comp| {
        var braille: KorCharBraille = undefined;
        switch (char_comp) {
            .chosung => |chosung| {
                braille = .{
                    .is_single = true,
                    .chosung = chosungToBraille(chosung.i),
                    .jungsung = &.{},
                    .jongsung = null,
                };
            },
            .jungsung => |jungsung| {
                braille = .{
                    .is_single = true,
                    .chosung = null,
                    .jungsung = jungsungToBraille(jungsung.i),
                    .jongsung = null,
                };
            },
            .jongsung => |jongsung| {
                braille = .{
                    .is_single = true,
                    .chosung = null,
                    .jungsung = &.{},
                    .jongsung = jongsungToBraille(jongsung.i),
                };
            },
            .composite => |composite| {
                braille = .{
                    .chosung = blk: {
                        if (composite.chosung_i == 11) {
                            break :blk null;
                        } else {
                            break :blk chosungToBraille(composite.chosung_i);
                        }
                    },
                    .jungsung = jungsungToBraille(composite.jungsung_i),
                    .jongsung = blk: {
                        if (composite.jongsung_i == 0) {
                            break :blk null;
                        } else {
                            break :blk jongsungToBraille(composite.jongsung_i);
                        }
                    },
                };
            },
        }
        return braille;
    } else {
        return null;
    }
}
