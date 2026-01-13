const std = @import("std");
const color = @import("../domain/color.zig");

pub const FormatterCode = enum {
    ANSI,
    RGB,
};

pub const FormatterMatrixUnion = union(enum) {
    ansi: FormatterMatrix("\x1b[38;5;{d}m{s}", "\x1b[0m", formatANSI),
    rgb: FormatterMatrix("\x1b[38;2;{d};{d};{d}m{s}", "\x1b[0m", formatRgb),
    unfo: FormatterMatrix("", "\x1b[0m", formatUnformatted),

    pub fn fmt_bytes(
        self: @This(),
    ) usize {
        return switch (self) {
            .ansi => |f| f.fmt_bytes(),
            .rgb => |f| f.fmt_bytes(),
            .unfo => |f| f.fmt_bytes(),
        };
    }

    pub fn prefix(
        self: @This(),
    ) []const u8 {
        return switch (self) {
            .ansi => |f| f.prefix(),
            .rgb => |f| f.prefix(),
            .unfo => |f| f.prefix(),
        };
    }

    pub fn sufix(
        self: @This(),
    ) []const u8 {
        return switch (self) {
            .ansi => |f| f.sufix(),
            .rgb => |f| f.sufix(),
            .unfo => |f| f.sufix(),
        };
    }

    pub fn format_prefix(
        self: @This(),
        buf: []u8,
        r: u8,
        g: u8,
        b: u8,
    ) []const u8 {
        return switch (self) {
            .ansi => |f| f.format_prefix(buf, r, g, b),
            .rgb => |f| f.format_prefix(buf, r, g, b),
            .unfo => |f| f.format_prefix(buf, r, g, b),
        };
    }
};

pub const FormatterCellUnion = union(enum) {
    ansi: FormatterCell("\x1b[38;5;{d}m{s}", formatANSI),
    rgb: FormatterCell("\x1b[38;2;{d};{d};{d}m{s}", formatRgb),
    unfo: FormatterCell("\x1b[38;2;{d};{d};{d}m{s}", formatUnformatted),

    pub fn fmt_bytes(
        self: @This(),
    ) usize {
        return switch (self) {
            .ansi => |f| f.fmt_bytes(),
            .rgb => |f| f.fmt_bytes(),
            .unfo => |f| f.fmt_bytes(),
        };
    }

    pub fn format(
        self: @This(),
        buf: []u8,
        r: u8,
        g: u8,
        b: u8,
        c: []const u8,
    ) ![]const u8 {
        return switch (self) {
            .ansi => |f| f.format(buf, r, g, b, c),
            .rgb => |f| f.format(buf, r, g, b, c),
            .unfo => |f| f.format(buf, r, g, b, c),
        };
    }
};

fn FormatterMatrix(
    comptime prefix_fmt: []const u8,
    comptime sufix_fmt: []const u8,
    comptime adapter: fn (
        buffer: []u8,
        comptime fmt: []const u8,
        r: u8,
        g: u8,
        b: u8,
        c: []const u8,
    ) []const u8,
) type {
    return struct {
        pub fn fmt_bytes(_: @This()) usize {
            return prefix_fmt.len + sufix_fmt.len;
        }

        pub fn prefix(_: @This()) []const u8 {
            return prefix_fmt;
        }

        pub fn sufix(_: @This()) []const u8 {
            return sufix_fmt;
        }

        pub fn format_prefix(
            _: @This(),
            buf: []u8,
            r: u8,
            g: u8,
            b: u8
        ) []const u8 {
            return adapter(buf, prefix_fmt, r, g, b, "");
        }
    };
}

fn FormatterCell(
    comptime char_fmt: []const u8,
    comptime adapter: fn (
        buffer: []u8,
        comptime fmt: []const u8,
        r: u8,
        g: u8,
        b: u8,
        c: []const u8,
    ) []const u8,
) type {
    return struct {
        pub fn fmt_bytes(_: @This()) usize {
            return char_fmt.len;
        }

        pub fn format(
            _: @This(),
            buf: []u8,
            r: u8,
            g: u8,
            b: u8,
            c: []const u8,
        ) []const u8 {
            return adapter(buf, char_fmt, r, g, b, c);
        }
    };
}

fn formatUnformatted(
    _: []u8,
    comptime _: []const u8,
    _: u8,
    _: u8,
    _: u8,
    c: []const u8,
) []const u8 {
    return c;
}

fn formatANSI(
    buffer: []u8,
    comptime fmt: []const u8,
    r: u8,
    g: u8,
    b: u8,
    c: []const u8,
) []const u8 {
    const a = rgbToAnsi256(r, g, b);
    return std.fmt.bufPrint(
        buffer,
        fmt,
        .{ a, c },
    ) catch unreachable;
}

fn formatRgb(
    buffer: []u8,
    comptime fmt: []const u8,
    r: u8,
    g: u8,
    b: u8,
    c: []const u8,
) []const u8 {
    return std.fmt.bufPrint(
        buffer,
        fmt,
        .{ r, g, b, c },
    ) catch unreachable;
}

fn rgbToAnsi256(r: u8, g: u8, b: u8) u8 {
    if (r == g and g == b) {
        if (r < 8) {
            return 16;
        }
        if (r > 248) {
            return 231;
        }

        const scaled_gray_offset   = (@as(u16, r) - 8) * 24;
        const gray_index: u8 = @intCast(scaled_gray_offset  / 247);

        return 232 + gray_index;
    }

    const rr = (@as(u16, r) * 5) / 255;
    const gg = (@as(u16, g) * 5) / 255;
    const bb = (@as(u16, b) * 5) / 255;

    return @intCast(16 + 36 * rr + 6 * gg + bb);
}
