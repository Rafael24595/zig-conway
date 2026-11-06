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
    printer: *Printer,
    context: *RenderContext,
) !void {
    var allocator = scratch.allocator();

    var matrix = context.matrix;

    const cols = matrix.cols_len();
    const rows = matrix.rows_len();
    const area = rows * cols;

    const time = try kit_time.milliseconds_to_time(allocator, state.get_runtime(), null);
    defer allocator.free(time);

    var col = @tagName(config.color);
    if (config.inheritance) {
        col = "*Inheritance";
    }

    var mut: []const u8 = "disabled";
    if (matrix.mutation_generation() >= 0) {
        mut = try printer.format("{d}/{d}", .{
            matrix.current_generation(),
            matrix.mutation_generation(),
        });
    }

    const header = try printer.format(
        "{}: {s}",
        .{
            build.name,
            build.version,
        },
    );

    const memory = try printer.format(
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

    const runtime_1 = try printer.format(
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

    const runtime_2 = try printer.format(
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

    var runtime_3: []u8 = "";
    if (config.inheritance) {
        runtime_3 = try printer.format(
            "Inheritance mode: {s} | " ++
                "Inheritance factions: {d}",
            .{
                @tagName(config.inheritance_mode),
                config.inheritance_faction,
            },
        );

        runtime_3 = try printer.format(
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
            header,
            console.CLEAN_LINE,
            memory,
            console.CLEAN_LINE,
            runtime_1,
            console.CLEAN_LINE,
            runtime_2,
            runtime_3,
        },
    );
}

/// Prints the keyboard shortcuts available to control the application.
///
/// Returns an error if printing the controls fails.
pub fn print_controls(printer: *Printer) !void {
    const app_controls = try printer.format(
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

    const trm_controls = try printer.format(
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
            app_controls,
            console.CLEAN_LINE,
            trm_controls,
        },
    );
}
