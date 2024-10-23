const std = @import("std");
const kor_utils = @import("kor_utils.zig");
const kor_braille = @import("kor_braille.zig");

const KorCharIndex = kor_braille.KorCharIndex;
const KorBrailleCluster = kor_braille.KorBrailleCluster;

const korCharToIndex = kor_braille.korCharToIndex;
const choseongToBraille = kor_braille.choseongToBraille;
const jungseongToBraille = kor_braille.jungseongToBraille;
const jongseongToBraille = kor_braille.jongseongToBraille;

/// Convert single korean character to braille.
pub fn korCharToBraille(codepoint: u21) ?KorBrailleCluster {
    if (korCharToIndex(codepoint)) |char_index| {
        var braille: KorBrailleCluster = undefined;
        switch (char_index) {
            .choseong => |choseong| {
                const slice = choseongToBraille(choseong.i);
                braille = .{ .single = .{
                    .buf = .{ '⠿', 0, 0 },
                    .len = @intCast(slice.len + 1),
                } };
                @memcpy(braille.single.buf[1 .. slice.len + 1], slice);
            },
            .jungseong => |jungseong| {
                const slice = jungseongToBraille(jungseong.i);
                braille = .{ .single = .{
                    .buf = .{ '⠿', 0, 0 },
                    .len = @intCast(slice.len + 1),
                } };
                @memcpy(braille.single.buf[1 .. slice.len + 1], slice);
            },
            .jongseong => |jongseong| {
                const slice = jongseongToBraille(jongseong.i);
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
                    const cho = choseongToBraille(composite.choseong_i);
                    braille.composite.choseong = braille.composite.buf[i .. i + cho.len];
                    @memcpy(braille.composite.choseong, cho);
                    i += @intCast(cho.len);
                }

                // jungseong
                const jung = jungseongToBraille(composite.jungseong_i);
                braille.composite.jungseong = braille.composite.buf[i .. i + jung.len];
                @memcpy(braille.composite.jungseong, jung);
                i += @intCast(jung.len);

                // jongseong
                const jong = jongseongToBraille(composite.jongseong_i);
                braille.composite.jongseong = braille.composite.buf[i .. i + jong.len];
                @memcpy(braille.composite.jongseong, jong);
            },
        }
        return braille;
    } else {
        return null;
    }
}

/// Convert korean word to braille abbreviation.
pub fn korWordToBrailleAbbrev(codepoint_iter: anytype, delimiter: u21, last_codepoint: *u21) !?KorBrailleCluster {
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
            // consume codepoints
            try codepoint_iter.skip(word.len + 1);

            // update last codepoint
            last_codepoint.* = word[word.len - 1];

            // return braille
            break .{ .abbrev = .{
                .buf = .{ '⠁', words.braille[i] },
                .len = 2,
            } };
        }
    } else null;
}

pub const KorBrailleConverter = struct {
    is_prev_kor: bool = false,
    prev_codepoint: u21 = 0,

    /// Reset BrailleConverter's state.
    pub fn reset(self: *@This()) void {
        self.is_prev_kor = false;
        self.prev_codepoint = 0;
    }

    inline fn typeCheckCodepointIter(codepoint_iter: anytype) void {
        if (@typeInfo(@TypeOf(codepoint_iter)) != .pointer) {
            @compileError("codepoint_iter must be a pointer to CodepointIterator");
        }
    }

    /// 모음 연쇄
    fn consecutiveMoeum(self: *@This(), codepoint: u21) ?KorBrailleCluster {
        if (self.is_prev_kor) {
            switch (codepoint) {
                '예' => {
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
                    } else {
                        unreachable;
                    }
                },
                '애' => {
                    // 'ㅑ, ㅘ, ㅜ, ㅝ'에 '애'가 붙어 나올 때에는 두 모음자 사이에 구분표 ⠤을 적어 나타낸다.
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
                    } else {
                        unreachable;
                    }
                },
                else => {},
            }
        }
        return null;
    }

    /// Converts next codepoint to braille.
    /// Returns null if EndOfStream or the current codepoint is delimiter.
    /// codepoint_iter's `buffer.len` and `peek_buffer.len` must be at least 4.
    pub fn convertNextBraille(self: *@This(), codepoint_iter: anytype, delimiter: u21) !?KorBrailleCluster {
        // check parameters
        typeCheckCodepointIter(codepoint_iter);
        std.debug.assert(codepoint_iter.ring_buffer.buf.len >= 4);
        std.debug.assert(codepoint_iter.peek_buffer.len >= 4);

        // read codepoint
        var codepoint = codepoint_iter.peek() catch |err| {
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
            if (try korWordToBrailleAbbrev(codepoint_iter, delimiter, &codepoint)) |braille| {
                is_kor = true;
                return braille;
            }
        }

        // consecutive moeum
        if (self.consecutiveMoeum(codepoint)) |braille| {
            return braille;
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

    /// Converts input codepoints to braille and prints it to the writer.
    /// Stops if EndOfStream or the current codepoint is delimiter.
    /// codepoint_iter's `buffer.len` and `peek_buffer.len` must be at least 4.
    pub fn printBrailleUntilDelimiter(self: *@This(), writer: std.io.AnyWriter, codepoint_iter: anytype, delimiter: u21) !void {
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
