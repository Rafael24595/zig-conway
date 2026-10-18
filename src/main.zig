const std = @import("std");
const builtin = @import("builtin");

const terminal_kit = @import("terminal_kit");

const signals = terminal_kit.signals;
const console = terminal_kit.console;
const Printer = terminal_kit.printer.Printer;

const RuntimeState = terminal_kit.runtime_state.RuntimeState;
const AllocatorTracer = terminal_kit.allocator.AllocatorTracer;
const MiniLCG = terminal_kit.mini_lcg.MiniLCG;

const configuration = @import("configuration/configuration.zig");

const debug = @import("app/debug.zig");
const RenderContext = @import("app/render_context.zig").RenderContext;

const color = @import("domain/color.zig");

pub fn main() !void {
    const basePersistentAllocator = std.heap.page_allocator;
    var persistentAllocator = AllocatorTracer.init(basePersistentAllocator);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const baseScratchAllocator = gpa.allocator();
    var scratchAllocator = AllocatorTracer.init(baseScratchAllocator);

    var arena = std.heap.ArenaAllocator.init(scratchAllocator.allocator());
    defer arena.deinit();

    var printer = Printer{
        .arena = &arena,
        .out = std.fs.File.stdout(),
    };

    defer printer.reset();

    const config = try configuration.fromArgs(
        persistentAllocator.allocator(),
        &printer,
    );

    var state = RuntimeState{};

    state.start_timestamp.store(config.start_ms, .release);
    state.speed_ms.store(config.milliseconds, .release);

    try console.enable_ansi();
    try console.enable_utf8();

    try console.enable_raw_mode();
    defer console.disable_raw_mode();

    try run(
        &state,
        &persistentAllocator,
        &scratchAllocator,
        &config,
        &printer,
    );
}

pub fn run(
    state: *RuntimeState,
    persistentAllocator: *AllocatorTracer,
    scratchAllocator: *AllocatorTracer,
    config: *const configuration.Configuration,
    printer: *Printer,
) !void {
    try signals.install(state, on_interrupt);

    defer {
        signals.uninstall() catch |err| {
            std.debug.print("Failed to uninstall signals: {}\n", .{err});
        };
    }

    var allocator = persistentAllocator.allocator();

    var lcg = MiniLCG.init(config.seed);

    var coloManager = try color.ColorManager.init(
        allocator,
        &lcg,
        config.inheritance_mode,
        config.inheritance_faction,
    );

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

    while (!should_exit(state)) {
        _ = state.consume_reload();

        try run_render_cycle(
            &allocator,
            persistentAllocator,
            scratchAllocator,
            state,
            config,
            printer,
            &lcg,
            &colorManager,
        );
    }
}

inline fn run_render_cycle(
    allocator: *std.mem.Allocator,
    persistentAllocator: *AllocatorTracer,
    scratchAllocator: *AllocatorTracer,
    state: *RuntimeState,
    config: *const configuration.Configuration,
    printer: *Printer,
    lcg: *MiniLCG,
    colorManager: *color.ColorManager,
) !void {
    const winsize = try console.winsize();

    var context: RenderContext = undefined;

    try context.init(
        allocator,
        winsize,
        config,
        printer,
        lcg,
        colorManager,
    );

    defer context.deinit();

    try printer.print(console.CLEAN_CONSOLE);

    while (!should_exit(state) and !should_reload(state)) {
        try printer.print(console.RESET_CURSOR);

        if (config.debug) {
            try debug.print_debug(
                state,
                persistentAllocator,
                scratchAllocator,
                config,
                printer,
                &context,
            );
        }

        try context.matrixPrinter.print(&context.matrix);

        if (!state.pause.load(.acquire)) {
            try context.matrix.next();
        }

        if (config.controls) {
            try debug.print_controls(printer);
        }

        const speed = state.speed_ms.load(.acquire);
        try state.wait_for_frame(speed * std.time.ns_per_ms);

        printer.reset();

        const newWinsize = try console.winsize();
        if (winsize.cols != newWinsize.cols or winsize.rows != newWinsize.rows) {
            state.request_reload();
        }

        context.counter.frame_increment();
    }
}

fn run_input_loop(state: *RuntimeState) !void {
    const stdin = std.fs.File.stdin();

    while (!should_exit(state)) {
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
                const speed = state.speed_ms.load(.acquire);
                const min = @min(3000, speed + 10);
                state.set_speed(min);
            },
            '-' => {
                const speed = state.speed_ms.load(.acquire);
                const max = speed -| 10;
                state.set_speed(max);
            },
            'q', 'Q', console.CTRL_C => {
                state.request_exit();
            },
            else => {},
        }
    }
}

fn on_interrupt(context: *anyopaque) void {
    const state: *RuntimeState = @ptrCast(@alignCast(context));
    state.request_exit();
}

inline fn should_exit(state: *const RuntimeState) bool {
    return state.exit.load(.acquire);
}

inline fn should_reload(state: *const RuntimeState) bool {
    return state.reload.load(.acquire);
}
