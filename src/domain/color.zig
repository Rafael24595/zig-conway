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
};

pub const DEFAULT_TABLE = [_]Color{
    Color.White,
    Color.Red,
    Color.Green,
    Color.Blue,
    Color.Yellow,
    Color.Cyan,
    Color.Magenta,
    Color.Orange,
    Color.Purple,
};

const color_values = [_][3]u8{
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
};

pub fn rgbOf(c: Color) [3]u8 {
    return color_values[@intFromEnum(c)];
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
