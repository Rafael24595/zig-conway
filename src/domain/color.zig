const std = @import("std");

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
