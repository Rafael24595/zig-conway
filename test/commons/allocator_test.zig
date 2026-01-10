const std = @import("std");

const AllocatorTracer = @import("root.zig").AllocatorTracer;

test "initialize the allocator with zero bytes with init method" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var base = gpa.allocator();

    var tracer = AllocatorTracer.init(&base);
    try std.testing.expectEqual(0, tracer.bytes());
}

test "increment the bytes in use with alloc method" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var base = gpa.allocator();

    var tracer = AllocatorTracer.init(&base);
    var alloc = tracer.allocator();

    const ptr = try alloc.alloc(u8, 16);
    defer alloc.free(ptr);

    try std.testing.expectEqual(16, tracer.bytes());
}

test "decrement the bytes in use with free method" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var base = gpa.allocator();

    var tracer = AllocatorTracer.init(&base);
    var alloc = tracer.allocator();

    const ptr = try alloc.alloc(u8, 32);
    alloc.free(ptr);
    try std.testing.expectEqual(0, tracer.bytes());
}

test "resize the bytes in use with resize method" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var base = gpa.allocator();

    var tracer = AllocatorTracer.init(&base);
    var alloc = tracer.allocator();

    const buf = try alloc.alloc(u8, 10);
    try std.testing.expect(tracer.bytes() == 10);

    if (alloc.resize(buf, 20)) {
        try std.testing.expectEqual(20, tracer.bytes());
    } else {
        try std.testing.expectEqual(10, tracer.bytes());
    }

    alloc.free(buf);
    try std.testing.expectEqual(0, tracer.bytes());
}

test "integration with ArrayList" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var base = gpa.allocator();

    var tracer = AllocatorTracer.init(&base);
    const alloc = tracer.allocator();

    var list = try std.ArrayList(u8).initCapacity(alloc, 2);
    defer list.deinit(alloc);

    try list.append(alloc, 'a');
    try list.append(alloc, 'b');

    try std.testing.expectEqual(2, tracer.bytes());
}
