const builtin = @import("builtin");
const std = @import("std");

pub const ConsoleReadError = error{
    Utf8InvalidStartByte,
    Utf8ExpectedContinuation,
    Utf8OverlongEncoding,
    Utf8EncodesSurrogateHalf,
    Utf8CodepointTooLarge,
    Utf16InvalidStartCodeUnit,
    ExpectedSecondSurrogateHalf,
    EndOfStream,
} || std.fs.File.ReadError;

const console_impl_windows = struct {
    var stdin_handle = std.os.windows.INVALID_HANDLE_VALUE;
    var stdout_writer: std.fs.File.Writer = undefined;

    const win32 = struct {
        const win = std.os.windows;

        extern "kernel32" fn ReadConsoleW(handle: win.HANDLE, buffer: [*]u16, len: win.DWORD, read: *win.DWORD, input_ctrl: ?*anyopaque) callconv(.winapi) bool;
    };

    fn init() void {
        stdin_handle = std.io.getStdIn().handle;
        stdout_writer = std.io.getStdOut().writer();
    }

    fn readCodepoint() ConsoleReadError!u21 {
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
            return try std.unicode.utf16DecodeSurrogatePair(&code_units);
        } else {
            return code_units[0];
        }
    }
};

const console_impl_unix = struct {
    const stdin_reader = std.io.getStdIn().reader();
    const stdout_writer = std.io.getStdOut().writer();

    fn init() void {}

    fn readCodepoint() ConsoleReadError!u21 {
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

    pub fn print(comptime format: []const u8, args: anytype) !void {
        try impl.stdout_writer.print(format, args);
    }

    pub fn readCodepoint() ConsoleReadError!u21 {
        return impl.readCodepoint();
    }

    pub fn readUntilDelimiter(buffer: []u21, delimiter: []const u21) ConsoleReadError![]const u21 {
        for (buffer, 0..) |*cp, i| {
            const codepoint = try readCodepoint();
            if (std.mem.indexOfScalar(u21, delimiter, codepoint)) |_| {
                return buffer[0..i];
            }
            cp.* = codepoint;
        }
        return buffer;
    }

    pub fn readLine(buffer: []u21) ConsoleReadError![]const u21 {
        return try readUntilDelimiter(buffer, &.{ '\r', '\n' });
    }

    pub const methods = struct {
        pub fn print(_: console, comptime format: []const u8, args: anytype) !void {
            try console.print(format, args);
        }

        pub fn readCodepoint(_: console) ConsoleReadError!u21 {
            return try console.readCodepoint();
        }

        pub fn readUntilDelimiter(_: console, buffer: []u21, delimiter: []const u21) ConsoleReadError![]const u21 {
            return try console.readUntilDelimiter(buffer, delimiter);
        }

        pub fn readLine(_: console, buffer: []u21) ConsoleReadError![]const u21 {
            return try console.readLine(buffer);
        }
    };
};
