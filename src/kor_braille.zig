const std = @import("std");
const kor_utils = @import("kor_utils.zig");

pub const kor_char_table = struct {
    pub const cho = [_]u21{ 'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ' };
    pub const jung = [_]u21{ 'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', 'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ' };
    pub const jong = [_]u21{ 0, 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ' };
};

pub const KorCharIndex = union(enum) {
    choseong: struct {
        i: u8,
    },
    jungseong: struct {
        i: u8,
    },
    jongseong: struct {
        i: u8,
    },
    composite: struct {
        choseong_i: u8,
        jungseong_i: u8,
        jongseong_i: u8,
    },
};

pub fn korCharToIndex(codepoint: u21) ?KorCharIndex {
    if (kor_utils.isJamo(codepoint)) {
        if (std.mem.indexOfScalar(u21, &kor_char_table.cho, codepoint)) |i| {
            return .{ .choseong = .{ .i = @intCast(i) } };
        }
        if (std.mem.indexOfScalar(u21, &kor_char_table.jung, codepoint)) |i| {
            return .{ .jungseong = .{ .i = @intCast(i) } };
        }
        if (std.mem.indexOfScalar(u21, &kor_char_table.jong, codepoint)) |i| {
            return .{ .jongseong = .{ .i = @intCast(i) } };
        }
    } else if (kor_utils.isComposite(codepoint)) {
        const base = codepoint - '가';
        return .{ .composite = .{
            .choseong_i = @intCast(base / 28 / 21),
            .jungseong_i = @intCast(base / 28 % 21),
            .jongseong_i = @intCast(base % 28),
        } };
    }
    return null;
}

pub const kor_braille_table = struct {
    const cho = [_]u21{ '⠈', 0, '⠉', '⠊', 1, '⠐', '⠑', '⠘', 2, '⠠', 3, '⠛', '⠨', 4, '⠰', '⠋', '⠓', '⠙', '⠚' };
    const cho2 = [_][2]u21{
        .{ '⠠', '⠈' }, // ㄲ
        .{ '⠠', '⠊' }, // ㄸ
        .{ '⠠', '⠘' }, // ㅃ
        .{ '⠠', '⠠' }, // ㅆ
        .{ '⠠', '⠨' }, // ㅉ
    };
    const jung = [_]u21{ '⠣', '⠗', '⠜', 0, '⠎', '⠝', '⠱', '⠌', '⠥', '⠧', 1, '⠽', '⠬', '⠍', '⠏', 2, 3, '⠩', '⠪', '⠺', '⠕' };
    const jung2 = [_][2]u21{
        .{ '⠜', '⠗' }, // ㅒ
        .{ '⠧', '⠗' }, // ㅙ
        .{ '⠏', '⠗' }, // ㅞ
        .{ '⠍', '⠗' }, // ㅟ
    };
    const jong = [_]u21{ 0, '⠁', 0, 1, '⠒', 2, 3, '⠔', '⠂', 4, 5, 6, 7, 8, 9, 10, '⠢', '⠃', 11, '⠄', '⠌', '⠶', '⠅', '⠆', '⠖', '⠦', '⠲', '⠴' };
    const jong2 = [_][2]u21{
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

    fn choseongToBraille(index: u8) []const u21 {
        if (cho[index] <= 4) {
            // choseong with 2 brailles
            return &cho2[cho[index]];
        } else {
            // choseong with 1 braille
            return cho[index .. index + 1];
        }
    }

    fn jungseongToBraille(index: u8) []const u21 {
        if (jung[index] <= 3) {
            // jungseong with 2 brailles
            return &jung2[jung[index]];
        } else {
            // jungseong with 1 braille
            return jung[index .. index + 1];
        }
    }

    fn jongseongToBraille(index: u8) []const u21 {
        if (index == 0) {
            // it has no jongseong
            return &.{};
        } else if (jong[index] <= 11) {
            // jongseong with 2 brailles
            return &jong2[jong[index]];
        } else {
            // jongseong with 1 braille
            return jong[index .. index + 1];
        }
    }
};

pub fn choseongToBraille(index: u8) []const u21 {
    return kor_braille_table.choseongToBraille(index);
}

pub fn jungseongToBraille(index: u8) []const u21 {
    return kor_braille_table.jungseongToBraille(index);
}

pub fn jongseongToBraille(index: u8) []const u21 {
    return kor_braille_table.jongseongToBraille(index);
}

pub const KorBrailleCluster = union(enum) {
    single: struct {
        buf: [3]u21,
        len: u8,
    },
    composite: struct {
        buf: [6]u21,
        choseong: []u21,
        jungseong: []u21,
        jongseong: []u21,
    },
    abbrev: struct {
        buf: [2]u21,
        len: u8,
    },

    pub fn getCodepointLength(self: *const @This()) u8 {
        switch (self.*) {
            .single => |*single| {
                return single.len;
            },
            .composite => |*composite| {
                return @intCast(composite.choseong.len + composite.jungseong.len + composite.jongseong.len);
            },
            .abbrev => |*abbrev| {
                return abbrev.len;
            },
        }
    }

    pub fn asSlice(self: *const @This()) []const u21 {
        switch (self.*) {
            .single => |*single| {
                return single.buf[0..single.len];
            },
            .composite => |*composite| {
                const len: u8 = @intCast(composite.choseong.len + composite.jungseong.len + composite.jongseong.len);
                return composite.buf[0..len];
            },
            .abbrev => |*abbrev| {
                return abbrev.buf[0..abbrev.len];
            },
        }
    }

    pub fn format(self: *const @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        switch (self.*) {
            .single => |*single| {
                for (0..single.len) |i| {
                    try writer.print("{u}", .{single.buf[i]});
                }
            },
            .composite => |*composite| {
                const len = self.getCodepointLength();
                for (0..len) |i| {
                    try writer.print("{u}", .{composite.buf[i]});
                }
            },
            .abbrev => |*abbrev| {
                for (0..abbrev.len) |i| {
                    try writer.print("{u}", .{abbrev.buf[i]});
                }
            },
        }
    }
};
