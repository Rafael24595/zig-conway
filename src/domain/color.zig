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
    allocator: *std.mem.Allocator,
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
    allocator: *std.mem.Allocator,

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
        const idx = self.lcg.rand_in_range(0, colors.len - 1);
        return colors[idx];
    }

    pub fn free(self: *@This()) void {
        self.allocator.free(self.table);
        self.table = null;
    }
};
