const std = @import("std");

const Configuration = @import("../configuration/configuration.zig").Configuration;

/// Represents the padding required for rendering the matrix, including
/// space for debug output, inheritance information, and control instructions.
pub const Padding = struct {
    /// Number of lines to reserve at the top of the terminal for debug output and inheritance information.
    upper: usize = 0,
    /// Number of lines to reserve at the bottom of the terminal for control instructions.
    lower: usize = 0,
};

/// Calculates the required padding based on the provided configuration.
///
/// The padding is determined by the following rules:
/// - If debug output is enabled, reserve 4 lines at the top.
/// - If inheritance information is enabled, reserve an additional line at the top.
/// - If control instructions are enabled, reserve 1 line at the bottom.
pub fn calculate_padding(config: *const Configuration) Padding {
    var padding = Padding{};

    if (config.debug) {
        padding.upper += 4;

        if (config.inheritance) {
            padding.upper += 1;
        }
    }

    if (config.controls) {
        padding.lower += 1;
    }

    return padding;
}

test "calculate_padding returns zero when all options are disabled" {
    const config = Configuration{
        .debug = false,
        .inheritance = false,
        .controls = false,
    };

    const padding = calculate_padding(&config);

    try std.testing.expectEqual(0, padding.upper + padding.lower);
}

test "calculate_padding reserves space for debug output" {
    const config = Configuration{
        .debug = true,
        .inheritance = false,
        .controls = false,
    };

    const padding = calculate_padding(&config);

    try std.testing.expectEqual(4, padding.upper);
    try std.testing.expectEqual(0, padding.lower);
}

test "calculate_padding reserves space for inheritance information" {
    const config = Configuration{
        .debug = true,
        .inheritance = true,
        .controls = false,
    };

    const padding = calculate_padding(&config);

    try std.testing.expectEqual(5, padding.upper);
    try std.testing.expectEqual(0, padding.lower);
}

test "calculate_padding reserves space for debug output and controls" {
    const config = Configuration{
        .debug = true,
        .inheritance = true,
        .controls = true,
    };

    const padding = calculate_padding(&config);

    try std.testing.expectEqual(5, padding.upper);
    try std.testing.expectEqual(1, padding.lower);
}
