pub const Mode = enum {
    Ascii_L,
    Ascii_M,
    Ascii_S,
    Block,
};

pub const ModeMeta = struct {
    alive_char: []const u8,
    death_char: []const u8,
    total_char: u8,
};

//TODO -> [Improve]: death_char field MUST be a space char (' ') for performance reasons.
const mode_values = [_]ModeMeta{ 
    .{ .alive_char = "#", .death_char = " ", .total_char = 1 }, 
    .{ .alive_char = "*", .death_char = " ", .total_char = 1 }, 
    .{ .alive_char = ".", .death_char = " ", .total_char = 1 }, 
    .{ .alive_char = "█", .death_char = " ", .total_char = 3 } 
};

pub fn metaOf(m: Mode) ModeMeta {
    return mode_values[@intFromEnum(m)];
}
