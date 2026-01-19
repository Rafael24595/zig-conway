const std = @import("std");

const MiniLCG = @import("../commons/mini_lcg.zig").MiniLCG;

pub const Color = enum {
    White,
    Black,
    Red,
    Green,
    Blue,
    Yellow,
    Cyan,
    Magenta,
    Orange,
    Purple,
    Gray,
    Pink,
    Brown,
    Aqua,
    Navy,
    Teal,
    NeonPink,
    NeonGreen,
    NeonBlue,
    NeonYellow,
    NeonOrange,
    NeonPurple,
    NeonCyan,
    NeonRed,
    Lavender,
    Lime,
    Coral,
    Gold,
};

const ColorMap = [_][3]u8{
    .{ 255, 255, 255 }, // White
    .{ 0, 0, 0 }, // Black
    .{ 255, 0, 0 }, // Red
    .{ 0, 255, 0 }, // Green
    .{ 0, 0, 255 }, // Blue
    .{ 255, 255, 0 }, // Yellow
    .{ 0, 255, 255 }, // Cyan
    .{ 255, 0, 255 }, // Magenta
    .{ 255, 128, 0 }, // Orange
    .{ 128, 0, 128 }, // Purple
    .{ 128, 128, 128 }, // Gray
    .{ 255, 192, 203 }, // Pink
    .{ 165, 42, 42 }, // Brown
    .{ 127, 255, 212 }, // Aqua
    .{ 0, 0, 128 }, // Navy
    .{ 0, 128, 128 }, // Teal
    .{ 255, 0, 144 }, // NeonPink
    .{ 57, 255, 20 }, // NeonGreen
    .{ 0, 191, 255 }, // NeonBlue
    .{ 207, 255, 4 }, // NeonYellow
    .{ 255, 95, 31 }, // NeonOrange
    .{ 191, 0, 255 }, // NeonPurple
    .{ 0, 255, 255 }, // NeonCyan
    .{ 255, 16, 83 }, // NeonRed
    .{ 230, 230, 250 }, // Lavender
    .{ 0, 255, 0 }, // Lime
    .{ 255, 127, 80 }, // Coral
    .{ 255, 215, 0 }, // Gold
};

pub fn rgbOf(c: Color) [3]u8 {
    return ColorMap[@intFromEnum(c)];
}

pub const InheritanceMode = enum {
    Default,
    Pastel,
    Neon,
    Earthy,
    Cool,
    Warm,
    //AoE,
};

pub const InheritanceMeta = struct {
    colors: []const Color,
};

const InheritanceMap = [_]InheritanceMeta{
    DEFAULT_THEME,
    PASTEL_THEME,
    NEON_THEME,
    EARTHY_THEME,
    COOL_THEME,
    WARM_THEME,
    //AOE_THEME,
};

pub const DEFAULT_THEME = InheritanceMeta{
    .colors = &[_]Color{
        Color.White,
        Color.Red,
        Color.Green,
        Color.Blue,
        Color.Yellow,
        Color.Cyan,
        Color.Magenta,
        Color.Orange,
        Color.Purple,
    },
};

pub const PASTEL_THEME = InheritanceMeta{
    .colors = &[_]Color{
        Color.Lavender,
        Color.Pink,
        Color.Coral,
        Color.Aqua,
        Color.Yellow,
        Color.Lime,
    },
};

pub const NEON_THEME = InheritanceMeta{
    .colors = &[_]Color{
        Color.NeonPink,
        Color.NeonGreen,
        Color.NeonBlue,
        Color.NeonYellow,
        Color.NeonOrange,
        Color.NeonPurple,
        Color.NeonCyan,
        Color.NeonRed,
    },
};

pub const EARTHY_THEME = InheritanceMeta{
    .colors = &[_]Color{
        Color.Brown,
        Color.Gray,
        Color.Orange,
        Color.Green,
        Color.Navy,
        Color.Teal,
        Color.Gold,
    },
};

pub const COOL_THEME = InheritanceMeta{
    .colors = &[_]Color{
        Color.Blue,
        Color.Cyan,
        Color.Navy,
        Color.Teal,
        Color.Aqua,
        Color.Lavender,
    },
};

pub const WARM_THEME = InheritanceMeta{
    .colors = &[_]Color{
        Color.Red,
        Color.Orange,
        Color.Yellow,
        Color.Pink,
        Color.Coral,
        Color.Gold,
    },
};

pub const AOE_THEME = InheritanceMeta{
    .colors = &[_]Color{
        Color.Red,
        Color.Blue,
        Color.Green,
        Color.Yellow,
        Color.Cyan,
        Color.Magenta,
        Color.Orange,
    },
};

pub fn inheritanceOf(m: InheritanceMode) InheritanceMeta {
    return InheritanceMap[@intFromEnum(m)];
}

pub fn sample(allocator: *std.mem.Allocator, lcg: *MiniLCG, size: usize, base: []const Color) ![]const Color {
    const count = @min(size, base.len);

    var indexes = try allocator.alloc(usize, base.len);
    defer allocator.free(indexes);

    for (0..base.len) |i| {
        indexes[i] = i;
    }

    lcg.shuffle(usize, indexes);

    var table_rng = try allocator.alloc(Color, count);
    for (0..count) |i| {
        const index = indexes[i];
        table_rng[i] = base[index];
    }

    return table_rng;
}

pub const ColorManager = struct {
    allocator: *std.mem.Allocator,

    lcg: *MiniLCG,

    table: [][3]u8,

    pub fn init(allocator: *std.mem.Allocator, lcg: *MiniLCG, table: []const Color) !@This() {
        var table_rgb = try allocator.alloc([3]u8, table.len);
        for (table, 0..) |c, i| {
            table_rgb[i] = rgbOf(c);
        }

        return ColorManager{
            .allocator = allocator,
            .lcg = lcg,
            .table = table_rgb,
        };
    }

    pub fn rand_color(self: *@This()) [3]u8 {
        const table = self.table;
        const idx = self.lcg.randInRange(0, @intCast(table.len - 1));
        return table[idx];
    }

    pub fn mix_or_select(self: *@This(), sel_prov: f32, colors: []const [3]u8) [3]u8 {
        if (colors.len == 0) {
            return rgbOf(Color.White);
        }

        if (self.lcg.float() < sel_prov) {
            return self.select(colors);
        }

        return self.mix(colors);
    }

    pub fn mix(_: *@This(), colors: []const [3]u8) [3]u8 {
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

    pub fn select(self: *@This(), colors: []const [3]u8) [3]u8 {
        const idx = self.lcg.randInRange(0, @intCast(colors.len - 1));
        return colors[idx];
    }

    pub fn free(self: *@This()) void {
        self.allocator.free(self.table);
        self.map = null;
    }
};
