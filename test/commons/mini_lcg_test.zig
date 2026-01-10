const std = @import("std");

const MiniLCG = @import("root.zig").MiniLCG;

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

