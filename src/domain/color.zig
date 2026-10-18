const std = @import("std");

const terminal_kit = @import("terminal_kit");

const MiniLCG = terminal_kit.mini_lcg.MiniLCG;

const kit_color = terminal_kit.color;

pub const Theme = enum {
    default,
    pastel,
    neon,
    earthy,
    cool,
    warm,
    //aoe,
};

pub const ThemeMeta = struct {
    colors: []const kit_color.Color,
};

const ThemeMap = [_]ThemeMeta{
    DEFAULT_THEME,
    PASTEL_THEME,
    NEON_THEME,
    EARTHY_THEME,
    COOL_THEME,
    WARM_THEME,
    //AOE_THEME,
};

pub const DEFAULT_THEME = ThemeMeta{
    .colors = &[_]kit_color.Color{
        kit_color.Color.white,
        kit_color.Color.red,
        kit_color.Color.green,
        kit_color.Color.blue,
        kit_color.Color.yellow,
        kit_color.Color.cyan,
        kit_color.Color.magenta,
        kit_color.Color.orange,
        kit_color.Color.purple,
    },
};

pub const PASTEL_THEME = ThemeMeta{
    .colors = &[_]kit_color.Color{
        kit_color.Color.lavender,
        kit_color.Color.pink,
        kit_color.Color.coral,
        kit_color.Color.aqua,
        kit_color.Color.yellow,
        kit_color.Color.lime,
    },
};

pub const NEON_THEME = ThemeMeta{
    .colors = &[_]kit_color.Color{
        kit_color.Color.neon_pink,
        kit_color.Color.neon_green,
        kit_color.Color.neon_blue,
        kit_color.Color.neon_yellow,
        kit_color.Color.neon_orange,
        kit_color.Color.neon_purple,
        kit_color.Color.neon_cyan,
        kit_color.Color.neon_red,
    },
};

pub const EARTHY_THEME = ThemeMeta{
    .colors = &[_]kit_color.Color{
        kit_color.Color.brown,
        kit_color.Color.gray,
        kit_color.Color.orange,
        kit_color.Color.green,
        kit_color.Color.navy,
        kit_color.Color.teal,
        kit_color.Color.gold,
    },
};

pub const COOL_THEME = ThemeMeta{
    .colors = &[_]kit_color.Color{
        kit_color.Color.blue,
        kit_color.Color.cyan,
        kit_color.Color.navy,
        kit_color.Color.teal,
        kit_color.Color.aqua,
        kit_color.Color.lavender,
    },
};

pub const WARM_THEME = ThemeMeta{
    .colors = &[_]kit_color.Color{
        kit_color.Color.red,
        kit_color.Color.orange,
        kit_color.Color.yellow,
        kit_color.Color.pink,
        kit_color.Color.coral,
        kit_color.Color.gold,
    },
};

//pub const AOE_THEME = ThemeMeta{
//    .colors = &[_]kit_color.Color{
//        kit_color.Color.red,
//        kit_color.Color.blue,
//        kit_color.Color.green,
//        kit_color.Color.yellow,
//        kit_color.Color.cyan,
//        kit_color.Color.magenta,
//        kit_color.Color.orange,
//    },
//};

pub fn meta_of(m: Theme) ThemeMeta {
    return ThemeMap[@intFromEnum(m)];
}

pub fn sample(
    allocator: std.mem.Allocator,
    lcg: *MiniLCG,
    size: usize,
    base: []const kit_color.Color,
) ![]const kit_color.Color {
    const count = @min(size, base.len);

    var indexes = try allocator.alloc(usize, base.len);
    defer allocator.free(indexes);

    for (0..base.len) |i| {
        indexes[i] = i;
    }

    lcg.shuffle(usize, indexes);

    var table_rng = try allocator.alloc(kit_color.Color, count);
    for (0..count) |i| {
        const index = indexes[i];
        table_rng[i] = base[index];
    }

    return table_rng;
}

pub const ColorManager = struct {
    allocator: std.mem.Allocator,

    lcg: *MiniLCG,

    table: [][3]u8,

    pub fn init(
        allocator: std.mem.Allocator,
        lcg: *MiniLCG,
        theme: Theme,
        size: usize,
    ) !@This() {
        const meta = meta_of(theme);

        const table = try sample(
            allocator,
            lcg,
            size,
            meta.colors,
        );

        defer allocator.free(table);

        var table_rgb = try allocator.alloc([3]u8, table.len);
        for (table, 0..) |c, i| {
            table_rgb[i] = kit_color.rgb_of(c);
        }

        return ColorManager{
            .allocator = allocator,
            .lcg = lcg,
            .table = table_rgb,
        };
    }

    pub fn free(self: *@This()) void {
        self.allocator.free(self.table);
        self.table = undefined;
    }

    pub fn rand_color(self: *@This()) [3]u8 {
        const table = self.table;
        const idx = self.lcg.rand_in_range(0, table.len - 1);
        return table[idx];
    }

    pub fn mix_or_select(self: *@This(), sel_prov: f32, colors: []const [3]u8) [3]u8 {
        if (colors.len == 0) {
            return kit_color.rgb_of(kit_color.Color.white);
        }

        if (self.lcg.float() < sel_prov) {
            return self.select(colors);
        }

        return mix(colors);
    }

    inline fn select(self: *@This(), colors: []const [3]u8) [3]u8 {
        const idx = self.lcg.rand_in_range(0, colors.len - 1);
        return colors[idx];
    }
};

inline fn mix(colors: []const [3]u8) [3]u8 {
    var r: u32 = 0;
    var g: u32 = 0;
    var b: u32 = 0;

    for (colors) |c| {
        r += c[0];
        g += c[1];
        b += c[2];
    }

    const n = colors.len;
    return [3]u8{
        @intCast(r / n),
        @intCast(g / n),
        @intCast(b / n),
    };
}

fn has_no_duplicates(comptime T: type, slice: []const T) bool {
    for (slice, 0..) |v, i| {
        for (slice[i + 1 ..]) |w| {
            if (v == w) return false;
        }
    }
    return true;
}

fn all_in_base(comptime T: type, slice: []const T, base: []const T) bool {
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
    try std.testing.expectEqual([3]u8{ 255, 0, 0 }, kit_color.rgb_of(kit_color.Color.red));
    try std.testing.expectEqual([3]u8{ 0, 255, 0 }, kit_color.rgb_of(kit_color.Color.green));
    try std.testing.expectEqual([3]u8{ 0, 0, 255 }, kit_color.rgb_of(kit_color.Color.blue));
}

test "sample returns correct size and no duplicates" {
    var allocator = std.heap.page_allocator;
    var rng = MiniLCG.init(123);

    const base = [_]kit_color.Color{ .red, .green, .blue, .yellow };
    const size: usize = 3;

    const result = try sample(allocator, &rng, size, base[0..]);
    defer allocator.free(result);

    try std.testing.expectEqual(size, result.len);
    try std.testing.expect(has_no_duplicates(kit_color.Color, result));
    try std.testing.expect(all_in_base(kit_color.Color, result, base[0..]));
}

test "sample clamps size to base length" {
    var allocator = std.heap.page_allocator;
    var rng = MiniLCG.init(42);

    const base = [_]kit_color.Color{ .red, .green };
    const size = 5;

    const result = try sample(allocator, &rng, size, base[0..]);
    defer allocator.free(result);

    try std.testing.expectEqual(base.len, result.len);
    try std.testing.expect(has_no_duplicates(kit_color.Color, result));
    try std.testing.expect(all_in_base(kit_color.Color, result, base[0..]));
}

test "sample is deterministic with same seed" {
    var allocator = std.heap.page_allocator;

    const base = [_]kit_color.Color{ .red, .green, .blue, .yellow };
    const size = 3;

    var rng1 = MiniLCG.init(777);
    var rng2 = MiniLCG.init(777);

    const result1 = try sample(allocator, &rng1, size, base[0..]);
    const result2 = try sample(allocator, &rng2, size, base[0..]);
    defer allocator.free(result1);
    defer allocator.free(result2);

    try std.testing.expectEqualSlices(kit_color.Color, result1, result2);
}

test "sample handles empty base" {
    var allocator = std.heap.page_allocator;
    var rng = MiniLCG.init(999);

    const base: [0]kit_color.Color = undefined;
    const size = 3;

    const result = try sample(allocator, &rng, size, base[0..]);
    defer allocator.free(result);

    try std.testing.expectEqual(0, result.len);
}

test "ColorManager.mix returns the average RGB values" {
    const colors = [_][3]u8{
        .{ 100, 50, 0 },
        .{ 200, 150, 100 },
    };

    try std.testing.expectEqual(
        [3]u8{ 150, 100, 50 },
        mix(&colors),
    );
}

test "ColorManager.mix averages multiple colors" {
    const colors = [_][3]u8{
        .{ 0, 30, 60 },
        .{ 30, 60, 90 },
        .{ 60, 90, 120 },
    };

    try std.testing.expectEqual(
        [3]u8{ 30, 60, 90 },
        mix(&colors),
    );
}
