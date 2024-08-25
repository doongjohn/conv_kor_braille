const builtin = @import("builtin");
const std = @import("std");

const console_impl_windows = struct {
    var stdin_handle = std.os.windows.INVALID_HANDLE_VALUE;

    const win32 = struct {
        const win = std.os.windows;
        const WINAPI = win.WINAPI;

        extern "kernel32" fn ReadConsoleW(handle: win.HANDLE, buffer: [*]u16, len: win.DWORD, read: *win.DWORD, input_ctrl: ?*anyopaque) callconv(WINAPI) bool;
    };

    fn readCodepoint() !u21 {
        if (stdin_handle == std.os.windows.INVALID_HANDLE_VALUE) {
            stdin_handle = std.io.getStdIn().handle;
        }

        var buf: [2]u16 = undefined;
        var read_count: u32 = undefined;

        if (!win32.ReadConsoleW(std.io.getStdIn().handle, &buf, 1, &read_count, null))
            return error.ReadConsoleError;

        if (std.unicode.utf16IsHighSurrogate(buf[0])) {
            if (!win32.ReadConsoleW(std.io.getStdIn().handle, buf[1..], 1, &read_count, null))
                return error.ReadConsoleError;
            return std.unicode.utf16DecodeSurrogatePair(&buf);
        } else {
            return buf[0];
        }
    }
};

const console_impl_unix = struct {
    const stdin_reader = std.io.getStdIn().reader();

    fn readCodepoint() !u21 {
        var buf: [4]u8 = .{0} ** 4;
        buf[0] = try stdin_reader.readByte();
        const byte_len = try std.unicode.utf8ByteSequenceLength(buf[0]);
        _ = try stdin_reader.readAtLeast(buf[1..], byte_len - 1);
        return try std.unicode.utf8Decode(buf[0..byte_len]);
    }
};

pub const console = struct {
    const impl = switch (builtin.os.tag) {
        .windows => console_impl_windows,
        else => console_impl_unix,
    };

    pub fn readCodepoint() !u21 {
        return impl.readCodepoint();
    }

    pub fn readLine(buffer: []u21) ![]const u21 {
        for (buffer, 0..) |*cp, i| {
            const codepoint = try readCodepoint();
            if (codepoint == '\n') {
                return std.mem.trimRight(u21, buffer[0..i], &[_]u21{ '\r', '\n' });
            }
            cp.* = codepoint;
        }
        return buffer;
    }
};
