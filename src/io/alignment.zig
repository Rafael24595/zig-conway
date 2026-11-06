const std = @import("std");

const RuntimeState = @import("terminal_kit").runtime_state.RuntimeState;

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
pub fn calculate_padding(
    config: *const Configuration,
    state: *RuntimeState,
) Padding {
    var padding = Padding{};

    if (state.show_debug()) {
        padding.upper += 4;

        if (config.inheritance) {
            padding.upper += 1;
        }
    }

    if (state.show_controls()) {
        padding.lower += 1;
    }

    return padding;
}

test "calculate_padding returns zero when all options are disabled" {
    const config = Configuration{
        .inheritance = false,
    };

    var state = RuntimeState{
        .debug = .init(false),
        .controls = .init(false),
    };

    const padding = calculate_padding(&config, &state);

    try std.testing.expectEqual(0, padding.upper + padding.lower);
}

test "calculate_padding reserves space for debug output" {
    const config = Configuration{
        .inheritance = false,
    };

    var state = RuntimeState{
        .debug = .init(true),
        .controls = .init(false),
    };

    const padding = calculate_padding(&config, &state);

    try std.testing.expectEqual(4, padding.upper);
    try std.testing.expectEqual(0, padding.lower);
}

test "calculate_padding reserves space for inheritance information" {
    const config = Configuration{
        .inheritance = true,
    };

    var state = RuntimeState{
        .debug = .init(true),
        .controls = .init(false),
    };

    const padding = calculate_padding(&config, &state);

    try std.testing.expectEqual(5, padding.upper);
    try std.testing.expectEqual(0, padding.lower);
}

test "calculate_padding reserves space for debug output and controls" {
    const config = Configuration{
        .inheritance = true,
    };

    var state = RuntimeState{
        .debug = .init(true),
        .controls = .init(true),
    };

    const padding = calculate_padding(&config, &state);

    try std.testing.expectEqual(5, padding.upper);
    try std.testing.expectEqual(2, padding.lower);
}
