const std = @import("std");

const terminal_kit = @import("terminal_kit");

const Printer = terminal_kit.printer.Printer;

const color = terminal_kit.color;
const formatter = terminal_kit.formatter;

const LinearMatrix = @import("../domain/matrix.zig").LinearMatrix;

const symbol = @import("../domain/symbol.zig");

/// Formats and prints a linear matrix using configurable symbols and colors.
pub const LinearMatrixPrinter = struct {
    /// Allocator used for the printer's owned buffers.
    allocator: std.mem.Allocator,

    /// Printer used to output the formatted frame.
    printer: *Printer,
    /// Formatter used for individual cells.
    formatter: formatter.FormatterCellUnion,

    /// Format string used to prefix the entire matrix output.
    prefix: []const u8,
    /// Format string used to suffix the entire matrix output.
    sufix: []const u8,

    /// Symbols used to represent alive and dead cells.
    mode_meta: symbol.ThemeMeta,

    /// Accumulates the complete formatted frame before output.
    buffer: std.ArrayList(u8),
    /// Scratch buffer used to format individual characters.
    format: []u8,

    /// Initializes the printer and allocates its formatting buffers.
    pub fn init(
        allocator: std.mem.Allocator,
        printer: *Printer,
        col: color.Color,
        fmt_mtrx: formatter.FormatterMatrixUnion,
        fmt_cell: formatter.FormatterCellUnion,
        mode_code: symbol.Theme,
        matrix: *LinearMatrix,
    ) !@This() {
        const len = fmt_mtrx.prefix().len;
        const rgb = color.rgb_of(col);

        const prefix = fmt_mtrx.format_prefix(
            try allocator.alloc(u8, len),
            rgb[0],
            rgb[1],
            rgb[2],
        );

        const sufix = fmt_mtrx.sufix();

        const meta = symbol.meta_of(mode_code);

        const rows = matrix.rows_len();
        const cols = matrix.cols_len();

        const char_fmt_len = fmt_cell.fmt_bytes() + meta.total_bytes;
        const mtrx_fmt_len = rows * cols * char_fmt_len;
        const estimated_size = prefix.len + mtrx_fmt_len + sufix.len;

        var buffer = try std.ArrayList(u8).initCapacity(allocator, estimated_size);
        errdefer buffer.deinit(allocator);

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

    /// Releases the buffers owned by this printer.
    pub fn free(self: *@This()) void {
        self.allocator.free(self.prefix);
        self.buffer.deinit(self.allocator);
        self.allocator.free(self.format);
    }

    /// Formats and prints the current matrix frame.
    pub fn print(self: *@This(), mtrx: *LinearMatrix) !void {
        if (mtrx.vector() == null or mtrx.vector().?.len == 0) {
            return;
        }

        self.buffer.clearRetainingCapacity();

        const matrix = mtrx.vector().?;

        const rows = mtrx.rows_len();
        const cols = mtrx.cols_len();

        try self.buffer.appendSlice(self.allocator, self.prefix);

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

                try self.buffer.appendSlice(self.allocator, cell);
            }

            if (y < rows - 1) {
                try self.buffer.append(self.allocator, '\n');
            }
        }

        try self.buffer.appendSlice(self.allocator, self.sufix);

        try self.printer.print(self.buffer.items);
    }
};
