const std = @import("std");
const builtin = @import("builtin");

const terminal_kit = @import("terminal_kit");

const signals = terminal_kit.signals;
const console = terminal_kit.console;
const Printer = terminal_kit.printer.Printer;

const runtime = terminal_kit.runtime_state;

const AllocatorTracer = terminal_kit.allocator.AllocatorTracer;
const MiniLCG = terminal_kit.mini_lcg.MiniLCG;

const configuration = @import("configuration/configuration.zig");

const debug = @import("app/debug.zig");
const RenderContext = @import("app/render_context.zig").RenderContext;

const color = @import("domain/color.zig");

/// Initializes application resources, configures the terminal, and starts
/// the rendering loop.
pub fn main() !void {
    var persistent = AllocatorTracer.init(
        std.heap.page_allocator,
    );

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var scratch = AllocatorTracer.init(
        gpa.allocator(),
    );

    var arena = std.heap.ArenaAllocator.init(
        scratch.allocator(),
    );

    defer arena.deinit();

    var printer = Printer{
        .arena = &arena,
        .out = std.fs.File.stdout(),
    };

    defer printer.reset();

    const config = try configuration.from_args(
        persistent.allocator(),
        &printer,
    );

    var state = runtime.RuntimeState{};

    state.start_timestamp.store(config.start_ms, .release);
    state.speed_ms.store(config.milliseconds, .release);

    try console.enable_ansi();
    try console.enable_utf8();

    try console.enable_raw_mode();
    defer console.disable_raw_mode();

    try run(
        &state,
        &persistent,
        &scratch,
        &config,
        &printer,
    );
}

/// Runs the application session, coordinating input handling and rendering
/// until termination is requested.
pub fn run(
    state: *runtime.RuntimeState,
    persistent: *AllocatorTracer,
    scratch: *AllocatorTracer,
    config: *const configuration.Configuration,
    printer: *Printer,
) !void {
    try signals.install(state, runtime.on_interrupt);

    defer {
        signals.uninstall() catch |err| {
            std.debug.print("Failed to uninstall signals: {}\n", .{err});
        };
    }

    const allocator = persistent.allocator();

    var lcg = MiniLCG.init(config.seed);

    var color_manager = try color.ColorManager.init(
        allocator,
        &lcg,
        config.inheritance_mode,
        config.inheritance_faction,
    );

    defer color_manager.free();

    defer printer.reset();

    try printer.print(console.CLEAN_ALL);
    try printer.print(console.HIDE_CURSOR);

    defer printer.prints(console.SHOW_CURSOR);
    defer printer.prints(console.CLEAN_ALL);

    var input_thread = try std.Thread.spawn(
        .{},
        run_input_loop,
        .{state},
    );

    defer input_thread.join();

    while (!runtime.should_exit(state)) {
        _ = state.consume_reload();

        try run_render_cycle(
            allocator,
            persistent,
            scratch,
            state,
            config,
            printer,
            &lcg,
            &color_manager,
        );
    }
}

/// Runs a rendering cycle using the terminal's current dimensions.
///
/// Creates and releases a render context for the duration of the cycle.
/// A terminal resize ends the current cycle so rendering can restart with
/// updated dimensions.
inline fn run_render_cycle(
    allocator: std.mem.Allocator,
    persistent: *AllocatorTracer,
    scratch: *AllocatorTracer,
    state: *runtime.RuntimeState,
    config: *const configuration.Configuration,
    printer: *Printer,
    lcg: *MiniLCG,
    color_manager: *color.ColorManager,
) !void {
    const winsize = try console.winsize();

    var context: RenderContext = undefined;

    try context.init(
        allocator,
        winsize,
        config,
        printer,
        lcg,
        color_manager,
    );

    defer context.deinit();

    try printer.print(console.CLEAN_CONSOLE);

    while (!runtime.should_exit(state) and !runtime.should_reload(state)) {
        try printer.print(console.RESET_CURSOR);

        if (config.debug) {
            try debug.print_debug(
                state,
                persistent,
                scratch,
                config,
                printer,
                &context,
            );
        }

        try context.matrix_printer.print(&context.matrix);

        if (!state.pause.load(.acquire)) {
            try context.matrix.next();
        }

        if (config.controls) {
            try debug.print_controls(printer);
        }

        const speed = state.speed_ms.load(.acquire);
        try state.wait_for_frame(speed * std.time.ns_per_ms);

        printer.reset();

        if (!winsize.eql(try console.winsize())) {
            state.request_reload();
        }

        context.counter.frame_increment();
    }
}

fn run_input_loop(state: *runtime.RuntimeState) !void {
    const stdin = std.fs.File.stdin();

    while (!runtime.should_exit(state)) {
        var buf: [1]u8 = undefined;

        const count = try stdin.read(&buf);
        if (count == 0) {
            continue;
        }

        switch (buf[0]) {
            'p', 'P', console.SPACE => {
                state.toggle_pause();
            },
            'r', 'R', console.BACKSPACE, console.DEL => {
                state.start_timestamp.store(std.time.milliTimestamp(), .release);
                state.request_reload();
            },
            '+' => {
                state.mod_speed(10);
            },
            '-' => {
                state.mod_speed(-10);
            },
            'q', 'Q', console.CTRL_C => {
                state.request_exit();
            },
            else => {},
        }
    }
}
