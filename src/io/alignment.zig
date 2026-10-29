const std = @import("std");

const Configuration = @import("../configuration/configuration.zig").Configuration;

pub const Padding = struct {
    upper: usize = 0,
    lower: usize = 0,
};

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
