const std = @import("std");

const build = @import("build.zig.zon");

const matrix = @import("../domain/matrix.zig");
const SymbolMode = @import("../domain/mode.zig").SymbolMode;
const Color = @import("../domain/color.zig").Color;

const Printer = @import("../io/printer.zig").Printer;
const formatter = @import("../io/formatter.zig");

pub const Configuration = struct {
    debug: bool = false,
    seed: u64 = 0,

    start_ms: i64 = 0,

    milliseconds: u64 = 50,
    alive_probability: f32 = 0.3,

    mutation_generation: i16 = -1,

    symbol_mode: SymbolMode = SymbolMode.Ascii_L,
    color_mode: formatter.FormatterCode = formatter.FormatterCode.RGB,

    inheritance: bool = false,
    formatter_matrix: formatter.FormatterMatrixUnion = formatter.FormatterMatrixUnion{ .unfo = .{} },
    formatter_cell: formatter.FormatterCellUnion = formatter.FormatterCellUnion{ .unfo = .{} },

    color: Color = Color.White,

    pub fn init(args: [][:0]u8, printer: *Printer) !@This() {
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
                    \\  -s  <number>      Random seed (default: current time in ms)
                    \\  -ms <number>      Frame delay in ms (default: {d})
                    \\  -l  <number>      Alive probability (default: {d})
                    \\  -g  <number>      Mutation generation (default: {d})
                    \\  -sm <enum>        Symbol mode (default: {s})
                    \\                      (use "help" to list available modes)
                    \\  -cm <mode>        Color mode (default: {s})
                    \\                      (use "help" to list available modes)
                    \\  -i                Enable inheritance mode (default: off)
                    \\                      Overrides color mode (-c)
                    \\  -c  <enum>        Color (default: {s})
                    \\                      (use "help" to list available modes)
                , .{
                    config.milliseconds,
                    config.alive_probability,
                    config.mutation_generation,
                    @tagName(config.symbol_mode),
                    @tagName(config.color_mode),
                    @tagName(config.color),
                });
                std.process.exit(0);
            }

            if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
                try printer.printf("{any}: {s}\n", .{ build.name, build.version });
                std.process.exit(0);
            }

            if (std.mem.eql(u8, arg, "-d")) {
                config.debug = true;
                continue;
            }

            if (std.mem.eql(u8, arg, "-s")) {
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

                continue;
            }

            if (std.mem.eql(u8, arg, "-ms")) {
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

                continue;
            }

            if (std.mem.eql(u8, arg, "-l")) {
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

                continue;
            }

            if (std.mem.eql(u8, arg, "-g")) {
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

                continue;
            }

            if (std.mem.eql(u8, arg, "-sm")) {
                if (i + 1 >= args.len) {
                    try printer.print("Missing argument for -sm (mode)\n");
                    std.process.exit(1);
                }

                const value = args[i + 1];
                if (std.mem.eql(u8, value, "help")) {
                    try config.printEnumOptionsWithTitle(SymbolMode, "Mode", printer);
                    std.process.exit(0);
                }

                config.symbol_mode = std.meta.stringToEnum(SymbolMode, value) orelse {
                    try printer.printf("Invalid mode: {s}\n", .{value});
                    try config.printEnumOptions(SymbolMode, printer);
                    std.process.exit(1);
                };

                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, "-cm")) {
                if (i + 1 >= args.len) {
                    try printer.print("Missing argument for -cm (color mode)\n");
                    std.process.exit(1);
                }

                const value = args[i + 1];
                if (std.mem.eql(u8, value, "help")) {
                    try config.printEnumOptionsWithTitle(formatter.FormatterCode, "Color mode", printer);
                    std.process.exit(0);
                }

                config.color_mode = std.meta.stringToEnum(formatter.FormatterCode, value) orelse {
                    try printer.printf("Invalid color mode: {s}\n", .{value});
                    try config.printEnumOptions(formatter.FormatterCode, printer);
                    std.process.exit(1);
                };

                i += 1;

                continue;
            }

            if (std.mem.eql(u8, arg, "-i")) {
                config.inheritance = true;
                continue;
            }

            if (std.mem.eql(u8, arg, "-c")) {
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

                continue;
            }

            try printer.printf("Unknown argument: {s}\n", .{arg});
            std.process.exit(1);
        }

        const timestamp = std.time.milliTimestamp();

        config.seed = @intCast(timestamp);
        config.start_ms = timestamp;

        init_formatters(&config);

        return config;
    }

    fn init_formatters(config: *Configuration) void {
        if (config.inheritance) {
            switch (config.color_mode) {
                formatter.FormatterCode.ANSI => {
                    config.formatter_cell = formatter.FormatterCellUnion{ .ansi = .{} };
                },
                formatter.FormatterCode.RGB => {
                    config.formatter_cell = formatter.FormatterCellUnion{ .rgb = .{} };
                },
            }

            config.formatter_matrix = formatter.FormatterMatrixUnion{ .unfo = .{} };

            return;
        }

        switch (config.color_mode) {
            formatter.FormatterCode.ANSI => {
                config.formatter_matrix = formatter.FormatterMatrixUnion{ .ansi = .{} };
            },
            formatter.FormatterCode.RGB => {
                config.formatter_matrix = formatter.FormatterMatrixUnion{ .rgb = .{} };
            },
        }

        config.formatter_cell = formatter.FormatterCellUnion{ .unfo = .{} };

        return;
    }

    fn printEnumOptions(self: *@This(), comptime T: type, printer: *Printer) !void {
        try self.printEnumOptionsWithTitle(T, "Available", printer);
    }

    fn printEnumOptionsWithTitle(_: *@This(), comptime T: type, title: [:0]const u8, printer: *Printer) !void {
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
