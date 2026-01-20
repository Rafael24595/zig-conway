const std = @import("std");

const testing = std.testing;

const utils = @import("root.zig").utils;
const Printer = @import("root.zig").printer.Printer;

test "millisecondsToTime - only milliseconds" {
    const alloc = testing.allocator;

    const result = try utils.millisecondsToTime(alloc, 5, null);
    defer alloc.free(result);

    try testing.expectEqualStrings("500ms", result);
}

test "millisecondsToTime - seconds and milliseconds" {
    const alloc = testing.allocator;

    const result = try utils.millisecondsToTime(alloc, 1500, null);
    defer alloc.free(result);

    try testing.expectEqualStrings("1s500ms", result);
}

test "millisecondsToTime - minutes and milliseconds" {
    const alloc = testing.allocator;

    const result = try utils.millisecondsToTime(alloc, 61_250, null);
    defer alloc.free(result);

    try testing.expectEqualStrings("1m1s250ms", result);
}

test "millisecondsToTime - hours minutes seconds" {
    const alloc = testing.allocator;

    const result = try utils.millisecondsToTime(alloc, 3_726_000, null);
    defer alloc.free(result);

    try testing.expectEqualStrings("1h2m6s000ms", result);
}

test "millisecondsToTime - seconds limit" {
    const alloc = testing.allocator;

    const result = try utils.millisecondsToTime(alloc, 3_726_000, utils.Second);
    defer alloc.free(result);

    try testing.expectEqualStrings("1h2m", result);
}

test "millisecondsToTime - days and years" {
    const alloc = testing.allocator;

    const one_year_ms = utils.Year.time;
    const result = try utils.millisecondsToTime(alloc, one_year_ms, null);
    defer alloc.free(result);

    try testing.expectEqualStrings("1y0d0h0m0s000ms", result);
}

test "utils.TypeFormatter - none" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    var fmt = Printer{
        .arena = &arena,
        .out = std.fs.File.stdout(),
    };

    defer fmt.reset();

    const tf = utils.TypeFormatter{ .none = {} };
    const result = try tf.format(&fmt);

    try testing.expectEqualStrings("", result);
}

test "utils.TypeFormatter - string" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    var fmt = Printer{
        .arena = &arena,
        .out = std.fs.File.stdout(),
    };

    defer fmt.reset();

    const tf = utils.TypeFormatter{ .str = "hola" };
    const result = try tf.format(&fmt);

    try testing.expectEqualStrings("hola", result);
}

test "utils.TypeFormatter - bool true" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    var fmt = Printer{
        .arena = &arena,
        .out = std.fs.File.stdout(),
    };

    defer fmt.reset();

    const tf = utils.TypeFormatter{ .bool = true };
    const result = try tf.format(&fmt);

    try testing.expectEqualStrings("true", result);
}

test "utils.TypeFormatter - bool false" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    var fmt = Printer{
        .arena = &arena,
        .out = std.fs.File.stdout(),
    };

    defer fmt.reset();

    const tf = utils.TypeFormatter{ .bool = false };
    const result = try tf.format(&fmt);

    try testing.expectEqualStrings("false", result);
}

test "utils.TypeFormatter - int" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    var fmt = Printer{
        .arena = &arena,
        .out = std.fs.File.stdout(),
    };

    defer fmt.reset();

    const tf = utils.TypeFormatter{ .int = 42 };
    const result = try tf.format(&fmt);

    try testing.expectEqualStrings("42", result);
}

test "utils.TypeFormatter - float" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    var fmt = Printer{
        .arena = &arena,
        .out = std.fs.File.stdout(),
    };

    defer fmt.reset();

    const tf = utils.TypeFormatter{ .float = 3.14159 };
    const result = try tf.format(&fmt);

    try testing.expectEqualStrings("3.14", result);
}
