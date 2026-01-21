const std = @import("std");

const Printer = @import("printer.zig").Printer;

const Matrix = @import("../domain/matrix.zig").Matrix;

const symbol = @import("../domain/symbol.zig");
const color = @import("../domain/color.zig");

const formatter = @import("formatter.zig");

pub const MatrixPrinter = struct {
    allocator: *std.mem.Allocator,

    printer: *Printer,
    formatter: formatter.FormatterCellUnion,

    prefix: []const u8,
    sufix: []const u8,

    mode_meta: symbol.SymbolMeta,

    pub fn init(
        allocator: *std.mem.Allocator,
        printer: *Printer,
        col: color.Color,
        fmt_mtrx: formatter.FormatterMatrixUnion,
        fmt_cell: formatter.FormatterCellUnion,
        mode_code: symbol.Mode,
    ) !@This() {
        const len = fmt_mtrx.prefix().len;
        const buf = try allocator.alloc(u8, len);

        const rgb = color.rgbOf(col);

        return .{
            .allocator = allocator,
            .printer = printer,
            .formatter = fmt_cell,
            .prefix = fmt_mtrx.format_prefix(buf, rgb[0], rgb[1], rgb[2]),
            .sufix = fmt_mtrx.sufix(),
            .mode_meta = symbol.metaOf(mode_code),
        };
    }

    pub fn print(self: *@This(), mtrx: *Matrix) !void {
        if (mtrx.matrix() == null or mtrx.matrix().?.len == 0) {
            return;
        }

        const matrix = mtrx.matrix().?;
        const rows = mtrx.rows();
        const columns = mtrx.cols();

        const char_fmt_len = self.formatter.fmt_bytes() + self.mode_meta.total_bytes;
        const mtrx_fmt_len = rows * columns * char_fmt_len;
        const estimated_size = self.prefix.len + mtrx_fmt_len + self.sufix.len;

        var buffer = try std.ArrayList(u8).initCapacity(self.allocator.*, estimated_size);
        defer buffer.deinit(self.allocator.*);

        const buf = try self.allocator.alloc(u8, char_fmt_len);
        defer self.allocator.free(buf);

        try buffer.appendSlice(self.allocator.*, self.prefix);

        for (0..rows) |y| {
            for (0..columns) |x| {
                var cell: []const u8 = self.mode_meta.death_char;
                if (matrix[y][x].status) {
                    cell = self.mode_meta.alive_char;
                }

                if (matrix[y][x].color) |c| {
                    cell = try self.formatter.format(buf, c[0], c[1], c[2], cell);
                }

                try buffer.appendSlice(self.allocator.*, cell);
            }

            if (y < rows - 1) {
                try buffer.append(self.allocator.*, '\n');
            }
        }

        try buffer.appendSlice(self.allocator.*, self.sufix);

        try self.printer.print(buffer.items);
    }

    pub fn reset(self: *@This()) void {
        self.allocator.free(self.prefix);
    }
};
