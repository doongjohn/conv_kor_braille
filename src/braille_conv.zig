const std = @import("std");

const kor_utils = struct {
    pub fn isSingleJamo(codepoint: u21) bool {
        return codepoint >= 'ㄱ' and codepoint <= 'ㅣ';
    }

    pub fn isComposite(codepoint: u21) bool {
        return codepoint >= '가' and codepoint <= '힣';
    }
};

const kor_char_table = struct {
    const cho = [_]u21{ 'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ' };
    const jung = [_]u21{ 'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', 'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ' };
    const jong = [_]u21{ 0, 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ' };
};

const kor_braille_table = struct {
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

    pub fn choseongToBraille(index: u8) []const u21 {
        if (cho[index] <= 4) {
            // choseong with 2 brailles
            return &cho2[cho[index]];
        } else {
            // choseong with 1 braille
            return cho[index .. index + 1];
        }
    }

    pub fn jungseongToBraille(index: u8) []const u21 {
        if (jung[index] <= 3) {
            // jungseong with 2 brailles
            return &jung2[jung[index]];
        } else {
            // jungseong with 1 braille
            return jung[index .. index + 1];
        }
    }

    pub fn jongseongToBraille(index: u8) []const u21 {
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

    pub fn asCodepoints(self: *const @This()) []const u21 {
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
    if (kor_utils.isSingleJamo(codepoint)) {
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

pub fn korCharToBraille(codepoint: u21) ?KorBrailleCluster {
    if (korCharToIndex(codepoint)) |char_index| {
        var braille: KorBrailleCluster = undefined;
        switch (char_index) {
            .choseong => |choseong| {
                const slice = kor_braille_table.choseongToBraille(choseong.i);
                braille = .{ .single = .{
                    .buf = .{ '⠿', 0, 0 },
                    .len = @intCast(slice.len + 1),
                } };
                @memcpy(braille.single.buf[1 .. slice.len + 1], slice);
            },
            .jungseong => |jungseong| {
                const slice = kor_braille_table.jungseongToBraille(jungseong.i);
                braille = .{ .single = .{
                    .buf = .{ '⠿', 0, 0 },
                    .len = @intCast(slice.len + 1),
                } };
                @memcpy(braille.single.buf[1 .. slice.len + 1], slice);
            },
            .jongseong => |jongseong| {
                const slice = kor_braille_table.jongseongToBraille(jongseong.i);
                braille = .{ .single = .{
                    .buf = .{ '⠿', 0, 0 },
                    .len = @intCast(slice.len + 1),
                } };
                @memcpy(braille.single.buf[1 .. slice.len + 1], slice);
            },
            .composite => |composite| {
                braille = .{ .composite = .{
                    .buf = .{0} ** 6,
                    .choseong = &.{},
                    .jungseong = &.{},
                    .jongseong = &.{},
                } };
                var i: u8 = 0;

                // choseong
                if (composite.choseong_i != 11) {
                    // empty if choseong is 'ㅇ'
                    const cho = kor_braille_table.choseongToBraille(composite.choseong_i);
                    braille.composite.choseong = braille.composite.buf[i .. i + cho.len];
                    @memcpy(braille.composite.choseong, cho);
                    i += @intCast(cho.len);
                }

                // jungseong
                const jung = kor_braille_table.jungseongToBraille(composite.jungseong_i);
                braille.composite.jungseong = braille.composite.buf[i .. i + jung.len];
                @memcpy(braille.composite.jungseong, jung);
                i += @intCast(jung.len);

                // jongseong
                const jong = kor_braille_table.jongseongToBraille(composite.jongseong_i);
                braille.composite.jongseong = braille.composite.buf[i .. i + jong.len];
                @memcpy(braille.composite.jongseong, jong);
            },
        }
        return braille;
    } else {
        return null;
    }
}

pub fn korWordToBraille(input: []const u21, word_len: *usize) ?KorBrailleCluster {
    const words = struct {
        const kor = [_][]const u21{
            &.{ '래', '서' },
            &.{ '러', '나' },
            &.{ '러', '면' },
            &.{ '러', '므', '로' },
            &.{ '런', '데' },
            &.{ '리', '고' },
            &.{ '리', '하', '여' },
        };
        const braille = [_]u21{
            '⠎', // 그래서
            '⠉', // 그러나
            '⠒', // 그러면
            '⠢', // 그러므로
            '⠝', // 그런데
            '⠥', // 그리고
            '⠱', // 그리하여
        };
    };

    if (input.len < 3 or !std.mem.startsWith(u21, input, &.{'그'})) {
        // null if slice is shorter than 3 characters or doesn't start with '그'
        return null;
    } else {
        var i: u8 = 0;
        return while (i < words.kor.len) : (i += 1) {
            if (std.mem.startsWith(u21, input[1..], words.kor[i])) {
                word_len.* = words.kor[i].len;
                break KorBrailleCluster{ .abbrev = .{
                    .buf = .{ '⠁', words.braille[i] },
                    .len = 2,
                } };
            }
        } else null;
    }
}

pub fn printKorAsBraille(writer: std.io.AnyWriter, input: []const u21) !void {
    var i: usize = 0;
    var is_prev_kor = false;

    while (i < input.len) {
        var offset: usize = 1;
        defer i += offset;
        defer is_prev_kor = kor_utils.isSingleJamo(input[i]) or kor_utils.isComposite(input[i]);

        if (!is_prev_kor) {
            if (korWordToBraille(input[i..], &offset)) |braille| {
                try writer.print("{s}", .{braille});
                continue;
            }
        }

        if (korCharToBraille(input[i])) |braille| {
            try writer.print("{s}", .{braille});
        } else {
            try writer.print("{u}", .{input[i]});
        }
    }
}
