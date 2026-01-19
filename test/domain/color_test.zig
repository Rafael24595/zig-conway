const std = @import("std");

const color = @import("root.zig").color;
const MiniLCG = @import("root.zig").MiniLCG;

fn hasNoDuplicates(comptime T: type, slice: []const T) bool {
    for (slice, 0..) |v, i| {
        for (slice[i + 1 ..]) |w| {
            if (v == w) return false;
        }
    }
    return true;
}

fn allInBase(comptime T: type, slice: []const T, base: []const T) bool {
    for (slice) |v| {
        var found = false;
        for (base) |b| {
            if (v == b) {
                found = true;
                break;
            }
        }
        if (!found) return false;
    }
    return true;
}

test "correct RGB values for known colors" {
    try std.testing.expectEqual([3]u8{ 255, 0, 0 }, color.rgbOf(color.Color.Red));
    try std.testing.expectEqual([3]u8{ 0, 255, 0 }, color.rgbOf(color.Color.Green));
    try std.testing.expectEqual([3]u8{ 0, 0, 255 }, color.rgbOf(color.Color.Blue));
}

test "sample returns correct size and no duplicates" {
    var allocator = std.heap.page_allocator;
    var rng = MiniLCG.init(123);

    const base = [_]color.Color{ .Red, .Green, .Blue, .Yellow };
    const size: usize = 3;

    const result = try color.sample(&allocator, &rng, size, base[0..]);
    defer allocator.free(result);

    try std.testing.expectEqual(size, result.len);
    try std.testing.expect(hasNoDuplicates(color.Color, result));
    try std.testing.expect(allInBase(color.Color, result, base[0..]));
}

test "sample clamps size to base length" {
    var allocator = std.heap.page_allocator;
    var rng = MiniLCG.init(42);

    const base = [_]color.Color{ .Red, .Green };
    const size = 5;

    const result = try color.sample(&allocator, &rng, size, base[0..]);
    defer allocator.free(result);

    try std.testing.expectEqual(base.len, result.len);
    try std.testing.expect(hasNoDuplicates(color.Color, result));
    try std.testing.expect(allInBase(color.Color, result, base[0..]));
}

test "sample is deterministic with same seed" {
    var allocator = std.heap.page_allocator;

    const base = [_]color.Color{ .Red, .Green, .Blue, .Yellow };
    const size = 3;

    var rng1 = MiniLCG.init(777);
    var rng2 = MiniLCG.init(777);

    const result1 = try color.sample(&allocator, &rng1, size, base[0..]);
    const result2 = try color.sample(&allocator, &rng2, size, base[0..]);
    defer allocator.free(result1);
    defer allocator.free(result2);

    try std.testing.expectEqualSlices(color.Color, result1, result2);
}

test "sample handles empty base" {
    var allocator = std.heap.page_allocator;
    var rng = MiniLCG.init(999);

    const base: [0]color.Color = undefined;
    const size = 3;

    const result = try color.sample(&allocator, &rng, size, base[0..]);
    defer allocator.free(result);

    try std.testing.expectEqual(0, result.len);
}
