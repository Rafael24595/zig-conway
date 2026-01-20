const std = @import("std");

const build = @import("build.zig.zon");

const matrix = @import("../domain/matrix.zig");
const symbol = @import("../domain/symbol.zig");
const color = @import("../domain/color.zig");

const Printer = @import("../io/printer.zig").Printer;
const formatter = @import("../io/formatter.zig");

const TypeFormatter = @import("../commons/utils.zig").TypeFormatter;

const Flag = struct {
    flag_short: []const u8,
    flag_long: ?[]const u8 = undefined,
    type: ?[]const u8 = undefined,
    desc: []const u8,
    name: []const u8,
    aux_desc: ?[]const u8 = undefined,
};

const FLAG_HELP: Flag = Flag{
    .flag_short = "-h",
    .flag_long = "--help",
    .desc = "Show this help message",
    .name = "help",
};

const FLAG_VERSION: Flag = Flag{
    .flag_short = "-v",
    .flag_long = "--version",
    .desc = "Show project's version",
    .name = "version",
};

const FLAG_DEBUG: Flag = Flag{
    .flag_short = "-d",
    .flag_long = "",
    .desc = "Enable debug mode",
    .name = "debug",
};

const FLAG_HELP_CONTROLS: Flag = Flag{
    .flag_short = "-hc",
    .desc = "Show the controls map",
    .name = "controls map",
};

const FLAG_SEED: Flag = Flag{
    .flag_short = "-s",
    .type = "<number>",
    .desc = "Random seed",
    .name = "seed",
};

const FLAG_MILLISECONDS: Flag = Flag{
    .flag_short = "-ms",
    .type = "<number>",
    .desc = "Frame delay in ms",
    .name = "milliseconds",
};

const FLAG_ALIVE_PROBABILITY: Flag = Flag{
    .flag_short = "-l",
    .type = "<number>",
    .desc = "Alive probability",
    .name = "alive Probability",
};

const FLAG_MUTATION_GENERATION: Flag = Flag{
    .flag_short = "-g",
    .type = "<number>",
    .desc = "Mutation generation",
    .name = "mutation generation",
};

const FLAG_SYMBOL_MODE: Flag = Flag{
    .flag_short = "-sm",
    .type = "<enum>",
    .desc = "Symbol mode",
    .name = "symbol mode",
    .aux_desc = "(use \"help\" to list available modes)",
};

const FLAG_COLOR_MODE: Flag = Flag{
    .flag_short = "-cm",
    .type = "<enum>",
    .desc = "Color mode",
    .name = "color mode",
    .aux_desc = "(use \"help\" to list available modes)",
};

const FLAG_INHERITANCE: Flag = Flag{
    .flag_short = "-i",
    .desc = "Enable inheritance mode",
    .name = "inheritance",
    .aux_desc = "Overrides color mode",
};

const FLAG_INHERITANCE_FACTIONS: Flag = Flag{
    .flag_short = "-if",
    .desc = "Inheritance factions",
    .name = "inheritance factions",
};

const FLAG_INHERITANCE_MODE: Flag = Flag{
    .flag_short = "-im",
    .desc = "Inheritance mode",
    .name = "inheritance mode",
};

const FLAG_COLOR: Flag = Flag{
    .flag_short = "-c",
    .type = "<enum>",
    .desc = "Color",
    .name = "color",
    .aux_desc = "(use \"help\" to list available modes)",
};

pub const Configuration = struct {
    debug: bool = false,
    controls: bool = false,

    seed: u64 = 0,

    start_ms: i64 = 0,

    milliseconds: u64 = 50,
    alive_probability: f32 = 0.3,

    mutation_generation: i16 = -1,

    symbol_mode: symbol.Mode = symbol.Mode.Classic,
    color_mode: formatter.FormatterCode = formatter.FormatterCode.RGB,

    inheritance: bool = false,
    inheritance_mode: color.InheritanceMode = color.InheritanceMode.Default,
    inheritance_faction: usize = color.inheritanceOf(color.InheritanceMode.Default).colors.len,

    formatter_matrix: formatter.FormatterMatrixUnion = formatter.FormatterMatrixUnion{ .unfo = .{} },
    formatter_cell: formatter.FormatterCellUnion = formatter.FormatterCellUnion{ .unfo = .{} },

    color: color.Color = color.Color.White,

    pub fn init(allocator: std.mem.Allocator, printer: *Printer, args: [][:0]u8) !@This() {
        defer printer.reset();

        var config = Configuration{};

        var i: usize = 1;
        while (i < args.len) : (i += 1) {
            const arg = args[i];

            if (std.mem.eql(u8, arg, FLAG_HELP.flag_short) or std.mem.eql(u8, arg, FLAG_HELP.flag_long.?)) {
                try print_help(allocator, printer, config);
                std.process.exit(0);
            }

            if (std.mem.eql(u8, arg, FLAG_VERSION.flag_short) or std.mem.eql(u8, arg, FLAG_VERSION.flag_long.?)) {
                try printer.printf("{any}: {s}\n", .{ build.name, build.version });
                std.process.exit(0);
            }

            if (std.mem.eql(u8, arg, FLAG_DEBUG.flag_short)) {
                config.debug = true;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_HELP_CONTROLS.flag_short)) {
                config.controls = true;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_SEED.flag_short)) {
                config.seed = try config.parseInt(u64, printer, args, i, FLAG_SEED, null, null);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_MILLISECONDS.flag_short)) {
                config.milliseconds = try config.parseInt(u64, printer, args, i, FLAG_MILLISECONDS, null, 1000 * 3);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_ALIVE_PROBABILITY.flag_short)) {
                config.alive_probability = try config.parseFloat(f32, printer, args, i, FLAG_ALIVE_PROBABILITY, 0, 1);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_MUTATION_GENERATION.flag_short)) {
                config.mutation_generation = try config.parseInt(i16, printer, args, i, FLAG_MUTATION_GENERATION, null, null);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_SYMBOL_MODE.flag_short)) {
                config.symbol_mode = try config.parseEnum(symbol.Mode, printer, args, i, FLAG_SYMBOL_MODE);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_COLOR_MODE.flag_short)) {
                config.color_mode = try config.parseEnum(formatter.FormatterCode, printer, args, i, FLAG_COLOR_MODE);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_INHERITANCE.flag_short)) {
                config.inheritance = true;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_INHERITANCE_FACTIONS.flag_short)) {
                config.inheritance = true;
                config.inheritance_faction = try config.parseInt(usize, printer, args, i, FLAG_INHERITANCE_FACTIONS, null, null);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_INHERITANCE_MODE.flag_short)) {
                config.inheritance = true;
                config.inheritance_mode = try config.parseEnum(color.InheritanceMode, printer, args, i, FLAG_INHERITANCE_MODE);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_COLOR.flag_short)) {
                config.color = try config.parseEnum(color.Color, printer, args, i, FLAG_COLOR);
                i += 1;
                continue;
            }

            try printer.printf("Unknown argument: {s}\n", .{arg});
            std.process.exit(1);
        }

        const timestamp = std.time.milliTimestamp();

        config.start_ms = timestamp;

        if (config.seed == 0) {
            config.seed = @intCast(timestamp);
        }

        init_formatters(&config);

        return config;
    }

    pub fn print_help(allocator: std.mem.Allocator, printer: *Printer, config: Configuration) !void {
        const message = try format_flags(allocator, printer, config);
        defer allocator.free(message);
        try printer.print(message);
    }

    pub fn format_flags(allocator: std.mem.Allocator, printer: *Printer, config: Configuration) ![]u8 {
        var buffer = try std.ArrayList(u8).initCapacity(allocator, 0);

        try buffer.appendSlice(allocator, "Usage: zig-conway             [options] \n\n");

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_HELP,
            .none,
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_VERSION,
            .none,
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_DEBUG,
            .{ .bool = config.debug },
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_HELP_CONTROLS,
            .{ .bool = config.controls },
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_SEED,
            .{ .str = "current time in ms" },
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_MILLISECONDS,
            .{ .int = @intCast(config.milliseconds) },
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_ALIVE_PROBABILITY,
            .{ .float = @floatCast(config.alive_probability) },
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_MUTATION_GENERATION,
            .{ .int = @intCast(config.mutation_generation) },
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_SYMBOL_MODE,
            .{ .str = @tagName(config.symbol_mode) },
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_COLOR_MODE,
            .{ .str = @tagName(config.color_mode) },
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_INHERITANCE,
            .{ .bool = config.inheritance },
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_INHERITANCE_FACTIONS,
            .{ .int = @intCast(config.inheritance_faction) },
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_INHERITANCE_MODE,
            .{ .str = @tagName(config.inheritance_mode) },
        ));

        try buffer.appendSlice(allocator, try format_flag(
            printer,
            FLAG_COLOR,
            .{ .str = @tagName(config.color) },
        ));

        return buffer.items;
    }

    pub fn format_flag(printer: *Printer, flag: Flag, default: TypeFormatter) ![]u8 {
        const flag_short = flag.flag_short;
        const flag_desc = flag.desc;

        var flag_long: []const u8 = "";
        if (flag.flag_long != null) {
            flag_long = flag.flag_long.?;
        }

        var flag_type: []const u8 = "";
        if (flag.type != null) {
            flag_type = flag.type.?;
        }

        var data = try printer.format("  {s:<3} {s:<12}  {s:<8}  {s}", .{ flag_short, flag_long, flag_type, flag_desc });

        if (default != .none) {
            const d = try default.format(printer);
            data = try printer.format("{s} (default: {s})", .{ data, d });
        }

        if (flag.aux_desc != null) {
            data = try printer.format("{s}\n{s:<32}{s}", .{ data, "", flag.aux_desc.? });
        }

        return try printer.format("{s} \n", .{data});
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

    fn parseFloat(_: *@This(), comptime T: type, printer: *Printer, args: [][:0]u8, i: usize, flag: Flag, min: ?T, max: ?T) !T {
        if (i + 1 >= args.len) {
            try printer.printf("Missing argument for {s} ({s})\n", .{ flag.flag_short, flag.name });
            std.process.exit(1);
        }

        const value = args[i + 1];
        var result = std.fmt.parseFloat(T, value) catch {
            try printer.printf("Invalid {s} value: {s}\n", .{ flag.name, value });
            std.process.exit(1);
        };

        if (min != null) {
            result = @max(result, min.?);
        }

        if (max != null) {
            result = @min(result, max.?);
        }

        return result;
    }

    fn parseInt(_: *@This(), comptime T: type, printer: *Printer, args: [][:0]u8, i: usize, flag: Flag, min: ?T, max: ?T) !T {
        if (i + 1 >= args.len) {
            try printer.printf("Missing argument for {s} ({s})\n", .{ flag.flag_short, flag.name });
            std.process.exit(1);
        }

        const value = args[i + 1];
        var result = std.fmt.parseInt(T, value, 10) catch {
            try printer.printf("Invalid {s} value: {s}\n", .{ flag.name, value });
            std.process.exit(1);
        };

        if (min != null) {
            result = @max(result, min.?);
        }

        if (max != null) {
            result = @min(result, max.?);
        }

        return result;
    }

    fn parseEnum(self: *@This(), comptime T: type, printer: *Printer, args: [][:0]u8, i: usize, flag: Flag) !T {
        if (i + 1 >= args.len) {
            try printer.printf("Missing argument for {s} ({s})\n", .{ flag.flag_short, flag.name });
            std.process.exit(1);
        }

        const value = args[i + 1];
        if (std.mem.eql(u8, value, "help")) {
            try self.printEnumOptionsWithTitle(T, flag.name, printer);
            std.process.exit(0);
        }

        return std.meta.stringToEnum(T, value) orelse {
            try printer.printf("Invalid {s}: {s}\n", .{ flag.name, value });
            try self.printEnumOptions(T, printer);
            std.process.exit(1);
        };
    }

    fn printEnumOptions(self: *@This(), comptime T: type, printer: *Printer) !void {
        try self.printEnumOptionsWithTitle(T, "Available", printer);
    }

    fn printEnumOptionsWithTitle(_: *@This(), comptime T: type, title: []const u8, printer: *Printer) !void {
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
    return Configuration.init(allocator, printer, args);
}
