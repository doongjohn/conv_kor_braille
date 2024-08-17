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
    const jong = [_]u21{ '?', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ' };
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

    pub fn chosungToBraille(index: u8) []const u21 {
        if (cho[index] <= 4) {
            // chosung with 2 brailles
            return &cho2[cho[index]];
        } else {
            // chosung with 1 braille
            return cho[index .. index + 1];
        }
    }

    pub fn jungsungToBraille(index: u8) []const u21 {
        if (jung[index] <= 3) {
            // jungsung with 2 brailles
            return &jung2[jung[index]];
        } else {
            // jungsung with 1 braille
            return jung[index .. index + 1];
        }
    }

    pub fn jongsungToBraille(index: u8) []const u21 {
        if (index == 0) {
            // it has no jongsung
            return &.{};
        } else if (jong[index] <= 11) {
            // jongsung with 2 brailles
            return &jong2[jong[index]];
        } else {
            // jongsung with 1 braille
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
        chosung: []u21,
        jungsung: []u21,
        jongsung: []u21,
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
                return @intCast(composite.chosung.len + composite.jungsung.len + composite.jongsung.len);
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
                const len: u8 = @intCast(composite.chosung.len + composite.jungsung.len + composite.jongsung.len);
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

pub fn korCharToIndex(codepoint: u21) ?KorCharIndex {
    if (kor_utils.isSingleJamo(codepoint)) {
        if (std.mem.indexOf(u21, &kor_char_table.cho, &.{codepoint})) |i| {
            return .{ .chosung = .{ .i = @intCast(i) } };
        }
        if (std.mem.indexOf(u21, &kor_char_table.jung, &.{codepoint})) |i| {
            return .{ .jungsung = .{ .i = @intCast(i) } };
        }
        if (std.mem.indexOf(u21, &kor_char_table.jong, &.{codepoint})) |i| {
            return .{ .jongsung = .{ .i = @intCast(i) } };
        }
    } else if (kor_utils.isComposite(codepoint)) {
        const base = codepoint - '가';
        return .{ .composite = .{
            .chosung_i = @intCast(base / 28 / 21),
            .jungsung_i = @intCast(base / 28 % 21),
            .jongsung_i = @intCast(base % 28),
        } };
    }
    return null;
}

pub fn korCharToBraille(codepoint: u21) ?KorBrailleCluster {
    if (korCharToIndex(codepoint)) |char_index| {
        var braille: KorBrailleCluster = undefined;
        switch (char_index) {
            .chosung => |chosung| {
                const slice = kor_braille_table.chosungToBraille(chosung.i);
                braille = .{ .single = .{
                    .buf = .{ '⠿', 0, 0 },
                    .len = @intCast(slice.len + 1),
                } };
                @memcpy(braille.single.buf[1 .. slice.len + 1], slice);
            },
            .jungsung => |jungsung| {
                const slice = kor_braille_table.jungsungToBraille(jungsung.i);
                braille = .{ .single = .{
                    .buf = .{ '⠿', 0, 0 },
                    .len = @intCast(slice.len + 1),
                } };
                @memcpy(braille.single.buf[1 .. slice.len + 1], slice);
            },
            .jongsung => |jongsung| {
                const slice = kor_braille_table.jongsungToBraille(jongsung.i);
                braille = .{ .single = .{
                    .buf = .{ '⠿', 0, 0 },
                    .len = @intCast(slice.len + 1),
                } };
                @memcpy(braille.single.buf[1 .. slice.len + 1], slice);
            },
            .composite => |composite| {
                braille = .{ .composite = .{
                    .buf = .{0} ** 6,
                    .chosung = &.{},
                    .jungsung = &.{},
                    .jongsung = &.{},
                } };
                var i: u8 = 0;

                // chosung
                if (composite.chosung_i != 11) {
                    // empty if chosung is 'ㅇ'
                    const cho = kor_braille_table.chosungToBraille(composite.chosung_i);
                    braille.composite.chosung = braille.composite.buf[i .. i + cho.len];
                    @memcpy(braille.composite.chosung, cho);
                    i += @intCast(cho.len);
                }

                // jungsung
                const jung = kor_braille_table.jungsungToBraille(composite.jungsung_i);
                braille.composite.jungsung = braille.composite.buf[i .. i + jung.len];
                @memcpy(braille.composite.jungsung, jung);
                i += @intCast(jung.len);

                // jongsung
                const jong = kor_braille_table.jongsungToBraille(composite.jongsung_i);
                braille.composite.jongsung = braille.composite.buf[i .. i + jong.len];
                @memcpy(braille.composite.jongsung, jong);
            },
        }
        return braille;
    } else {
        return null;
    }
}

pub fn korWordToBraille(input: []const u8, word_len: *usize) ?KorBrailleCluster {
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

    if (input.len < 3 * 3 or !std.mem.startsWith(u8, input, "그")) {
        // null if slice is shorter than 3 korean characters or doesn't start with '그'
        return null;
    } else {
        var i: u8 = 0;
        return while (i < words.kor.len) : (i += 1) {
            if (std.mem.startsWith(u8, input[3..], words.kor[i])) {
                word_len.* = words.kor[i].len + 3;
                break KorBrailleCluster{ .abbrev = .{
                    .buf = .{ '⠁', words.braille[i] },
                    .len = 2,
                } };
            }
        } else null;
    }
}

pub fn arrayListAppendKorAsBraille(array_list: *std.ArrayList(u21), input: []const u8) !void {
    var i: usize = 0;
    var is_prev_kor = false;
    var iter_utf8 = (try std.unicode.Utf8View.init(input)).iterator();

    while (iter_utf8.nextCodepointSlice()) |codepoint_slice| {
        var offset = codepoint_slice.len;
        defer i += offset;

        const codepoint = try std.unicode.utf8Decode(codepoint_slice);
        defer is_prev_kor = kor_utils.isSingleJamo(codepoint) or kor_utils.isComposite(codepoint);

        if (!is_prev_kor) {
            if (korWordToBraille(input[i..], &offset)) |braille| {
                try array_list.appendSlice(braille.asCodepoints());
                for (0..offset / 3 - 1) |_| {
                    _ = iter_utf8.nextCodepointSlice();
                }
                continue;
            }
        }

        if (korCharToBraille(codepoint)) |braille| {
            try array_list.appendSlice(braille.asCodepoints());
        } else {
            try array_list.appendSlice(&.{codepoint});
        }
    }
}

pub fn printKorAsBraille(writer: anytype, input: []const u8) !void {
    var i: usize = 0;
    var is_prev_kor = false;
    var iter_utf8 = (try std.unicode.Utf8View.init(input)).iterator();

    while (iter_utf8.nextCodepointSlice()) |codepoint_slice| {
        var offset = codepoint_slice.len;
        defer i += offset;

        const codepoint = try std.unicode.utf8Decode(codepoint_slice);
        defer is_prev_kor = kor_utils.isSingleJamo(codepoint) or kor_utils.isComposite(codepoint);

        if (!is_prev_kor) {
            if (korWordToBraille(input[i..], &offset)) |braille| {
                try writer.print("{s}", .{braille});
                for (0..offset / 3 - 1) |_| {
                    _ = iter_utf8.nextCodepointSlice();
                }
                continue;
            }
        }

        if (korCharToBraille(codepoint)) |braille| {
            try writer.print("{s}", .{braille});
        } else {
            try writer.print("{u}", .{codepoint});
        }
    }
}
