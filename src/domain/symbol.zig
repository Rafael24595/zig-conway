pub const Theme = enum {
    Classic,
    Treasure,
    Stars,
    Dots,
    Block,
    Alert,
    Donut,
    Twister,
    Dollar,
    Euro,
    Crosshair,
    Delta,
    Butterfly,
    Target,
    Circle,
};

pub const ThemeMeta = struct {
    alive_char: []const u8,
    death_char: []const u8,
    total_bytes: u8,
};

//TODO -> [Improve]: death_char field MUST be a space char (' ') for performance reasons.
const ThemeMap = [_]ThemeMeta{
    .{ .alive_char = "#", .death_char = " ", .total_bytes = 1 },
    .{ .alive_char = "x", .death_char = " ", .total_bytes = 1 },
    .{ .alive_char = "*", .death_char = " ", .total_bytes = 1 },
    .{ .alive_char = ".", .death_char = " ", .total_bytes = 1 },
    .{ .alive_char = "█", .death_char = " ", .total_bytes = 3 },
    .{ .alive_char = "!", .death_char = " ", .total_bytes = 1 },
    .{ .alive_char = "o", .death_char = " ", .total_bytes = 1 },
    .{ .alive_char = "@", .death_char = " ", .total_bytes = 1 },
    .{ .alive_char = "$", .death_char = " ", .total_bytes = 1 },
    .{ .alive_char = "€", .death_char = " ", .total_bytes = 3 },
    .{ .alive_char = "¤", .death_char = " ", .total_bytes = 2 },
    .{ .alive_char = "∆", .death_char = " ", .total_bytes = 3 },
    .{ .alive_char = "⌘", .death_char = " ", .total_bytes = 3 },
    .{ .alive_char = "◎", .death_char = " ", .total_bytes = 3 },
    .{ .alive_char = "◉", .death_char = " ", .total_bytes = 3 },
};

pub fn metaOf(m: Theme) ThemeMeta {
    return ThemeMap[@intFromEnum(m)];
}
