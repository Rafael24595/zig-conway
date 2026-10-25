const kit_formatter = @import("terminal_kit").formatter;

/// Defines the supported terminal color formats.
pub const FormatterCode = enum {
    /// Uses the 256-color ANSI palette.
    ansi,
    /// Uses 24-bit RGB ANSI escape sequences.
    rgb,
};

pub fn matrix_unfo() kit_formatter.FormatterMatrixUnion {
    return .{ .unfo = .{} };
}

pub fn matrix_union_of(f: FormatterCode) kit_formatter.FormatterMatrixUnion {
    return switch (f) {
        FormatterCode.ansi => .{ .ansi = .{} },
        FormatterCode.rgb => .{ .rgb = .{} },
    };
}

pub fn cell_unfo() kit_formatter.FormatterCellUnion {
    return .{ .unfo = .{} };
}

pub fn cell_union_of(f: FormatterCode) kit_formatter.FormatterCellUnion {
    return switch (f) {
        FormatterCode.ansi => .{ .ansi = .{} },
        FormatterCode.rgb => .{ .rgb = .{} },
    };
}
