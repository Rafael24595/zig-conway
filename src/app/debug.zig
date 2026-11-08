const std = @import("std");

const build = @import("build.zig.zon");

const terminal_kit = @import("terminal_kit");

const kit_time = terminal_kit.time;

const console = terminal_kit.console;

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
    winsize: console.WinSize,
    printer: *Printer,
    context: *RenderContext,
    target_cursor: usize,
) !usize {
    const allocator = scratch.allocator();

    const width = winsize.cols;
    const matrix = context.matrix;

    const cols = matrix.cols_len();
    const rows = matrix.rows_len();
    const area = rows * cols;

    const time = try kit_time.milliseconds_to_time(allocator, state.get_runtime(), null);
    defer allocator.free(time);

    const color = if (config.inheritance)
        "*inheritance"
    else
        @tagName(config.color);

    const mutation: []const u8 = if (matrix.mutation_generation() >= 0)
        try printer.format("{d}/{d}", .{
            matrix.current_generation(),
            matrix.mutation_generation(),
        })
    else
        "disabled";

    var max_cursor: usize = 0;

    const header = try printer.format_limited(
        target_cursor,
        cols,
        "{}: {s}",
        .{
            build.name,
            build.version,
        },
    );

    max_cursor = header.max_cursor;

    const memory = try printer.format_limited(
        target_cursor,
        width,
        "Persistent memory: {d} bytes | " ++
            "Scratch memory: {d} bytes | " ++
            "Paused {any} | " ++
            "FPS: {d}",
        .{
            persistent.bytes(),
            scratch.bytes(),
            state.is_paused(),
            context.counter.get_frame_rate(std.time.ms_per_s),
        },
    );

    max_cursor = @max(max_cursor, memory.max_cursor);

    const runtime_1 = try printer.format_limited(
        target_cursor,
        width,
        "Seed: {d} | " ++
            "Matrix: {d} | " ++
            "Columns: {d} | " ++
            "Rows: {d} | " ++
            "Symbol: {s} | " ++
            "Color: {s}",
        .{
            config.seed,
            area,
            cols,
            rows,
            @tagName(config.symbol_mode),
            col,
        },
    );

    max_cursor = @max(max_cursor, runtime_1.max_cursor);

    const runtime_2 = try printer.format_limited(
        target_cursor,
        width,
        "Speed: {d}ms | " ++
            "Probability: {d}% | " ++
            "Time: {s} | " ++
            "Population: {d} | " ++
            "Mutation: {s}",
        .{
            state.get_speed(),
            config.alive_probability,
            time,
            matrix.alive_population(),
            mut,
        },
    );

    max_cursor = @max(max_cursor, runtime_2.max_cursor);

    var runtime_3_text: []u8 = "";
    if (config.inheritance) {
        const runtime_3 = try printer.format_limited(
            target_cursor,
            width,
            "Inheritance mode: {s} | " ++
                "Inheritance factions: {d}",
            .{
                @tagName(config.inheritance_mode),
                config.inheritance_faction,
            },
        );

        max_cursor = @max(max_cursor, runtime_3.max_cursor);

        runtime_3_text = try printer.format(
            "{s}{s}\n",
            .{
                console.CLEAN_LINE,
                runtime_3.text,
            },
        );
    }

    try printer.printf(
        "{s}{s}\n" ++
            "{s}{s}\n" ++
            "{s}{s}\n" ++
            "{s}{s}\n" ++
            "{s}",
        .{
            console.CLEAN_LINE,
            header.text,
            console.CLEAN_LINE,
            memory.text,
            console.CLEAN_LINE,
            runtime_1.text,
            console.CLEAN_LINE,
            runtime_2.text,
            runtime_3_text,
        },
    );

    return @max(max_cursor, runtime_2.max_cursor);
}

/// Prints the keyboard shortcuts available to control the application.
///
/// Returns an error if printing the controls fails.
pub fn print_controls(
    printer: *Printer,
    winsize: console.WinSize,
    target_cursor: usize,
) !usize {
    const width = winsize.cols;

    var max_cursor: usize = 0;

    const app_controls = try printer.format_limited(
        target_cursor,
        width,
        "Pause: [{s}] | " ++
            "Inc sleep: [{s}] | " ++
            "Dec sleep: [{s}] | " ++
            "Restart: [{s}] | " ++
            "Toggle Cell: [{s}]",
        .{
            "p, space",
            "+",
            "-",
            "r, backspace",
            "left click",
        },
    );

    max_cursor = app_controls.max_cursor;

    const trm_controls = try printer.format_limited(
        target_cursor,
        width,
        "Scroll left: [{s}] | " ++
            "Scroll right: [{s}] | " ++
            "Show debug: [{s}] | " ++
            "Show controls: [{s}] | " ++
            "Exit: [{s}]",
        .{
            ",",
            ".",
            "/",
            "?",
            "q, ctrl+c",
        },
    );

    try printer.printf(
        "\n{s}{s}" ++
            "\n{s}{s}",
        .{
            console.CLEAN_LINE,
            app_controls.text,
            console.CLEAN_LINE,
            trm_controls.text,
        },
    );

    return @max(max_cursor, trm_controls.max_cursor);
}
