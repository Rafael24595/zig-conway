/// Defines the available cell symbol themes.
pub const Theme = enum {
    classic,
    treasure,
    stars,
    dots,
    block,
    alert,
    donut,
    twister,
    dollar,
    euro,
    crosshair,
    delta,
    butterfly,
    tango,
    circle,
};

/// Stores the alive and dead symbols and their byte size.
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

/// Returns the symbol metadata for the given theme.
pub fn meta_of(m: Theme) ThemeMeta {
    return ThemeMap[@intFromEnum(m)];
}
