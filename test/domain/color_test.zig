const std = @import("std");

const color = @import("root.zig").color;

test "correct RGB values for known colors" {
    try std.testing.expectEqual([3]u8{255, 0, 0}, color.rgbOf(color.Color.Red));
    try std.testing.expectEqual([3]u8{0, 255, 0}, color.rgbOf(color.Color.Green));
    try std.testing.expectEqual([3]u8{0, 0, 255}, color.rgbOf(color.Color.Blue));
}
