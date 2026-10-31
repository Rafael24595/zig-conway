const std = @import("std");

const EMPTY: u64 = std.math.maxInt(u64);

/// Represents a coordinate on the game board with y and x values.
pub const Coord = struct {
    /// The y-coordinate of the point.
    y: usize,
    /// The x-coordinate of the point.
    x: usize,
};

/// Represents the state of the game, including the last requested coordinate.
pub const GameState = struct {
    /// The last requested coordinate, packed into a single u64 value.
    point: std.atomic.Value(u64) = .init(EMPTY),

    /// Requests a coordinate to be processed by the game state.
    pub fn request_coord(self: *@This(), y: u32, x: u32) void {
        const packed_y: u64 = @as(u64, y) << 32;
        const packed_x: u64 = @as(u64, x);
        self.point.store(packed_y | packed_x, .release);
    }

    /// Consumes the last requested coordinate, returning it if available.
    /// If no coordinate is available, returns null.
    pub fn consume_coord(self: *@This()) ?Coord {
        const packed_coord = self.point.swap(EMPTY, .acq_rel);

        if (packed_coord == EMPTY) {
            return null;
        }

        const y: usize = @intCast(packed_coord >> 32);

        const x_u32: u32 = @truncate(packed_coord);
        const x: usize = @intCast(x_u32);

        return .{
            .y = y,
            .x = x,
        };
    }
};

test "GameState initializes to empty and consume_coord returns null" {
    var state = GameState{};
    try std.testing.expectEqual(null, state.consume_coord());
}

test "request_coord and consume_coord roundtrip correctly" {
    var state = GameState{};

    state.request_coord(10, 20);

    const coord = state.consume_coord();

    try std.testing.expect(coord != null);

    try std.testing.expectEqual(10, coord.?.y);
    try std.testing.expectEqual(20, coord.?.x);

    try std.testing.expectEqual(null, state.consume_coord());
}

test "request_coord overwrites previous unconsumed coordinate" {
    var state = GameState{};

    state.request_coord(5, 5);
    state.request_coord(42, 99);

    const coord = state.consume_coord();

    try std.testing.expect(coord != null);

    try std.testing.expectEqual(42, coord.?.y);
    try std.testing.expectEqual(99, coord.?.x);
}

test "consume_coord leaves state empty allowing subsequent requests" {
    var state = GameState{};

    state.request_coord(1, 2);

    const c1 = state.consume_coord();

    try std.testing.expectEqual(1, c1.?.y);
    try std.testing.expectEqual(2, c1.?.x);

    try std.testing.expectEqual(null, state.consume_coord());

    state.request_coord(3, 4);

    const c2 = state.consume_coord();

    try std.testing.expectEqual(3, c2.?.y);
    try std.testing.expectEqual(4, c2.?.x);
}
