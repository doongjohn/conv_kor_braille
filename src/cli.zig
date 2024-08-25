const builtin = @import("builtin");
const std = @import("std");

const console_impl_windows = struct {
    var stdin_handle = std.os.windows.INVALID_HANDLE_VALUE;

    const win32 = struct {
        const win = std.os.windows;
        const WINAPI = win.WINAPI;

        extern "kernel32" fn ReadConsoleW(handle: win.HANDLE, buffer: [*]u16, len: win.DWORD, read: *win.DWORD, input_ctrl: ?*anyopaque) callconv(WINAPI) bool;
    };

    fn init() void {
        stdin_handle = std.io.getStdIn().handle;
    }

    fn readCodepoint() !u21 {
        var code_units: [2]u16 = undefined;
        var read_count: u32 = undefined;

        if (!win32.ReadConsoleW(stdin_handle, &code_units, 1, &read_count, null)) {
            const err = std.os.windows.GetLastError();
            std.debug.panic("Windows API error: {}\n", .{err});
        }

        if (try std.unicode.utf16CodeUnitSequenceLength(code_units[0]) == 2) {
            if (!win32.ReadConsoleW(stdin_handle, code_units[1..], 1, &read_count, null)) {
                const err = std.os.windows.GetLastError();
                std.debug.panic("Windows API error: {}\n", .{err});
            }
            return std.unicode.utf16DecodeSurrogatePair(&code_units);
        } else {
            return code_units[0];
        }
    }
};

const console_impl_unix = struct {
    const stdin_reader = std.io.getStdIn().reader();

    fn init() void {}

    fn readCodepoint() !u21 {
        var code_units: [4]u8 = undefined;
        try stdin_reader.readNoEof(code_units[0..1]);
        const len = try std.unicode.utf8ByteSequenceLength(code_units[0]);
        if (len > 1) {
            try stdin_reader.readNoEof(code_units[1..len]);
        }
        return try std.unicode.utf8Decode(code_units[0..len]);
    }
};

pub const console = struct {
    const impl = switch (builtin.os.tag) {
        .windows => console_impl_windows,
        else => console_impl_unix,
    };

    pub fn init() void {
        return impl.init();
    }

    pub fn readCodepoint() !u21 {
        return impl.readCodepoint();
    }

    pub fn readUntilDelimiter(buffer: []u21, delimiter: []const u21) ![]const u21 {
        for (buffer, 0..) |*cp, i| {
            const codepoint = try readCodepoint();
            if (std.mem.indexOf(u21, delimiter, &.{codepoint})) |_| {
                return buffer[0..i];
            }
            cp.* = codepoint;
        }
        return buffer;
    }

    pub fn readLine(buffer: []u21) ![]const u21 {
        return try readUntilDelimiter(buffer, &.{ '\r', '\n' });
    }
};
