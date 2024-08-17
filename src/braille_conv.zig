const std = @import("std");

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

    pub fn asCodepointSlice(self: *const @This()) []const u21 {
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

pub fn korWordToBraille(slice: []const u8, word_len: *usize) ?KorBrailleCluster {
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
                break KorBrailleCluster{ .abbrev = .{
                    .buf = .{ '⠁', words.braille[i] },
                    .len = 2,
                } };
            }
        } else null;
    }
}

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
    const is_single_jamo = codepoint >= 0x3131 and codepoint <= 0x3163;
    const is_composite = codepoint >= 0xAC00 and codepoint <= 0xD79D;
    if (is_single_jamo) {
        if (std.mem.indexOf(u21, &kor_char_lookup.cho, &.{codepoint})) |i| {
            return .{ .chosung = .{ .i = @intCast(i) } };
        }
        if (std.mem.indexOf(u21, &kor_char_lookup.jung, &.{codepoint})) |i| {
            return .{ .jungsung = .{ .i = @intCast(i) } };
        }
        if (std.mem.indexOf(u21, &kor_char_lookup.jong, &.{codepoint})) |i| {
            return .{ .jongsung = .{ .i = @intCast(i) } };
        }
    } else if (is_composite) {
        const base = codepoint - 0xAC00;
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

pub fn korCharToBraille(codepoint: u21) ?KorBrailleCluster {
    if (korCharToIndex(codepoint)) |char_index| {
        var braille: KorBrailleCluster = undefined;
        switch (char_index) {
            .chosung => |chosung| {
                const slice = chosungToBraille(chosung.i);
                braille = .{ .single = .{
                    .buf = .{ '⠿', 0, 0 },
                    .len = @intCast(slice.len + 1),
                } };
                @memcpy(braille.single.buf[1 .. slice.len + 1], slice);
            },
            .jungsung => |jungsung| {
                const slice = jungsungToBraille(jungsung.i);
                braille = .{ .single = .{
                    .buf = .{ '⠿', 0, 0 },
                    .len = @intCast(slice.len + 1),
                } };
                @memcpy(braille.single.buf[1 .. slice.len + 1], slice);
            },
            .jongsung => |jongsung| {
                const slice = jongsungToBraille(jongsung.i);
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
                    const cho = chosungToBraille(composite.chosung_i);
                    braille.composite.chosung = braille.composite.buf[i .. i + cho.len];
                    @memcpy(braille.composite.chosung, cho);
                    i += @intCast(cho.len);
                }

                // jungsung
                const jung = jungsungToBraille(composite.jungsung_i);
                braille.composite.jungsung = braille.composite.buf[i .. i + jung.len];
                @memcpy(braille.composite.jungsung, jung);
                i += @intCast(jung.len);

                // jongsung
                const jong = jongsungToBraille(composite.jongsung_i);
                braille.composite.jongsung = braille.composite.buf[i .. i + jong.len];
                @memcpy(braille.composite.jongsung, jong);
            },
        }
        return braille;
    } else {
        return null;
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
        defer is_prev_kor = (codepoint >= 0x3131 and codepoint <= 0x3163) or (codepoint >= 0xAC00 and codepoint <= 0xD79D);

        if (!is_prev_kor) {
            if (korWordToBraille(input[i..], &offset)) |braille| {
                try array_list.appendSlice(braille.asCodepointSlice());
                for (0..offset / 3 - 1) |_| {
                    _ = iter_utf8.nextCodepointSlice();
                }
                continue;
            }
        }

        if (korCharToBraille(codepoint)) |braille| {
            try array_list.appendSlice(braille.asCodepointSlice());
        } else {
            try array_list.appendSlice(codepoint);
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
        defer is_prev_kor = (codepoint >= 0x3131 and codepoint <= 0x3163) or (codepoint >= 0xAC00 and codepoint <= 0xD79D);

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
