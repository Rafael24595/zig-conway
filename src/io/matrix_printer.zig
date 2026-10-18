const std = @import("std");

const terminal_kit = @import("terminal_kit");

const Printer = terminal_kit.printer.Printer;
const color = terminal_kit.color;

const LinearMatrix = @import("../domain/matrix.zig").LinearMatrix;

const symbol = @import("../domain/symbol.zig");

const formatter = @import("formatter.zig");

pub const LinearMatrixPrinter = struct {
    allocator: *std.mem.Allocator,

    printer: *Printer,
    formatter: formatter.FormatterCellUnion,

    prefix: []const u8,
    sufix: []const u8,

    mode_meta: symbol.ThemeMeta,

    buffer: std.ArrayList(u8),
    format: []u8,

    pub fn init(
        allocator: *std.mem.Allocator,
        printer: *Printer,
        col: color.Color,
        fmt_mtrx: formatter.FormatterMatrixUnion,
        fmt_cell: formatter.FormatterCellUnion,
        mode_code: symbol.Theme,
        matrix: *LinearMatrix,
    ) !@This() {
        const len = fmt_mtrx.prefix().len;
        const buf = try allocator.alloc(u8, len);

        const rgb = color.rgb_of(col);

        const prefix = fmt_mtrx.format_prefix(buf, rgb[0], rgb[1], rgb[2]);
        const sufix = fmt_mtrx.sufix();

        const meta = symbol.meta_of(mode_code);

        const rows = matrix.rows_len();
        const cols = matrix.cols_len();

        const char_fmt_len = fmt_cell.fmt_bytes() + meta.total_bytes;
        const mtrx_fmt_len = rows * cols * char_fmt_len;
        const estimated_size = prefix.len + mtrx_fmt_len + sufix.len;

        const buffer = try std.ArrayList(u8).initCapacity(allocator.*, estimated_size);
        const format = try allocator.alloc(u8, char_fmt_len);

        return .{
            .allocator = allocator,
            .printer = printer,
            .formatter = fmt_cell,
            .prefix = prefix,
            .sufix = sufix,
            .mode_meta = meta,
            .buffer = buffer,
            .format = format,
        };
    }

    pub fn free(self: *@This()) void {
        self.buffer.deinit(self.allocator.*);
        self.allocator.free(self.format);
        self.allocator.free(self.prefix);
    }

    pub fn print(self: *@This(), mtrx: *LinearMatrix) !void {
        if (mtrx.vector() == null or mtrx.vector().?.len == 0) {
            return;
        }

        self.buffer.clearRetainingCapacity();

        const matrix = mtrx.vector().?;

        const rows = mtrx.rows_len();
        const cols = mtrx.cols_len();

        try self.buffer.appendSlice(self.allocator.*, self.prefix);

        for (0..rows) |y| {
            const row_start = y * cols;

            for (0..cols) |x| {
                const cursor = row_start + x;

                var cell: []const u8 = self.mode_meta.death_char;
                if (matrix[cursor].status) {
                    cell = self.mode_meta.alive_char;
                }

                if (matrix[cursor].color) |c| {
                    cell = try self.formatter.format(self.format, c[0], c[1], c[2], cell);
                }

                try self.buffer.appendSlice(self.allocator.*, cell);
            }

            if (y < rows - 1) {
                try self.buffer.append(self.allocator.*, '\n');
            }
        }

        try self.buffer.appendSlice(self.allocator.*, self.sufix);

        try self.printer.print(self.buffer.items);
    }
};
