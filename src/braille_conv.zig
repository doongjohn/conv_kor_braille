const std = @import("std");

pub const KorCharBraille = union(enum) {
    single: struct {
        arr: [3]u21,
        len: u8,
    },
    abbrev: struct {
        arr: [2]u21,
        len: u8,
    },
    composite: struct {
        chosung: []const u21,
        jungsung: []const u21,
        jongsung: []const u21,
    },

    pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        switch (self) {
            .single => |single| {
                for (0..single.len) |i| {
                    try writer.print("{u}", .{single.arr[i]});
                }
            },
            .abbrev => |abbrev| {
                for (0..abbrev.len) |i| {
                    try writer.print("{u}", .{abbrev.arr[i]});
                }
            },
            .composite => |composite| {
                for (composite.chosung) |code_point| {
                    try writer.print("{u}", .{code_point});
                }
                for (composite.jungsung) |code_point| {
                    try writer.print("{u}", .{code_point});
                }
                for (composite.jongsung) |code_point| {
                    try writer.print("{u}", .{code_point});
                }
            },
        }
    }
};

pub fn korWordToBraille(slice: []const u8, word_len: *usize) ?KorCharBraille {
    const words = struct {
        const kor = [_][]const u8{
            "래서",
            "러나",
            "러면",
            "러므로",
            "런데",
            "리고",
            "리하여",
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

    if (slice.len < 3 * 3 or !std.mem.startsWith(u8, slice, "그")) {
        return null;
    } else {
        var i: u8 = 0;
        return while (i < words.kor.len) : (i += 1) {
            if (std.mem.startsWith(u8, slice[3..], words.kor[i])) {
                word_len.* = words.kor[i].len + 3;
                break KorCharBraille{ .abbrev = .{
                    .arr = .{ '⠁', words.braille[i] },
                    .len = 2,
                } };
            }
        } else null;
    }
}

const kor_char_lookup = struct {
    const cho = [_]u21{ 'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ' };
    const jung = [_]u21{ 'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', 'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ' };
    const jong = [_]u21{ '?', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ' };
};

const kor_braille_lookup = struct {
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
    const jong = [_]u21{ '_', '⠁', 0, 1, '⠒', 2, 3, '⠔', '⠂', 4, 5, 6, 7, 8, 9, 10, '⠢', '⠃', 11, '⠄', '⠌', '⠶', '⠅', '⠆', '⠖', '⠦', '⠲', '⠴' };
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

pub fn korCharToIndex(code_point: u21) ?KorCharIndex {
    const is_single = code_point >= 0x3131 and code_point <= 0x3163;
    const is_composite = code_point >= 0xAC00 and code_point <= 0xD79D;
    if (is_single) {
        if (std.mem.indexOf(u21, &kor_char_lookup.cho, &.{code_point})) |i| {
            return .{ .chosung = .{ .i = @intCast(i) } };
        }
        if (std.mem.indexOf(u21, &kor_char_lookup.jung, &.{code_point})) |i| {
            return .{ .jungsung = .{ .i = @intCast(i) } };
        }
        if (std.mem.indexOf(u21, &kor_char_lookup.jong, &.{code_point})) |i| {
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
    if (kor_braille_lookup.cho[index] <= 4) {
        // chosung with 2 brailles
        return &kor_braille_lookup.cho2[kor_braille_lookup.cho[index]];
    } else {
        // chosung with 1 braille
        return kor_braille_lookup.cho[index .. index + 1];
    }
}

pub fn jungsungToBraille(index: u8) []const u21 {
    if (kor_braille_lookup.jung[index] <= 3) {
        // jungsung with 2 brailles
        return &kor_braille_lookup.jung2[kor_braille_lookup.jung[index]];
    } else {
        // jungsung with 1 braille
        return kor_braille_lookup.jung[index .. index + 1];
    }
}

pub fn jongsungToBraille(index: u8) []const u21 {
    if (index == 0) {
        // it has no jongsung
        return &.{};
    } else if (kor_braille_lookup.jong[index] <= 11) {
        // jongsung with 2 brailles
        return &kor_braille_lookup.jong2[kor_braille_lookup.jong[index]];
    } else {
        // jongsung with 1 braille
        return kor_braille_lookup.jong[index .. index + 1];
    }
}

pub fn korCharToBraille(code_point: u21) ?KorCharBraille {
    if (korCharToIndex(code_point)) |char_index| {
        var braille: KorCharBraille = undefined;
        switch (char_index) {
            .chosung => |chosung| {
                const slice = chosungToBraille(chosung.i);
                braille = .{ .single = .{
                    .arr = .{ '⠿', 0, 0 },
                    .len = @intCast(slice.len + 1),
                } };
                @memcpy(braille.single.arr[1 .. slice.len + 1], slice);
            },
            .jungsung => |jungsung| {
                const slice = jungsungToBraille(jungsung.i);
                braille = .{ .single = .{
                    .arr = .{ '⠿', 0, 0 },
                    .len = @intCast(slice.len + 1),
                } };
                @memcpy(braille.single.arr[1 .. slice.len + 1], slice);
            },
            .jongsung => |jongsung| {
                const slice = jongsungToBraille(jongsung.i);
                braille = .{ .single = .{
                    .arr = .{ '⠿', 0, 0 },
                    .len = @intCast(slice.len + 1),
                } };
                @memcpy(braille.single.arr[1 .. slice.len + 1], slice);
            },
            .composite => |composite| {
                braille = .{
                    .composite = .{
                        .chosung = blk: {
                            if (composite.chosung_i == 11) {
                                // empty if chosung is 'ㅇ'
                                break :blk &.{};
                            } else {
                                break :blk chosungToBraille(composite.chosung_i);
                            }
                        },
                        .jungsung = jungsungToBraille(composite.jungsung_i),
                        .jongsung = jongsungToBraille(composite.jongsung_i),
                    },
                };
            },
        }
        return braille;
    } else {
        return null;
    }
}
