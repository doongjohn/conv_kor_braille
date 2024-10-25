const std = @import("std");

/// Comptime interface
pub fn AnyCodepointIterator(PtrT: type) type {
    return struct {
        impl: PtrT,

        pub inline fn getBufferCapacity(self: @This()) usize {
            return self.impl.getBufferCapacity();
        }

        /// Reset internal state.
        /// Peeked data will be discarded.
        pub inline fn reset(self: @This()) void {
            self.impl.reset();
        }

        pub inline fn next(self: @This()) !u21 {
            return self.impl.next();
        }

        /// Discard `n` items.
        pub inline fn skip(self: @This(), n: usize) !void {
            try self.impl.skip(n);
        }

        pub inline fn peek(self: @This()) !u21 {
            return self.impl.peek();
        }

        /// Peek `n` items and return it as a slice.
        /// Returned slice is valid until `fn next` or `fn skip` is called.
        pub inline fn peekUntilDelimiter(self: @This(), n: usize, delimiter: u21) ![]const u21 {
            return self.impl.peekUntilDelimiter(n, delimiter);
        }
    };
}

inline fn checkFnSignature(comptime lhs: anytype, comptime fn_name: []const u8, Signature: type) void {
    const FnType = @TypeOf(@field(lhs, fn_name));
    if (@typeInfo(FnType) != .@"fn") {
        @compileError(std.fmt.comptimePrint("T.{s} is not a function!", .{fn_name}));
    }
    if (@typeInfo(Signature) != .@"fn") {
        @compileError(std.fmt.comptimePrint("Signature is not a function!", .{}));
    }
    if (FnType != Signature) {
        @compileError(std.fmt.comptimePrint("`fn {s}` mismatch!\nfound: {}\nexpect: {}", .{ fn_name, FnType, Signature }));
    }
}

/// Create AnyCodepointIterator from implementation.
/// Lifetime of returned AnyCodepointIterator is same as the implementation.
pub fn initAnyCodepointIterator(codepoint_iter_impl: anytype) AnyCodepointIterator(@TypeOf(codepoint_iter_impl)) {
    switch (@typeInfo(@TypeOf(codepoint_iter_impl))) {
        .pointer => |pointer| {
            const T = pointer.child;
            checkFnSignature(T, "getBufferCapacity", fn (self: T) usize);
            checkFnSignature(T, "reset", fn (self: *T) void);
            checkFnSignature(T, "next", fn (self: *T) anyerror!u21);
            checkFnSignature(T, "skip", fn (self: *T, n: usize) anyerror!void);
            checkFnSignature(T, "peek", fn (self: *T) anyerror!u21);
            checkFnSignature(T, "peekUntilDelimiter", fn (self: *T, n: usize, delimiter: u21) anyerror![]const u21);
        },
        else => {
            @compileError(std.fmt.comptimePrint("Type T must be a pointer to CodepointIterator but found: {}", .{@TypeOf(codepoint_iter_impl)}));
        },
    }
    return .{ .impl = codepoint_iter_impl };
}

pub fn GenericCodepointIterator(Context: type, ReadError: type) type {
    const GenericRingBuffer = @import("generic_ringbuffer.zig").GenericRingBuffer;

    return struct {
        context: Context,
        readFn: *const fn (context: Context) ReadError!u21,
        ring_buffer: GenericRingBuffer(u21),
        peek_buffer: []u21,

        /// Create a new CodepointIterator.
        /// Size of `buffer` and `peek_buffer` must be same.
        /// - `buffer` is used for `ring_buffer`.
        /// - `peek_buffer` is used for `fn peekUntilDelimiter`.
        pub fn init(
            context: Context,
            readFn: *const fn (context: Context) ReadError!u21,
            buffer: []u21,
            peek_buffer: []u21,
        ) @This() {
            // check parameters
            std.debug.assert(buffer.len == peek_buffer.len);

            return .{
                .context = context,
                .readFn = readFn,
                .ring_buffer = GenericRingBuffer(u21){ .buf = buffer },
                .peek_buffer = peek_buffer,
            };
        }

        pub fn getBufferCapacity(self: @This()) usize {
            return self.ring_buffer.buf.len;
        }

        /// Reset internal state.
        /// Peeked data will be discarded.
        pub fn reset(self: *@This()) void {
            self.ring_buffer.clear();
        }

        pub fn next(self: *@This()) anyerror!u21 {
            if (self.ring_buffer.size == 0) {
                return try self.readFn(self.context);
            } else {
                return try self.ring_buffer.popFront();
            }
        }

        /// Discard `n` items.
        pub fn skip(self: *@This(), n: usize) anyerror!void {
            for (0..n) |_| {
                _ = try self.next();
            }
        }

        pub fn peek(self: *@This()) anyerror!u21 {
            if (self.ring_buffer.size == 0) {
                const codepoint = try self.readFn(self.context);
                try self.ring_buffer.pushBack(codepoint);
            }
            return try self.ring_buffer.getFront();
        }

        /// Peek `n` items and return it as a slice.
        /// Returned slice is valid until `fn next` or `fn skip` is called.
        pub fn peekUntilDelimiter(self: *@This(), n: usize, delimiter: u21) anyerror![]const u21 {
            if (n == 0 or self.ring_buffer.buf.len < n) {
                return &.{};
            }

            blk: {
                // Don't read more if the last codepoint is delimiter
                if (self.ring_buffer.size > 0) {
                    if (try self.ring_buffer.getBack() == delimiter) {
                        break :blk;
                    }
                }

                // Read more codepoints
                if (self.ring_buffer.size < n) {
                    const read_count = n - self.ring_buffer.size;
                    for (0..read_count) |_| {
                        const codepoint = self.readFn(self.context) catch |err| {
                            switch (err) {
                                error.EndOfStream => break,
                                else => return err,
                            }
                        };
                        try self.ring_buffer.pushBack(codepoint);

                        // check delimiter
                        if (codepoint == delimiter) {
                            break;
                        }
                    }
                }
            }

            // Return as a slice
            if (self.ring_buffer.head <= self.ring_buffer.tail) {
                return self.ring_buffer.buf[self.ring_buffer.head .. self.ring_buffer.tail + 1];
            } else {
                const front_seg_size = self.ring_buffer.buf.len - self.ring_buffer.head;

                const ring_front_seg = self.ring_buffer.buf[self.ring_buffer.head .. self.ring_buffer.head + front_seg_size];
                const ring_back_seg = self.ring_buffer.buf[0 .. self.ring_buffer.tail + 1];

                const peek_front_seg = self.peek_buffer[0..front_seg_size];
                const peek_back_seg = self.peek_buffer[front_seg_size..self.ring_buffer.size];

                @memcpy(peek_front_seg, ring_front_seg);
                @memcpy(peek_back_seg, ring_back_seg);
                return self.peek_buffer[0..self.ring_buffer.size];
            }
        }
    };
}
