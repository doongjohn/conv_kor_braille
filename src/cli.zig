const builtin = @import("builtin");
const std = @import("std");

const win32 = if (builtin.os.tag == .windows) struct {
    const win = std.os.windows;
    const WINAPI = win.WINAPI;

    extern "kernel32" fn ReadConsoleW(handle: win.HANDLE, buffer: [*]u16, len: win.DWORD, read: *win.DWORD, input_ctrl: ?*anyopaque) callconv(WINAPI) bool;
};

pub fn stdinReadLine(buffer: []u8) ![]const u8 {
    switch (builtin.os.tag) {
        .windows => {
            var utf16_buf: [10000]u16 = undefined;
            var utf16_read_count: u32 = undefined;
            if (!win32.ReadConsoleW(std.io.getStdIn().handle, &utf16_buf, utf16_buf.len, &utf16_read_count, null))
                return error.ReadConsoleError;

            const utf8_len = try std.unicode.utf16LeToUtf8(buffer, utf16_buf[0..utf16_read_count]);
            return std.mem.trimRight(u8, buffer[0..utf8_len], "\r\n");
        },
        else => {
            const stdin = std.io.getStdIn().reader();
            return std.mem.trimRight(u8, try stdin.readUntilDelimiter(buffer, '\n'), "\n");
        },
    }
}
