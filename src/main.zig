const std = @import("std");
const builtin = @import("builtin");

const build = @import("build.zig.zon");

const configuration = @import("configuration/configuration.zig");

const utils = @import("commons/utils.zig");
const AllocatorTracer = @import("commons/allocator.zig").AllocatorTracer;
const MiniLCG = @import("commons/mini_lcg.zig").MiniLCG;

const console = @import("io/console.zig");
const Printer = @import("io/printer.zig").Printer;
const MatrixPrinter = @import("io/matrix_printer.zig").MatrixPrinter;

const matrix = @import("domain/matrix.zig");

var exit_requested: bool = false;

pub fn main() !void {
    try console.enableANSI();
    try console.enableUTF8();

    var basePersistentAllocator = std.heap.page_allocator;
    var persistentAllocator = AllocatorTracer.init(&basePersistentAllocator);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var baseScratchAllocator = gpa.allocator();
    var scratchAllocator = AllocatorTracer.init(&baseScratchAllocator);

    var arena = std.heap.ArenaAllocator.init(scratchAllocator.allocator());
    defer arena.deinit();

    var printer = Printer{ .arena = &arena, .out = std.fs.File.stdout() };
    defer printer.reset();

    const config = try configuration.fromArgs(persistentAllocator.allocator(), &printer);

    try run(&persistentAllocator, &scratchAllocator, &config, &printer);
}

pub fn run(persistentAllocator: *AllocatorTracer, scratchAllocator: *AllocatorTracer, config: *const configuration.Configuration, printer: *Printer) !void {
    try defineSignalHandlers();

    var persistent = persistentAllocator.allocator();
    var scratch = scratchAllocator.allocator();

    var lcg = MiniLCG.init(config.seed);

    var matrixPrinter = MatrixPrinter(console.COLOR_WRAPPER_BYTES, console.COLOR_WRAPPER_PREFIX, console.COLOR_WRAPPER_SUFIX).init(&persistent, printer, config.mode, config.color);

    while (!exit_requested) {
        const winsize = try console.winSize();

        // Tested on Windows CMD.
        var space: usize = 0;
        if (config.debug) {
            space += 4;
        }

        const area = winsize.cols * winsize.rows;

        const cols = winsize.cols;
        const rows = winsize.rows - space;
        const fixedArea = rows * cols;

        var mtrx = matrix.Matrix.init(&persistent, &lcg, config.alive_probability, config.mutation_generation);
        try mtrx.build(cols, rows);

        try printer.print(console.CLEAN_CONSOLE);
        try printer.print(console.HIDE_CURSOR);

        var persistentBytes = persistentAllocator.bytes();
        var scratchBytes = scratchAllocator.bytes();
        while (!exit_requested) {
            try printer.print(console.RESET_CURSOR);
            if (config.debug) {
                const end_ms = std.time.milliTimestamp();
                const time = try utils.millisecondsToTime(scratch, end_ms - config.start_ms, null);
                defer scratch.free(time);

                try printer.printf("{}: {s}\n", .{ build.name, build.version });
                try printer.printf("Persistent memory: {d} bytes | Scratch memory: {d} bytes\n", .{ persistentBytes, scratchBytes });
                try printer.printf("Seed: {d} | Matrix: {d} | Columns: {d} | Rows: {d} | Mode: {s} | Color: {s}\n", .{ config.seed, fixedArea, cols, rows, @tagName(config.mode), @tagName(config.color) });
                try printer.printf("Speed: {d}ms | Probability: {d}% | Time: {s} | Population: {d} | Mutation: {d}/{d} \n", .{ config.milliseconds, config.alive_probability, time, mtrx.alive_population(), mtrx.current_generation(), mtrx.mutation_generation() });
            }
            try matrixPrinter.print(&mtrx);
            try mtrx.next();
            std.Thread.sleep(config.milliseconds * std.time.ns_per_ms);

            persistentBytes = persistentAllocator.bytes();
            scratchBytes = scratchAllocator.bytes();

            printer.reset();

            const newWinsize = try console.winSize();
            if (area != newWinsize.cols * newWinsize.rows) {
                break;
            }
        }

        try printer.print(console.CLEAN_CONSOLE);

        mtrx.free();
    }

    printer.reset();

    try printer.print(console.CLEAN_CONSOLE);
    try printer.print("\n");

    try printer.print(console.SHOW_CURSOR);
    try printer.print(console.RESET_CURSOR);
}

pub fn defineSignalHandlers() !void {
    if (builtin.os.tag == .windows) {
        if (std.os.windows.kernel32.SetConsoleCtrlHandler(winCtrlHandler, 1) == 0) {
            return error.FailedToSetCtrlHandler;
        }
        return;
    }

    const action = std.posix.Sigaction{
        .handler = .{ .handler = unixSigintHandler },
        .mask = undefined,
        .flags = 0,
    };

    _ = std.posix.sigaction(std.posix.SIG.INT, &action, null);
}

fn winCtrlHandler(ctrl_type: std.os.windows.DWORD) callconv(.c) std.os.windows.BOOL {
    _ = ctrl_type;
    exit_requested = true;
    return 1;
}

fn unixSigintHandler(sig_num: i32) callconv(.c) void {
    _ = sig_num;
    exit_requested = true;
}
