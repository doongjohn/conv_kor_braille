const std = @import("std");
const kor_utils = @import("kor_utils.zig");

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
                if (composite.choseong_i != 11) { // ignore 'ㅇ'
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

pub fn korWordToBraille(codepoint_iter: anytype, delimiter: u21, last_codepoint: *u21) !?KorBrailleCluster {
    const slice = try codepoint_iter.peekUntilDelimiter(4, delimiter);

    if (slice.len < 2 or slice[0] != '그') {
        return null;
    }

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

    // find word
    var i: u8 = 0;
    return while (i < words.kor.len) : (i += 1) {
        const word = words.kor[i];
        if (std.mem.startsWith(u21, slice[1..], word)) {
            // update last codepoint
            last_codepoint.* = word[word.len - 1];

            // consume codepoints
            try codepoint_iter.skip(word.len + 1);

            // return braille
            break .{ .abbrev = .{
                .buf = .{ '⠁', words.braille[i] },
                .len = 2,
            } };
        }
    } else null;
}

pub const BrailleConverter = struct {
    is_prev_kor: bool = false,
    prev_codepoint: u21 = undefined,

    /// Reset BrailleConverter's state.
    pub fn reset(self: *@This()) void {
        self.is_prev_kor = false;
    }

    inline fn typeCheckCodepointIter(codepoint_iter: anytype) void {
        if (@typeInfo(@TypeOf(codepoint_iter)) != .pointer) {
            @compileError("codepoint_iter must be a pointer to CodepointIterator");
        }
    }

    /// Convert input codepoints to a braille.
    /// Returns null if end of stream or the next codepoint is delimiter.
    /// `buffer.len` and `peek_buffer.len` must be at least 4.
    pub fn convertNextBraille(self: *@This(), codepoint_iter: anytype, delimiter: u21) !?KorBrailleCluster {
        // check parameters
        typeCheckCodepointIter(codepoint_iter);
        std.debug.assert(codepoint_iter.ring_buffer.buf.len >= 4);
        std.debug.assert(codepoint_iter.peek_buffer.len >= 4);

        // read codepoint
        const codepoint = codepoint_iter.peek() catch |err| {
            switch (err) {
                error.EndOfStream => return null,
                else => return err,
            }
        };

        // check delimiter
        if (codepoint == delimiter) {
            return null;
        }

        // update state
        var is_kor = false;
        defer self.is_prev_kor = is_kor;
        defer self.prev_codepoint = codepoint;

        // convert word
        if (!self.is_prev_kor) {
            if (try korWordToBraille(codepoint_iter, delimiter, &self.prev_codepoint)) |braille| {
                is_kor = true;
                return braille;
            }
        }

        if (self.is_prev_kor) {
            // 모음 연쇄
            if (codepoint == '예') {
                // 모음자에 '예'가 붙어 나올 때에는 그 사이에 구분표 ⠤을 적어 나타낸다.
                if (korCharToIndex(self.prev_codepoint)) |kor_char_index| {
                    switch (kor_char_index) {
                        .composite => |composite| {
                            if (composite.jongseong_i == 0) {
                                return .{ .single = .{
                                    .buf = .{ '⠤', 0, 0 },
                                    .len = @intCast(1),
                                } };
                            }
                        },
                        else => {},
                    }
                }
            } else if (codepoint == '애') {
                // 'ㅑ, ㅘ, ㅜ, ㅝ'에 '애'가 붙어 나올 때에는 두 모음자 사이에 구분표 ⠤을 적어 나타낸다
                if (korCharToIndex(self.prev_codepoint)) |kor_char_index| {
                    switch (kor_char_index) {
                        .composite => |composite| {
                            const target_jungseongs = [_]u8{ 2, 9, 13, 14 }; // ㅑ ㅘ ㅜ ㅝ
                            if (composite.jongseong_i == 0 and
                                std.mem.indexOfScalar(u8, &target_jungseongs, composite.jungseong_i) != null)
                            {
                                return .{ .single = .{
                                    .buf = .{ '⠤', 0, 0 },
                                    .len = @intCast(1),
                                } };
                            }
                        },
                        else => {},
                    }
                }
            }
        }

        // consume codepoint
        try codepoint_iter.skip(1);

        // convert character
        if (korCharToBraille(codepoint)) |braille| {
            is_kor = true;
            return braille;
        } else {
            return error.ConversionFailed;
        }
    }

    /// Convert input codepoints to braille and print it to the writer.
    /// Stops if end of stream or the next codepoint is delimiter.
    /// Size of codepoint_iter's `buffer` and `peek_buffer` must be at least 4.
    pub fn printUntilDelimiter(self: *@This(), writer: std.io.AnyWriter, codepoint_iter: anytype, delimiter: u21) !void {
        // check parameters
        typeCheckCodepointIter(codepoint_iter);
        std.debug.assert(codepoint_iter.ring_buffer.buf.len >= 4);
        std.debug.assert(codepoint_iter.peek_buffer.len >= 4);

        // reset state on function exit
        defer self.reset();

        while (true) {
            // read codepoint
            const codepoint = codepoint_iter.peek() catch |err| {
                switch (err) {
                    error.EndOfStream => break,
                    else => return err,
                }
            };

            // convert to braille
            const conv_result = self.convertNextBraille(codepoint_iter, delimiter) catch |err| {
                switch (err) {
                    error.ConversionFailed => {
                        try writer.print("{u}", .{codepoint});
                        continue;
                    },
                    else => return err,
                }
            };

            // print braille
            if (conv_result) |braille| {
                try writer.print("{s}", .{braille});
            } else {
                break;
            }
        }
    }
};
