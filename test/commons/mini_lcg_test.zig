const std = @import("std");

const MiniLCG = @import("root.zig").MiniLCG;

const Point = struct {
    x: i32,
    y: i32,
};

fn isPermutation(comptime T: type, a: []const T, b: []const T, comptime cmp: fn (a: T, b: T) bool) bool {
    if (a.len != b.len) {
        return false;
    }

    var used = [_]bool{false} ** 256;
    for (a) |x| {
        var found = false;
        for (b, 0..) |y, i| {
            if (!used[i] and cmp(x, y)) {
                used[i] = true;
                found = true;
                break;
            }
        }

        if (!found) {
            return false;
        }
    }

    return true;
}

fn cmpI32(a: i32, b: i32) bool {
    return a == b;
}

fn cmpPoint(a: Point, b: Point) bool {
    return a.x == b.x and a.x == b.y;
}

test "random number in range with specific seed" {
    var lcg = MiniLCG.init(1234);

    var num = lcg.randInRange(0, 10);
    try std.testing.expectEqual(1, num);

    num = lcg.randInRange(0, 10);
    try std.testing.expectEqual(6, num);

    num = lcg.randInRange(0, 10);
    try std.testing.expectEqual(9, num);
}

test "lcg determinism" {
    var a = MiniLCG.init(42);
    var b = MiniLCG.init(42);

    for (0..10) |_| {
        const ra = a.randInRange(0, 100);
        const rb = b.randInRange(0, 100);
        try std.testing.expectEqual(ra, rb);
    }
}

test "different seeds produce different sequences" {
    var a = MiniLCG.init(1);
    var b = MiniLCG.init(2);

    for (0..10) |_| {
        const ra = a.randInRange(0, 255);
        const rb = b.randInRange(0, 255);
        try std.testing.expect(ra != rb);
    }
}

test "respects range boundaries" {
    var lcg = MiniLCG.init(9876);

    for (0..1000) |_| {
        const v = lcg.randInRange(5, 15);
        try std.testing.expect(v >= 5 and v <= 15);
    }
}

test "single value range returns same result" {
    var lcg = MiniLCG.init(123);
    for (0..10) |_| {
        try std.testing.expectEqual(7, lcg.randInRange(7, 7));
    }
}

test "handles seed overflow" {
    var lcg = MiniLCG.init(std.math.maxInt(u64));
    const v = lcg.randInRange(0, 255);
    try std.testing.expect(v <= 255);
}

test "float produces values in [0,1)" {
    var lcg = MiniLCG.init(9999);

    for (0..1000) |_| {
        const f = lcg.float();
        try std.testing.expect(f >= 0.0);
        try std.testing.expect(f < 1.0);
    }
}

test "float determinism" {
    var a = MiniLCG.init(77);
    var b = MiniLCG.init(77);

    for (0..100) |_| {
        try std.testing.expectEqual(a.float(), b.float());
    }
}

test "float distribution sanity check" {
    var lcg = MiniLCG.init(1234);

    var sum: f32 = 0.0;
    const n = 10_000;

    for (0..n) |_| {
        sum += lcg.float();
    }

    const mean = sum / @as(f32, n);

    try std.testing.expect(mean > 0.45);
    try std.testing.expect(mean < 0.55);
}

test "shuffle produces a valid permutation" {
    var rng = MiniLCG.init(1234);

    var data = [_]i32{ 1, 2, 3, 4, 5, 6, 7, 8 };
    const original = data;

    rng.shuffle(i32, data[0..]);

    try std.testing.expect(
        isPermutation(i32, original[0..], data[0..], cmpI32),
    );
}

test "shuffle is deterministic for the same seed" {
    var rng1 = MiniLCG.init(42);
    var rng2 = MiniLCG.init(42);

    var a = [_]u8{ 1, 2, 3, 4, 5 };
    var b = [_]u8{ 1, 2, 3, 4, 5 };

    rng1.shuffle(u8, a[0..]);
    rng2.shuffle(u8, b[0..]);

    try std.testing.expectEqualSlices(u8, a[0..], b[0..]);
}

test "shuffle handles empty and single-element slices" {
    var rng = MiniLCG.init(999);

    var empty = [_]i32{};
    rng.shuffle(i32, empty[0..]);
    try std.testing.expectEqual(@as(usize, 0), empty.len);

    var one = [_]i32{42};
    rng.shuffle(i32, one[0..]);
    try std.testing.expectEqual(@as(i32, 42), one[0]);
}

test "shuffle usually changes order" {
    var unchanged: usize = 0;

    var i: usize = 0;
    while (i < 20) : (i += 1) {
        var rng = MiniLCG.init(i + 1);

        var data = [_]u8{ 1, 2, 3, 4, 5 };
        const original = data;

        rng.shuffle(u8, data[0..]);

        if (std.mem.eql(u8, original[0..], data[0..])) {
            unchanged += 1;
        }
    }

    try std.testing.expect(unchanged < 5);
}

test "shuffle works with structs" {
    var rng = MiniLCG.init(77);

    var data = [_]Point{
        .{ .x = 1, .y = 1 },
        .{ .x = 2, .y = 2 },
        .{ .x = 3, .y = 3 },
    };

    const original = data;
    rng.shuffle(Point, data[0..]);

    try std.testing.expect(isPermutation(Point, original[0..], data[0..], cmpPoint));
}
