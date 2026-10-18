const std = @import("std");

const build = @import("build.zig.zon");

const terminal_kit = @import("terminal_kit");

const kit_time = terminal_kit.time;

const AllocatorTracer = terminal_kit.allocator.AllocatorTracer;
const RuntimeState = terminal_kit.runtime_state.RuntimeState;
const Printer = terminal_kit.printer.Printer;

const configuration = @import("../configuration/configuration.zig");

const RenderContext = @import("./render_context.zig").RenderContext;

/// Prints diagnostic information about the application, runtime state,
/// memory usage, rendering configuration, and current matrix dimensions.
///
/// Returns an error if memory allocation, time formatting, or printing fails.
pub fn print_debug(
    state: *RuntimeState,
    persistent: *AllocatorTracer,
    scratch: *AllocatorTracer,
    config: *const configuration.Configuration,
    printer: *Printer,
    context: *RenderContext,
) !void {
    var allocator = scratch.allocator();

    var matrix = context.matrix;

    const cols = matrix.cols_len();
    const rows = matrix.rows_len();
    const area = rows * cols;

    var end_ms = std.time.milliTimestamp();
    if (state.pause.load(.acquire)) {
        end_ms = state.pause_timestamp.raw;
    }

    const start_timestamp = state.start_timestamp.load(.acquire);

    const time = try kit_time.milliseconds_to_time(allocator, end_ms - start_timestamp, null);
    defer allocator.free(time);

    var col = @tagName(config.color);
    if (config.inheritance) {
        col = "*Inheritance";
    }

    var paused = false;
    if (state.pause.load(.acquire)) {
        paused = true;
    }

    var mut: []const u8 = "disabled";
    if (matrix.mutation_generation() >= 0) {
        mut = try printer.format("{d}/{d}", .{
            matrix.current_generation(),
            matrix.mutation_generation(),
        });
    }

    try printer.printf("{}: {s}\n", .{
        build.name,
        build.version,
    });

    try printer.printf("Persistent memory: {d} bytes | Scratch memory: {d} bytes | Paused {any} | FPS: {d} \n", .{
        persistent.bytes(),
        scratch.bytes(),
        paused,
        context.counter.get_frame_rate(std.time.ms_per_s),
    });

    try printer.printf("Seed: {d} | Matrix: {d} | Columns: {d} | Rows: {d} | Symbol: {s} | Color: {s} \n", .{
        config.seed,
        area,
        cols,
        rows,
        @tagName(config.symbol_mode),
        col,
    });

    try printer.printf("Speed: {d}ms | Probability: {d}% | Time: {s} | Population: {d} | Mutation: {s} \n", .{
        state.speed_ms.load(.acquire),
        config.alive_probability,
        time,
        matrix.alive_population(),
        mut,
    });

    if (config.inheritance) {
        try printer.printf("Inheritance mode: {s} | Inheritance factions: {d} \n", .{
            @tagName(config.inheritance_mode),
            config.inheritance_faction,
        });
    }
}

/// Prints the keyboard shortcuts available to control the application.
///
/// Returns an error if printing the controls fails.
pub fn print_controls(printer: *Printer) !void {
    try printer.printf("\nPause: [{s}] | Restart: [{s}] | Increment sleep: [{s}] | Decrement sleep: [{s}] | Exit: [{s}]", .{
        "p, space",
        "r, backspace",
        "+",
        "-",
        "q, ctrl+c",
    });
}
