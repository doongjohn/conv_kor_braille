pub fn GenericRingBuffer(T: type) type {
    return struct {
        buf: []T,
        head: usize = 0,
        tail: usize = 0,
        size: usize = 0,

        pub fn isFull(self: *@This()) bool {
            return self.size == self.buf.len;
        }

        pub fn nextIndex(self: *@This(), index: usize) usize {
            return (index + 1) % self.buf.len;
        }

        pub fn prevIndex(self: *@This(), index: usize) usize {
            const prev = index - 1;
            if (prev >= 0) {
                return prev;
            } else {
                return self.buf.len + prev;
            }
        }

        pub fn getFront(self: *@This()) !T {
            if (self.size == 0) {
                return error.Empty;
            }
            return self.buf[self.head];
        }

        pub fn getBack(self: *@This()) !T {
            if (self.size == 0) {
                return error.Empty;
            }
            return self.buf[self.tail];
        }

        pub fn pushFront(self: *@This(), value: T) !void {
            if (self.size == self.buf.len) {
                return error.Full;
            }

            if (self.size > 0) {
                self.head = self.prevIndex(self.head);
            }
            self.buf[self.head] = value;
            self.size += 1;
        }

        pub fn pushBack(self: *@This(), value: T) !void {
            if (self.size == self.buf.len) {
                return error.Full;
            }

            if (self.size > 0) {
                self.tail = self.nextIndex(self.tail);
            }
            self.buf[self.tail] = value;
            self.size += 1;
        }

        pub fn popFront(self: *@This()) !T {
            if (self.size == 0) {
                return error.Empty;
            }

            const i = self.head;
            if (self.size > 1) {
                self.head = self.nextIndex(self.head);
            }
            self.size -= 1;
            return self.buf[i];
        }

        pub fn popBack(self: *@This()) !T {
            if (self.size == 0) {
                return error.Empty;
            }

            const i = self.tail;
            if (self.size > 1) {
                self.tail = self.prevIndex(self.tail);
            }
            self.size -= 1;
            return self.buf[i];
        }

        pub fn clear(self: *@This()) void {
            self.head = 0;
            self.tail = 0;
            self.size = 0;
        }
    };
}
