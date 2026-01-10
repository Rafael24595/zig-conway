const std = @import("std");

const Printer = @import("printer.zig").Printer;

const Matrix = @import("../domain/matrix.zig").Matrix;

const mode = @import("../domain/mode.zig");
const color = @import("../domain/color.zig");

pub fn MatrixPrinter(
    comptime char_fmt_bytes: usize,
    comptime char_fmt_prefix: []const u8,
    comptime char_fmt_sufix: []const u8,
) type {
    return struct {
        allocator: *std.mem.Allocator,

        printer: *Printer,

        mode_meta: mode.ModeMeta,
        color_meta: [3]u8,

        pub fn init(allocator: *std.mem.Allocator, printer: *Printer, mode_code: mode.Mode, color_code: color.Color) MatrixPrinter(char_fmt_bytes, char_fmt_prefix, char_fmt_sufix) {
            return .{ .allocator = allocator, .printer = printer, .mode_meta = mode.metaOf(mode_code), .color_meta = color.rgbOf(color_code) };
        }

        pub fn print(self: *@This(), mtrx: *Matrix) !void {
            if (mtrx.matrix() == null or mtrx.matrix().?.len == 0) {
                return;
            }

            const matrix = mtrx.matrix().?;
            const rows = matrix.len;
            const columns = matrix[0].len;

            const estimatedSize = (rows * columns * self.mode_meta.total_char) + char_fmt_bytes;
            var buffer = try std.ArrayList(u8).initCapacity(self.allocator.*, estimatedSize);
            defer buffer.deinit(self.allocator.*);

            var formatBuffer: [char_fmt_bytes]u8 = undefined;

            const prefix = try std.fmt.bufPrint(&formatBuffer, char_fmt_prefix, .{ self.color_meta[0], self.color_meta[1], self.color_meta[2] });
            try buffer.appendSlice(self.allocator.*, prefix);

            for (0..rows) |y| {
                for (0..columns) |x| {
                    var cell: []const u8 = self.mode_meta.death_char;
                    if (matrix[y][x]) {
                        cell = self.mode_meta.alive_char;
                    }

                    try buffer.appendSlice(self.allocator.*, cell);
                }

                if (y < rows - 1) {
                    try buffer.append(self.allocator.*, '\n');
                }
            }

            try buffer.appendSlice(self.allocator.*, char_fmt_sufix);

            try self.printer.print(buffer.items);
        }
    };
}
