const std = @import("std");

const terminal_kit = @import("terminal_kit");

const Counter = terminal_kit.frame.Counter;

const console = terminal_kit.console;
const Printer = terminal_kit.printer.Printer;
const MiniLCG = terminal_kit.mini_lcg.MiniLCG;

const configuration = @import("../configuration/configuration.zig");

const LinearMatrixPrinter = @import("../io/matrix_printer.zig").LinearMatrixPrinter;

const LinearMatrix = @import("../domain/matrix.zig").LinearMatrix;
const color = @import("../domain/color.zig");

pub const RenderContext = struct {
    matrix: LinearMatrix,
    matrix_printer: LinearMatrixPrinter,

    counter: Counter,

    pub fn init(
        self: *@This(),
        allocator: *std.mem.Allocator,
        winsize: console.WinSize,
        config: *const configuration.Configuration,
        printer: *Printer,
        lcg: *MiniLCG,
        colorManager: *color.ColorManager,
    ) !void {
        const space = calculate_padding(config);

        const cols = winsize.cols;
        const rows = winsize.rows - space;

        self.matrix = LinearMatrix.init(
            allocator,
            lcg,
            colorManager,
            config.alive_probability,
            config.mutation_generation,
        );

        errdefer self.matrix.free();

        try self.matrix.build(cols, rows);

        self.matrix_printer = try LinearMatrixPrinter.init(
            allocator,
            printer,
            config.color,
            config.formatter_matrix,
            config.formatter_cell,
            config.symbol_mode,
            &self.matrix,
        );

        errdefer self.matrix_printer.free();

        self.counter = Counter.init();
    }

    pub fn deinit(self: *RenderContext) void {
        self.matrix.free();
        self.matrix_printer.free();
    }
};

inline fn calculate_padding(config: *const configuration.Configuration) usize {
    var space: usize = 0;
    if (config.debug) {
        space += 4;

        if (config.inheritance) {
            space += 1;
        }
    }

    if (config.controls) {
        space += 1;
    }

    return space;
}
