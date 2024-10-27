const std = @import("std");

pub const CodepointIteratorVTable = struct {
    getBufferCapacity: *const fn (self: *anyopaque) usize,
    reset: *const fn (self: *anyopaque) void,
    next: *const fn (self: *anyopaque) anyerror!u21,
    skip: *const fn (self: *anyopaque, n: usize) anyerror!void,
    peek: *const fn (self: *anyopaque) anyerror!u21,
    peekUntilDelimiter: *const fn (self: *anyopaque, n: usize, delimiter: u21) anyerror![]const u21,
};

pub const CodepointIterator = struct {
    impl: *anyopaque,
    vtable: *const CodepointIteratorVTable,

    /// Get internal buffer capacity.
    pub inline fn getBufferCapacity(self: @This()) usize {
        return self.vtable.getBufferCapacity(self.impl);
    }

    /// Reset internal state.
    /// Peeked data will be discarded.
    pub inline fn reset(self: @This()) void {
        self.vtable.reset(self.impl);
    }

    /// Get next codepoint.
    pub inline fn next(self: @This()) anyerror!u21 {
        return self.vtable.next(self.impl);
    }

    /// Discard `n` items.
    pub inline fn skip(self: @This(), n: usize) anyerror!void {
        return self.vtable.skip(self.impl, n);
    }

    /// Peek next codepoint.
    pub inline fn peek(self: @This()) anyerror!u21 {
        return self.vtable.peek(self.impl);
    }

    /// Peek `n` items and return it as a slice.
    /// Returned slice is valid until `fn next` or `fn skip` is called.
    pub inline fn peekUntilDelimiter(self: @This(), n: usize, delimiter: u21) anyerror![]const u21 {
        return self.vtable.peekUntilDelimiter(self.impl, n, delimiter);
    }
};

pub fn GenericCodepointIterator(Context: type, ReadError: type) type {
    const GenericRingBuffer = @import("generic_ringbuffer.zig").GenericRingBuffer;

    return struct {
        context: Context,
        readFn: *const fn (context: Context) ReadError!u21,
        ring_buffer: GenericRingBuffer(u21),
        peek_buffer: []u21,

        /// Create a new CodepointIterator.
        /// Size of `buffer` and `peek_buffer` must be equal.
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

        pub fn iter(self: *@This()) CodepointIterator {
            return .{
                .impl = self,
                .vtable = &.{
                    .getBufferCapacity = getBufferCapacity,
                    .reset = reset,
                    .next = next,
                    .skip = skip,
                    .peek = peek,
                    .peekUntilDelimiter = peekUntilDelimiter,
                },
            };
        }

        pub fn getBufferCapacity(self_ptr: *anyopaque) usize {
            const self: *@This() = @ptrCast(@alignCast(self_ptr));
            return self.ring_buffer.buf.len;
        }

        pub fn reset(self_ptr: *anyopaque) void {
            const self: *@This() = @ptrCast(@alignCast(self_ptr));
            self.ring_buffer.clear();
        }

        pub fn next(self_ptr: *anyopaque) anyerror!u21 {
            const self: *@This() = @ptrCast(@alignCast(self_ptr));
            if (self.ring_buffer.size == 0) {
                return try self.readFn(self.context);
            } else {
                return try self.ring_buffer.popFront();
            }
        }

        pub fn skip(self_ptr: *anyopaque, n: usize) anyerror!void {
            const self: *@This() = @ptrCast(@alignCast(self_ptr));
            for (0..n) |_| {
                _ = try next(self);
            }
        }

        pub fn peek(self_ptr: *anyopaque) anyerror!u21 {
            const self: *@This() = @ptrCast(@alignCast(self_ptr));
            if (self.ring_buffer.size == 0) {
                const codepoint = try self.readFn(self.context);
                try self.ring_buffer.pushBack(codepoint);
            }
            return try self.ring_buffer.getFront();
        }

        pub fn peekUntilDelimiter(self_ptr: *anyopaque, n: usize, delimiter: u21) anyerror![]const u21 {
            const self: *@This() = @ptrCast(@alignCast(self_ptr));

            if (n == 0 or self.ring_buffer.buf.len < n) {
                // TODO: error when peeking more then ring_buffer.buf.len?
                return &.{};
            }

            blk: {
                // don't read more if the last codepoint is delimiter
                if (self.ring_buffer.size > 0) {
                    if (try self.ring_buffer.getBack() == delimiter) {
                        break :blk;
                    }
                }

                // read more codepoints
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

            // return it as a slice
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
