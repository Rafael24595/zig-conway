const std = @import("std");
const builtin = @import("builtin");

const build = @import("build.zig.zon");

const terminal_kit = @import("terminal_kit");

const Printer = terminal_kit.printer.Printer;

const Flag = terminal_kit.configuration.Flag;
const kit_conf = terminal_kit.configuration;

const kit_formatter = terminal_kit.formatter;
const kit_color = terminal_kit.color;

const matrix = @import("../domain/matrix.zig");
const symbol = @import("../domain/symbol.zig");
const color = @import("../domain/color.zig");

const formatter = @import("../io/formatter.zig");

const frame_pause_ms: u64 = switch (builtin.os.tag) {
    .windows => 45,
    else => 50,
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

const FLAG_THEME_SYMBOL: Flag = Flag{
    .flag_short = "-ts",
    .type = "<enum>",
    .desc = "Theme symbol",
    .name = "Theme symbol",
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

const FLAG_COLOR_MODE: Flag = Flag{
    .flag_short = "-cm",
    .type = "<enum>",
    .desc = "Color mode",
    .name = "color mode",
    .aux_desc = "(use \"help\" to list available modes)",
};

/// Stores the application settings parsed from command-line arguments,
/// including rendering options, animation timing, inheritance settings and appearance preferences.
pub const Configuration = struct {
    /// Enables diagnostic information during execution.
    debug: bool = false,
    /// Enables the display of keyboard controls.
    controls: bool = false,

    /// Random seed used to initialize the matrix generation.
    /// A value of zero causes the seed to be derived from the current timestamp.
    seed: u64 = 0,

    /// Application start timestamp, in milliseconds since the Unix epoch.
    start_ms: i64 = 0,

    /// Delay between animation frames, in milliseconds.
    milliseconds: u64 = frame_pause_ms,
    // Probability of a cell being alive at initialization, expressed as a float between 0 and 1.
    alive_probability: f32 = 0.3,

    /// Maximum generation at which mutations are allowed.
    /// A negative value disables mutation.
    mutation_generation: i16 = -1,

    /// Theme used to render matrix symbols.
    symbol_mode: symbol.Theme = .classic,
    /// Color formatting mode used by the output formatters.
    color_mode: formatter.FormatterCode = .rgb,

    /// Enables inheritance mode.
    inheritance: bool = false,
    /// Theme used to determine inheritance colors.
    inheritance_mode: color.Theme = .default,
    /// Number of inheritance factions to use.
    inheritance_faction: usize = color.meta_of(.default).colors.len,

    /// Formatter configuration for the matrix output.
    formatter_matrix: kit_formatter.FormatterMatrixUnion = formatter.matrix_unfo(),
    /// Formatter configuration for individual cells.
    formatter_cell: kit_formatter.FormatterCellUnion = formatter.cell_unfo(),

    /// Default color used for rendering.
    color: kit_color.Color = .white,

    /// Parses command-line arguments and initializes the application settings.
    ///
    /// Returns an error if argument parsing or output formatting fails.
    /// Help and version requests terminate the process after printing their output.
    pub fn init(
        allocator: std.mem.Allocator,
        printer: *Printer,
        args: [][:0]u8,
    ) !@This() {
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
                config.seed = try kit_conf.parse_int(u64, printer, args, i, FLAG_SEED, null, null);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_MILLISECONDS.flag_short)) {
                config.milliseconds = try kit_conf.parse_int(u64, printer, args, i, FLAG_MILLISECONDS, null, 1000 * 3);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_ALIVE_PROBABILITY.flag_short)) {
                config.alive_probability = try kit_conf.parse_float(f32, printer, args, i, FLAG_ALIVE_PROBABILITY, 0, 1);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_MUTATION_GENERATION.flag_short)) {
                config.mutation_generation = try kit_conf.parse_int(i16, printer, args, i, FLAG_MUTATION_GENERATION, null, null);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_THEME_SYMBOL.flag_short)) {
                config.symbol_mode = try kit_conf.parse_enum(symbol.Theme, printer, args, i, FLAG_THEME_SYMBOL);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_INHERITANCE.flag_short)) {
                config.inheritance = true;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_INHERITANCE_FACTIONS.flag_short)) {
                config.inheritance = true;
                config.inheritance_faction = try kit_conf.parse_int(usize, printer, args, i, FLAG_INHERITANCE_FACTIONS, null, null);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_INHERITANCE_MODE.flag_short)) {
                config.inheritance = true;
                config.inheritance_mode = try kit_conf.parse_enum(color.Theme, printer, args, i, FLAG_INHERITANCE_MODE);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_COLOR.flag_short)) {
                config.color = try kit_conf.parse_enum(kit_color.Color, printer, args, i, FLAG_COLOR);
                i += 1;
                continue;
            }

            if (std.mem.eql(u8, arg, FLAG_COLOR_MODE.flag_short)) {
                config.color_mode = try kit_conf.parse_enum(formatter.FormatterCode, printer, args, i, FLAG_COLOR_MODE);
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

    fn init_formatters(config: *Configuration) void {
        if (config.inheritance) {
            config.formatter_matrix = formatter.matrix_unfo();
            config.formatter_cell = formatter.cell_union_of(config.color_mode);
            return;
        }

        config.formatter_matrix = formatter.matrix_union_of(config.color_mode);
        config.formatter_cell = formatter.cell_unfo();
    }

    inline fn print_help(
        allocator: std.mem.Allocator,
        printer: *Printer,
        config: Configuration,
    ) !void {
        const message = try format_flags(allocator, printer, config);
        defer allocator.free(message);
        try printer.print(message);
    }

    inline fn format_flags(
        allocator: std.mem.Allocator,
        printer: *Printer,
        config: Configuration,
    ) ![]u8 {
        var buffer = try std.ArrayList(u8).initCapacity(allocator, 0);

        try buffer.appendSlice(allocator, "\nUsage: zig-conway             [options] \n\n");

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_HELP,
            .none,
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_VERSION,
            .none,
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_DEBUG,
            .{ .bool = config.debug },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_HELP_CONTROLS,
            .{ .bool = config.controls },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_SEED,
            .{ .str = "current time in ms" },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_MILLISECONDS,
            .{ .int = @intCast(config.milliseconds) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_ALIVE_PROBABILITY,
            .{ .float = @floatCast(config.alive_probability) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_MUTATION_GENERATION,
            .{ .int = @intCast(config.mutation_generation) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_THEME_SYMBOL,
            .{ .str = @tagName(config.symbol_mode) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_INHERITANCE,
            .{ .bool = config.inheritance },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_INHERITANCE_FACTIONS,
            .{ .int = @intCast(config.inheritance_faction) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_INHERITANCE_MODE,
            .{ .str = @tagName(config.inheritance_mode) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_COLOR,
            .{ .str = @tagName(config.color) },
        ));

        try buffer.appendSlice(allocator, try kit_conf.format_flag(
            printer,
            FLAG_COLOR_MODE,
            .{ .str = @tagName(config.color_mode) },
        ));

        return buffer.items;
    }
};

/// Builds the application configuration from the current process arguments.
///
/// Allocates the argument list using `allocator` and releases it before
/// returning. Propagates errors from argument allocation and parsing.
pub fn from_args(allocator: std.mem.Allocator, printer: *Printer) !Configuration {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    return Configuration.init(allocator, printer, args);
}

test "Configuration uses the expected default values" {
    const config = Configuration{};

    try std.testing.expect(!config.debug);
    try std.testing.expect(!config.controls);
    try std.testing.expect(!config.inheritance);

    try std.testing.expectEqual(0, config.seed);
    try std.testing.expectEqual(0, config.start_ms);
    try std.testing.expectEqual(frame_pause_ms, config.milliseconds);

    try std.testing.expectEqual(0.3, config.alive_probability);
    try std.testing.expectEqual(-1, config.mutation_generation);

    try std.testing.expectEqual(symbol.Theme.classic, config.symbol_mode);
    try std.testing.expectEqual(formatter.FormatterCode.rgb, config.color_mode);

    try std.testing.expectEqual(color.Theme.default, config.inheritance_mode);
    try std.testing.expectEqual(color.meta_of(color.Theme.default).colors.len, config.inheritance_faction);

    try std.testing.expectEqual(kit_color.Color.white, config.color);

    try std.testing.expectEqual(.unfo, std.meta.activeTag(config.formatter_matrix));
    try std.testing.expectEqual(.unfo, std.meta.activeTag(config.formatter_cell));
}

test "init_formatters configures ANSI formatters in inheritance mode" {
    var config = Configuration{
        .inheritance = true,
        .color_mode = formatter.FormatterCode.ansi,
    };

    Configuration.init_formatters(&config);

    try std.testing.expectEqual(
        .unfo,
        std.meta.activeTag(config.formatter_matrix),
    );
    try std.testing.expectEqual(
        .ansi,
        std.meta.activeTag(config.formatter_cell),
    );
}

test "init_formatters configures RGB formatters in inheritance mode" {
    var config = Configuration{
        .inheritance = true,
        .color_mode = formatter.FormatterCode.rgb,
    };

    Configuration.init_formatters(&config);

    try std.testing.expectEqual(
        .unfo,
        std.meta.activeTag(config.formatter_matrix),
    );
    try std.testing.expectEqual(
        .rgb,
        std.meta.activeTag(config.formatter_cell),
    );
}

test "init_formatters configures ANSI formatters without inheritance" {
    var config = Configuration{
        .inheritance = false,
        .color_mode = formatter.FormatterCode.ansi,
    };

    Configuration.init_formatters(&config);

    try std.testing.expectEqual(
        .ansi,
        std.meta.activeTag(config.formatter_matrix),
    );
    try std.testing.expectEqual(
        .unfo,
        std.meta.activeTag(config.formatter_cell),
    );
}

test "init_formatters configures RGB formatters without inheritance" {
    var config = Configuration{
        .inheritance = false,
        .color_mode = formatter.FormatterCode.rgb,
    };

    Configuration.init_formatters(&config);

    try std.testing.expectEqual(
        .rgb,
        std.meta.activeTag(config.formatter_matrix),
    );
    try std.testing.expectEqual(
        .unfo,
        std.meta.activeTag(config.formatter_cell),
    );
}
