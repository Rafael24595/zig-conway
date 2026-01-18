const std = @import("std");
const builtin = @import("builtin");

const AtomicOrder = std.builtin.AtomicOrder;

const build = @import("build.zig.zon");

const configuration = @import("configuration/configuration.zig");

const utils = @import("commons/utils.zig");
const AllocatorTracer = @import("commons/allocator.zig").AllocatorTracer;
const MiniLCG = @import("commons/mini_lcg.zig").MiniLCG;

const console = @import("io/console.zig");
const Printer = @import("io/printer.zig").Printer;
const MatrixPrinter = @import("io/matrix_printer.zig").MatrixPrinter;

const matrix = @import("domain/matrix.zig");
const color = @import("domain/color.zig");

var start_timestamp = std.atomic.Value(i64).init(0);

var pause = std.atomic.Value(u8).init(0);
var pause_timestamp = std.atomic.Value(i64).init(0);

var speed_ms = std.atomic.Value(u64).init(0);

var exit = std.atomic.Value(u8).init(0);
var reload = std.atomic.Value(u8).init(0);

var mutex: std.Thread.Mutex = .{};
var cond: std.Thread.Condition = .{};

pub fn main() !void {
    try console.enableANSI();
    try console.enableUTF8();
    try console.enableRawMode();

    defer console.disableRawMode();

    var basePersistentAllocator = std.heap.page_allocator;
    var persistentAllocator = AllocatorTracer.init(&basePersistentAllocator);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var baseScratchAllocator = gpa.allocator();
    var scratchAllocator = AllocatorTracer.init(&baseScratchAllocator);

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

    start_timestamp.store(config.start_ms, AtomicOrder.release);
    speed_ms.store(config.milliseconds, AtomicOrder.release);

    try run(
        &persistentAllocator,
        &scratchAllocator,
        &config,
        &printer,
    );
}

pub fn run(persistentAllocator: *AllocatorTracer, scratchAllocator: *AllocatorTracer, config: *const configuration.Configuration, printer: *Printer) !void {
    var persistent = persistentAllocator.allocator();

    var lcg = MiniLCG.init(config.seed);

    var color_manager = try color.ColorManager.init(
        &persistent,
        &lcg,
        &color.DEFAULT_TABLE,
    );

    var mtrx_printer = try MatrixPrinter.init(
        &persistent,
        printer,
        config.color,
        config.formatter_matrix,
        config.formatter_cell,
        config.symbol_mode,
    );

    defer printer.reset();
    defer mtrx_printer.reset();

    try printer.print(console.CLEAN_CONSOLE);
    try printer.print(console.HIDE_CURSOR);

    defer printer.prints(console.CLEAN_CONSOLE);
    defer printer.prints(console.SHOW_CURSOR);
    defer printer.prints(console.RESET_CURSOR);

    var input_thread = try std.Thread.spawn(.{}, runInputLoop, .{});
    defer input_thread.join();

    while (exit.load(AtomicOrder.acquire) == 0) {
        _ = reload.fetchXor(1, AtomicOrder.acq_rel);

        const winsize = try console.winSize();

        var space: usize = 0;
        if (config.debug) {
            space += 4;
        }

        if (config.controls) {
            space += 1;
        }

        const area = winsize.cols * winsize.rows;

        const cols = winsize.cols;
        const rows = winsize.rows - space;

        var mtrx = matrix.Matrix.init(
            &persistent,
            &lcg,
            &color_manager,
            config.alive_probability,
            config.mutation_generation,
        );

        try mtrx.build(cols, rows);

        defer mtrx.free();

        try printer.print(console.CLEAN_CONSOLE);

        while (exit.load(AtomicOrder.acquire) == 0 and reload.load(AtomicOrder.acquire) == 0) {
            try printer.print(console.RESET_CURSOR);

            if (config.debug) {
                try print_debug(
                    persistentAllocator,
                    scratchAllocator,
                    config,
                    printer,
                    &mtrx,
                );
            }

            try mtrx_printer.print(&mtrx);

            if (pause.load(AtomicOrder.acquire) == 0) {
                try mtrx.next();
            }

            if (config.controls) {
                try print_controls(printer);
            }

            mutex.lock();
            _ = cond.timedWait(&mutex, speed_ms.raw * std.time.ns_per_ms) catch |err| switch (err) {
                error.Timeout => true,
                else => return err,
            };
            mutex.unlock();

            printer.reset();

            const newWinsize = try console.winSize();
            if (area != newWinsize.cols * newWinsize.rows) {
                break;
            }
        }
    }
}

fn runInputLoop() !void {
    const stdin = std.fs.File.stdin();

    while (exit.load(AtomicOrder.acquire) == 0) {
        var buf: [1]u8 = undefined;
        _ = try stdin.read(&buf);

        switch (buf[0]) {
            'p', 'P', console.SPACE => {
                if (pause.load(AtomicOrder.acquire) == 0) {
                    _ = pause_timestamp.store(std.time.milliTimestamp(), AtomicOrder.release);
                }
                _ = pause.fetchXor(1, AtomicOrder.acq_rel);
            },
            'r', 'R', console.BACKSPACE, console.DEL => {
                _ = reload.fetchXor(1, AtomicOrder.acq_rel);
                _ = start_timestamp.store(std.time.milliTimestamp(), AtomicOrder.release);
                _ = cond.signal();
            },
            '+' => {
                const min = @min(1000 * 3, speed_ms.raw + 10);
                _ = speed_ms.store(min, AtomicOrder.release);
                _ = cond.signal();
            },
            '-' => {
                const max = speed_ms.raw -| 10;
                _ = speed_ms.store(max, AtomicOrder.release);
                _ = cond.signal();
            },
            'q', 'Q', console.CTRL_C => {
                _ = exit.fetchXor(1, AtomicOrder.acq_rel);
                _ = cond.signal();
            },
            else => {},
        }
    }
}

pub fn print_debug(
    persistentAllocator: *AllocatorTracer,
    scratchAllocator: *AllocatorTracer,
    config: *const configuration.Configuration,
    printer: *Printer,
    mtrx: *matrix.Matrix,
) !void {
    var scratch = scratchAllocator.allocator();

    const cols = mtrx.cols();
    const rows = mtrx.rows();
    const fixedArea = rows * cols;

    var end_ms = std.time.milliTimestamp();
    if (pause.load(AtomicOrder.acquire) == 1) {
        end_ms = pause_timestamp.raw;
    }

    const time = try utils.millisecondsToTime(scratch, end_ms - start_timestamp.raw, null);
    defer scratch.free(time);

    var col = @tagName(config.color);
    if (config.inheritance) {
        col = "*Inheritance";
    }

    var paused = false;
    if (pause.load(AtomicOrder.acquire) == 1) {
        paused = true;
    }

    var mut: []const u8 = "disabled";
    if (mtrx.mutation_generation() >= 0) {
        mut = try printer.format("{d}/{d}", .{
            mtrx.current_generation(),
            mtrx.mutation_generation(),
        });
    }

    try printer.printf("{}: {s}\n", .{
        build.name,
        build.version,
    });

    try printer.printf("Persistent memory: {d} bytes | Scratch memory: {d} bytes | Paused {any} \n", .{
        persistentAllocator.bytes(),
        scratchAllocator.bytes(),
        paused,
    });

    try printer.printf("Seed: {d} | Matrix: {d} | Columns: {d} | Rows: {d} | Mode: {s} | Color: {s} \n", .{
        config.seed,
        fixedArea,
        cols,
        rows,
        @tagName(config.symbol_mode),
        col,
    });

    try printer.printf("Speed: {d}ms | Probability: {d}% | Time: {s} | Population: {d} | Mutation: {s} \n", .{
        speed_ms.raw,
        config.alive_probability,
        time,
        mtrx.alive_population(),
        mut,
    });
}

pub fn print_controls(
    printer: *Printer,
) !void {
    try printer.printf("\nPause: [{s}] | Restart: [{s}] | Increment sleep: [{s}] | Decrement sleep: [{s}] | Exit: [{s}]", .{
        "p, space",
        "r, backspace",
        "+",
        "-",
        "q, ctrl+c",
    });
}
