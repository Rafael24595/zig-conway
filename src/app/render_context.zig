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

/// Holds the resources and state required to render the matrix,
/// including its matrix data, output formatter, and frame counter.
///
/// Call `init` before using the context and `deinit` to release its
/// resources after successful initialization.
pub const RenderContext = struct {
    /// Matrix containing the data to be rendered.
    matrix: LinearMatrix,
    /// Handles the formatting and output of the matrix.
    matrix_printer: LinearMatrixPrinter,

    /// Tracks the number of frames rendered and calculates the frame rate.
    counter: Counter,

    /// Initializes the rendering resources using the terminal dimensions
    /// and the provided configuration.
    ///
    /// Returns an error if initialization or matrix construction fails.
    pub fn init(
        self: *@This(),
        allocator: std.mem.Allocator,
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

    /// Releases the resources owned by the rendering context.
    ///
    /// Must be called after successful initialization.
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

test "calculate_padding returns zero when all options are disabled" {
    const config = configuration.Configuration{
        .debug = false,
        .inheritance = false,
        .controls = false,
    };

    try std.testing.expectEqual(0, calculate_padding(&config));
}

test "calculate_padding reserves space for debug output" {
    const config = configuration.Configuration{
        .debug = true,
        .inheritance = false,
        .controls = false,
    };

    try std.testing.expectEqual(4, calculate_padding(&config));
}

test "calculate_padding reserves space for inheritance information" {
    const config = configuration.Configuration{
        .debug = true,
        .inheritance = true,
        .controls = false,
    };

    try std.testing.expectEqual(5, calculate_padding(&config));
}

test "calculate_padding reserves space for debug output and controls" {
    const config = configuration.Configuration{
        .debug = true,
        .inheritance = true,
        .controls = true,
    };

    try std.testing.expectEqual(6, calculate_padding(&config));
}
