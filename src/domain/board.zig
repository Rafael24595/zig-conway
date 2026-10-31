const std = @import("std");

/// Represents a point on the board with x and y coordinates.
pub const Point = struct {
    /// The y-coordinate of the point.
    y: usize,
    /// The x-coordinate of the point.
    x: usize,
};

/// Represents the viewport of the board, defining its position and dimensions.
pub const BoardViewport = struct {
    /// The y-coordinate of the top-left corner of the viewport in terminal coordinates.
    y: usize = 0,
    /// The x-coordinate of the top-left corner of the viewport in terminal coordinates.
    x: usize = 0,

    /// The number of columns in the viewport.
    cols: usize,
    /// The number of rows in the viewport.
    rows: usize,

    /// Translates terminal coordinates to board coordinates.
    pub fn to_board(
        self: @This(),
        terminal_y: usize,
        terminal_x: usize,
    ) ?Point {
        if (terminal_y == 0 or terminal_x == 0) {
            return null;
        }

        const y = terminal_y - 1;
        const x = terminal_x - 1;

        if (y < self.y or x < self.x) {
            return null;
        }

        const board_y = y - self.y;
        const board_x = x - self.x;

        if (board_y >= self.rows or board_x >= self.cols) {
            return null;
        }

        return .{
            .y = board_y,
            .x = board_x,
        };
    }
};

test "to_board returns null when terminal coordinates are zero" {
    const viewport = BoardViewport{
        .y = 0,
        .x = 0,
        .cols = 10,
        .rows = 10,
    };

    try std.testing.expectEqual(
        null,
        viewport.to_board(0, 5),
    );

    try std.testing.expectEqual(
        null,
        viewport.to_board(5, 0),
    );

    try std.testing.expectEqual(
        null,
        viewport.to_board(0, 0),
    );
}

test "to_board returns null when terminal coordinates are outside viewport boundaries (too small)" {
    const viewport = BoardViewport{
        .y = 5,
        .x = 5,
        .cols = 10,
        .rows = 10,
    };

    try std.testing.expectEqual(
        null,
        viewport.to_board(6, 5),
    );

    try std.testing.expectEqual(
        null,
        viewport.to_board(5, 6),
    );
}

test "to_board returns null when terminal coordinates exceed viewport dimensions" {
    const viewport = BoardViewport{
        .y = 2,
        .x = 2,
        .cols = 5,
        .rows = 5,
    };

    try std.testing.expectEqual(
        null,
        viewport.to_board(3, 9),
    );

    try std.testing.expectEqual(
        null,
        viewport.to_board(9, 3),
    );
}

test "to_board correctly translates valid terminal coordinates to board points" {
    const viewport = BoardViewport{
        .y = 3,
        .x = 2,
        .cols = 10,
        .rows = 10,
    };

    const result = viewport.to_board(6, 5);

    try std.testing.expect(result != null);

    try std.testing.expectEqual(
        Point{
            .y = 2,
            .x = 2,
        },
        result.?,
    );
}

test "to_board handles edge case at the exact top-left origin of the viewport" {
    const viewport = BoardViewport{
        .x = 5,
        .y = 5,
        .cols = 10,
        .rows = 10,
    };

    const result = viewport.to_board(6, 6);

    try std.testing.expect(result != null);

    try std.testing.expectEqual(
        Point{
            .y = 0,
            .x = 0,
        },
        result.?,
    );
}
