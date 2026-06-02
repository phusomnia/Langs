const std = @import("std");

pub const Queue = struct {
    allocator: *std.mem.Allocator,
    data: []i32,
    head: usize,
    tail: usize,
    len: usize,
    capacity: usize,

    pub fn init(allocator: *std.mem.Allocator, init_cap: usize) !Queue {
        const cap = init_cap;
        if (cap == 0) return error.InvalidCapacity;
        const data = try allocator.alloc(i32, cap);
        return Queue{
            .allocator = allocator,
            .data = data,
            .head = 0,
            .tail = 0,
            .len = 0,
            .capacity = cap,
        };
    }

    pub fn deinit(self: *Queue) void {
        if (self.capacity != 0) {
            self.allocator.free(self.data);
        }
    }

    pub fn enqueue(self: *Queue, value: i32) !void {
        // check limit of queue
        if (self.len == self.capacity) {
            try self.grow();
        }
        self.data[self.tail] = value;
        self.tail = (self.tail + 1) % self.capacity;
        self.len += 1;
    }

    pub fn dequeue(self: *Queue) !void {
        // check if queue is empty
        if (self.len == 0) {
            return error.QueueEmpty;
        }
        const item = self.data[self.head];
        self.head = (self.head + 1) % self.capacity;
        self.len -= 1;
        return item;
    }

    pub fn isEmpty(self: *Queue) bool {
        return self.len == 0;
    }

    pub fn size(self: *Queue) usize {
        return self.len;
    }

    pub fn grow(self: *Queue) !void {
        if (self.len == self.capacity) {
            const new_cap = self.capacity * 2;
            var new_data = try self.allocator.alloc(i32, new_cap);
            var i: usize = 0;
            while (i < self.len) : (i += 1) {
                new_data[i] = self.data[(self.head + i) % self.capacity];
            }

            self.allocator.free(self.data);
            self.data = new_data;
            self.head = 0;
            self.tail = self.len;
            self.capacity = new_cap;
        }
    }
};

pub fn main() !void {
    var page_allocator = std.heap.page_allocator;
    var q = try Queue.init(&page_allocator, 4);
    defer q.deinit();

    try q.enqueue(1);
    try q.enqueue(2);
    try q.enqueue(3);
    try q.enqueue(4);
    try q.enqueue(5);
    try q.enqueue(6);
    try q.enqueue(7);
    try q.enqueue(8);
    try q.enqueue(9);
    try q.enqueue(10);
    try q.enqueue(11);

    std.debug.print("Queue size: {}\n", .{q.size()});
}
