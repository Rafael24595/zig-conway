const std = @import("std");

const build = @import("build.zig.zon");

const matrix = @import("../domain/matrix.zig");
const Printer = @import("../io/printer.zig").Printer;

const Mode = @import("../domain/mode.zig").Mode;
const Color = @import("../domain/color.zig").Color;

pub const Configuration = struct {
    debug: bool = false,
    seed: u64 = 0,

    start_ms: i64 = 0,

    alive_probability: f32 = 0.3,
    mutation_generation: i16 = -1,
    
    milliseconds: u64 = 50,

    mode: Mode = Mode.Ascii_L,
    color: Color = Color.White,

    pub fn init(args: [][:0]u8, printer: *Printer) !Configuration {
        defer printer.reset();

        var config = Configuration{};

        var i: usize = 1;
        while (i < args.len) : (i += 1) {
            const arg = args[i];

            if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                try printer.printf(
                    \\Usage: zig-conway   [options]
                    \\  -h, --help        Show this help message
                    \\  -v, --version     Show project's version
                    \\  -d                Enable debug mode (default: off)
                    \\  -s  <number>      Random seed (default: actual date in ms)
                    \\  -ms <number>      Frame delay in ms (default: {d})
                    \\  -l  <number>      Alive probability (default: {d})
                    \\  -m  <number>      Mode (default: {s})
                    \\  -c  <number>      Color (default: {s})
                    \\  -g  <number>      Mutation generation (default: {d})
                , .{ config.milliseconds, config.alive_probability, @tagName(config.mode), @tagName(config.color), config.mutation_generation });
                std.process.exit(0);
            } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
                try printer.printf("{any}: {s}\n", .{ build.name, build.version });
                std.process.exit(0);
            } else if (std.mem.eql(u8, arg, "-d")) {
                config.debug = true;
            } else if (std.mem.eql(u8, arg, "-s")) {
                if (i + 1 >= args.len) {
                    try printer.print("Missing argument for -s (seed)\n");
                    std.process.exit(1);
                }

                const value = args[i + 1];
                config.seed = std.fmt.parseInt(u64, value, 10) catch {
                    try printer.printf("Invalid seed value: {s}\n", .{value});
                    std.process.exit(1);
                };
                i += 1;
            } else if (std.mem.eql(u8, arg, "-l")) {
                if (i + 1 >= args.len) {
                    try printer.print("Missing argument for -l (alive Probability)\n");
                    std.process.exit(1);
                }

                const value = args[i + 1];
                var alive_probability = std.fmt.parseFloat(f32, value) catch {
                    try printer.printf("Invalid alive Probability value: {s}\n", .{value});
                    std.process.exit(1);
                };

                if (alive_probability < 0) {
                    alive_probability = 0;
                }

                if (alive_probability > 1) {
                    alive_probability = 1;
                }

                config.alive_probability = alive_probability;

                i += 1;
            } else if (std.mem.eql(u8, arg, "-ms")) {
                if (i + 1 >= args.len) {
                    try printer.print("Missing argument for -ms (milliseconds)\n");
                    std.process.exit(1);
                }

                const value = args[i + 1];
                config.milliseconds = std.fmt.parseInt(u64, value, 10) catch {
                    try printer.printf("Invalid milliseconds value: {s}\n", .{value});
                    std.process.exit(1);
                };
                i += 1;
            } else if (std.mem.eql(u8, arg, "-m")) {
                if (i + 1 >= args.len) {
                    try printer.print("Missing argument for -m (mode)\n");
                    std.process.exit(1);
                }

                const value = args[i + 1];
                if (std.mem.eql(u8, value, "help")) {
                    try config.printEnumOptionsWithTitle(Mode, "Mode", printer);
                    std.process.exit(0);
                }

                config.mode = std.meta.stringToEnum(Mode, value) orelse {
                    try printer.printf("Invalid mode: {s}\n", .{value});
                    try config.printEnumOptions(Mode, printer);
                    std.process.exit(1);
                };

                i += 1;
            } else if (std.mem.eql(u8, arg, "-c")) {
                if (i + 1 >= args.len) {
                    try printer.print("Missing argument for -c (color)\n");
                    std.process.exit(1);
                }

                const value = args[i + 1];
                if (std.mem.eql(u8, value, "help")) {
                    try config.printEnumOptionsWithTitle(Color, "Color", printer);
                    std.process.exit(0);
                }

                config.color = std.meta.stringToEnum(Color, value) orelse {
                    try printer.printf("Invalid color: {s}\n", .{value});
                    try config.printEnumOptions(Color, printer);
                    std.process.exit(1);
                };

                i += 1;
            } else if (std.mem.eql(u8, arg, "-g")) {
                if (i + 1 >= args.len) {
                    try printer.print("Missing argument for -g (mutation generation)\n");
                    std.process.exit(1);
                }

                const value = args[i + 1];
                config.mutation_generation = std.fmt.parseInt(i16, value, 10) catch {
                    try printer.printf("Invalid mutation generation value: {s}\n", .{value});
                    std.process.exit(1);
                };
                i += 1;
            } else {
                try printer.printf("Unknown argument: {s}\n", .{arg});
                std.process.exit(1);
            }
        }

        const timestamp = std.time.milliTimestamp();
        config.seed = @intCast(timestamp);
        config.start_ms = timestamp;

        return config;
    }

    fn printEnumOptions(self: *Configuration, comptime T: type, printer: *Printer) !void {
        try self.printEnumOptionsWithTitle(T, "Available", printer);
    }

    fn printEnumOptionsWithTitle(_: *Configuration, comptime T: type, title: [:0]const u8, printer: *Printer) !void {
        const info = @typeInfo(T);
        try printer.printf("{s} options:\n", .{title});
        inline for (info.@"enum".fields) |field| {
            try printer.printf(" - {s}\n", .{field.name});
        }
    }
};

pub fn fromArgs(allocator: std.mem.Allocator, printer: *Printer) !Configuration {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    return Configuration.init(args, printer);
}
