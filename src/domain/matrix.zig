const std = @import("std");

const MiniLCG = @import("terminal_kit").mini_lcg.MiniLCG;

const ColorManager = @import("color.zig").ColorManager;

const SEARCH_AREA = 1;

pub const DEFAULT_DOMINANCE = 0.3;

const Cell = struct {
    color: ?[3]u8,
    status: bool,
};

pub const LinearMatrix = struct {
    allocator: std.mem.Allocator,

    lcg: *MiniLCG,
    color_manager: *ColorManager,

    alive_probability: f32,

    cur_gen: i16 = 0,
    mut_gen: i16 = 0,

    dominance: f32 = DEFAULT_DOMINANCE,

    cols: usize = 0,
    rows: usize = 0,

    matrix_current: ?[]Cell = null,
    matrix_next: ?[]Cell = null,

    population: usize = 0,

    pub fn init(
        allocator: std.mem.Allocator,
        lcg: *MiniLCG,
        color_manager: *ColorManager,
        alive: f32,
        mut_gen: i16,
    ) LinearMatrix {
        return LinearMatrix{
            .allocator = allocator,
            .lcg = lcg,
            .color_manager = color_manager,
            .alive_probability = alive,
            .mut_gen = mut_gen,
            .matrix_current = null,
            .matrix_next = null,
        };
    }

    pub fn build(self: *@This(), cols: usize, rows: usize) !void {
        self.cols = cols;
        self.rows = rows;

        self.matrix_current = try define_matrix(self.allocator, cols, rows);
        self.matrix_next = try define_matrix(self.allocator, cols, rows);

        self.population = 0;

        self.add_status();
        self.add_color();
    }

    fn add_status(self: *@This()) void {
        const mtrx = self.matrix_current.?;
        for (mtrx) |*cell| {
            const alive = self.lcg.float() < self.alive_probability;
            if (alive) {
                self.population += 1;
            }
            cell.*.status = alive;
        }
    }

    fn add_color(self: *@This()) void {
        const mtrx = self.matrix_current.?;
        for (0..self.rows) |y| {
            const row_start = y * self.cols;

            for (0..self.cols) |x| {
                const cursor = row_start + x;
                const color = self.find_color(y, x);
                mtrx[cursor].color = color;
            }
        }
    }

    inline fn find_color(self: *@This(), y: usize, x: usize) [3]u8 {
        const mtrx = self.matrix_current.?;

        const min_y = y -| SEARCH_AREA;
        const max_y = @min(self.rows - 1, y + SEARCH_AREA);

        const min_x = x -| SEARCH_AREA;
        const max_x = @min(self.cols - 1, x + SEARCH_AREA);

        var color: ?[3]u8 = null;
        for (min_y..max_y + 1) |cy| {
            const row_start = cy * self.cols;

            for (min_x..max_x + 1) |cx| {
                if (cy == y and cx == x) {
                    continue;
                }

                const cursor = row_start + cx;
                const cell = mtrx[cursor];
                if (cell.status and cell.color != null) {
                    color = cell.color;
                }
            }
        }

        if (color != null) {
            return color.?;
        }

        return self.color_manager.rand_color();
    }

    pub fn vector(self: *@This()) ?[]Cell {
        return self.matrix_current;
    }

    pub fn cols_len(self: @This()) usize {
        return self.cols;
    }

    pub fn rows_len(self: @This()) usize {
        return self.rows;
    }

    pub fn current_generation(self: @This()) i16 {
        return self.cur_gen;
    }

    pub fn mutation_generation(self: @This()) i16 {
        return self.mut_gen;
    }

    pub fn alive_population(self: @This()) usize {
        return self.population;
    }

    pub fn next(self: *@This()) !void {
        if (self.matrix_current == null or self.matrix_next == null) {
            return;
        }

        if (self.matrix_current.?.len == 0) {
            return;
        }

        try self.mutate();

        const current_matrix = self.matrix_current.?;
        const next_matrix = self.matrix_next.?;

        self.population = 0;

        for (0..self.rows) |y| {
            const row_start = y * self.cols;

            for (0..self.cols) |x| {
                const cursor = row_start + x;

                const data = self.count_parents(y, x);

                const cell = current_matrix[cursor];
                const state = self.calculate_state(
                    cell,
                    data.count,
                    data.parents,
                );

                next_matrix[cursor].status = state.alive;
                next_matrix[cursor].color = state.color;

                if (state.alive) {
                    self.population += 1;
                }
            }
        }

        const tmp = self.matrix_current;

        self.matrix_current = self.matrix_next;
        self.matrix_next = tmp;
    }

    inline fn count_parents(self: *@This(), y: usize, x: usize) struct {
        count: usize,
        parents: [8]?[3]u8,
    } {
        const mtrx = self.matrix_current.?;

        const min_y = y -| SEARCH_AREA;
        const max_y = @min(self.rows - 1, y + SEARCH_AREA);

        const min_x = x -| SEARCH_AREA;
        const max_x = @min(self.cols - 1, x + SEARCH_AREA);

        var count: usize = 0;
        var parents: [8]?[3]u8 = .{null} ** 8;
        for (min_y..max_y + 1) |cy| {
            const row_start = cy * self.cols;

            for (min_x..max_x + 1) |cx| {
                if (cy == y and cx == x) {
                    continue;
                }

                const cursor = row_start + cx;
                const cell = mtrx[cursor];
                if (cell.status) {
                    std.debug.assert(cell.color != null);

                    parents[count] = cell.color.?;
                    count += 1;
                }
            }
        }

        return .{
            .count = count,
            .parents = parents,
        };
    }

    inline fn calculate_state(self: *@This(), cell: Cell, count: usize, parents: [8]?[3]u8) struct {
        alive: bool,
        color: ?[3]u8,
    } {
        if (!cell.status and count == 3) {
            var compacted: [8][3]u8 = undefined;
            const colors = compact_parents(&parents, &compacted);

            return .{
                .alive = true,
                .color = self.color_manager.mix_or_select(self.dominance, colors),
            };
        }

        if (cell.status and (count == 2 or count == 3)) {
            return .{
                .alive = true,
                .color = cell.color,
            };
        }

        return .{
            .alive = false,
            .color = null,
        };
    }

    inline fn mutate(self: *@This()) !void {
        if (self.mut_gen < 0) {
            return;
        }

        if (self.cur_gen < self.mut_gen) {
            self.cur_gen += 1;
            return;
        }

        const mtrx = self.matrix_current.?;

        const cells: f32 = @floatFromInt(self.rows * self.cols);
        const mutation_count: usize = @intFromFloat(cells * 0.001);

        for (0..@max(1, mutation_count)) |_| {
            const y = self.lcg.rand_in_range(0, self.rows - 1);
            const x = self.lcg.rand_in_range(0, self.cols - 1);

            const cursor = y * self.cols + x;

            const sta = !mtrx[cursor].status;

            var col: ?[3]u8 = null;
            if (sta) {
                col = self.color_manager.rand_color();
            }

            mtrx[cursor].status = sta;
            mtrx[cursor].color = col;
        }

        self.cur_gen = 0;
    }

    pub fn free(self: *@This()) void {
        if (self.matrix_current != null) {
            self.allocator.free(self.matrix_current.?);
            self.matrix_current = null;
        }

        if (self.matrix_next != null) {
            self.allocator.free(self.matrix_next.?);
            self.matrix_next = null;
        }
    }
};

pub fn define_matrix(allocator: *std.mem.Allocator, cols: usize, rows: usize) ![]Cell {
    const mtrx = try allocator.alloc(Cell, cols * rows);

    @memset(mtrx, Cell{
        .status = false,
        .color = null,
    });

    return mtrx;
}

fn compact_parents(parents: *const [8]?[3]u8, buffer: *[8][3]u8) []const [3]u8 {
    var count: usize = 0;

    for (parents.*) |p| {
        if (p) |color| {
            buffer[count] = color;
            count += 1;
        }
    }

    return buffer[0..count];
}

fn create_test_matrix(
    allocator: std.mem.Allocator,
    lcg: *MiniLCG,
    color_manager: *mod_color.ColorManager,
) !LinearMatrix {
    var matrix = LinearMatrix.init(
        allocator,
        lcg,
        color_manager,
        0.0,
        -1,
    );

    try matrix.build(3, 3);
    return matrix;
}

test "define_matrix initializes all cells as dead and colorless" {
    var allocator = std.testing.allocator;

    const result = try define_matrix(allocator, 2, 3);
    defer allocator.free(result);

    try std.testing.expectEqual(6, result.len);

    for (result) |cell| {
        try std.testing.expect(!cell.status);
        try std.testing.expect(cell.color == null);
    }
}

test "define_matrix supports an empty matrix" {
    var allocator = std.testing.allocator;

    const result = try define_matrix(allocator, 0, 0);
    defer allocator.free(result);

    try std.testing.expectEqual(0, result.len);
}

test "compact_parents removes empty entries and preserves color order" {
    const parents = [8]?[3]u8{
        .{ 255, 0, 0 },
        null,
        .{ 0, 255, 0 },
        null,
        .{ 0, 0, 255 },
        null,
        null,
        null,
    };

    var buffer: [8][3]u8 = undefined;
    const result = compact_parents(&parents, &buffer);

    try std.testing.expectEqual(3, result.len);
    try std.testing.expectEqual([3]u8{ 255, 0, 0 }, result[0]);
    try std.testing.expectEqual([3]u8{ 0, 255, 0 }, result[1]);
    try std.testing.expectEqual([3]u8{ 0, 0, 255 }, result[2]);
}

test "compact_parents returns an empty slice when there are no parents" {
    const parents = [_]?([3]u8){null} ** 8;

    var buffer: [8][3]u8 = undefined;
    const result = compact_parents(&parents, &buffer);

    try std.testing.expectEqual(0, result.len);
}

test "next births a dead cell with three living neighbors" {
    const allocator = std.testing.allocator;
    var lcg = MiniLCG.init(1);

    const meta = mod_color.meta_of(mod_color.Theme.default);

    var color_manager = try mod_color.ColorManager.init(
        allocator,
        &lcg,
        mod_color.Theme.default,
        meta.colors.len,
    );

    defer color_manager.free();

    var matrix = try create_test_matrix(
        allocator,
        &lcg,
        &color_manager,
    );

    defer matrix.free();

    const cells = matrix.matrix_current.?;
    const living_color = [3]u8{ 255, 0, 0 };

    cells[0] = .{ .status = true, .color = living_color };
    cells[1] = .{ .status = true, .color = living_color };
    cells[2] = .{ .status = true, .color = living_color };

    try matrix.next();

    const next_cells = matrix.matrix_current.?;
    try std.testing.expect(next_cells[4].status);
    try std.testing.expect(next_cells[4].color != null);
    try std.testing.expectEqual(2, matrix.alive_population());
}

test "next preserves a living cell with two living neighbors" {
    const allocator = std.testing.allocator;
    var lcg = MiniLCG.init(2);

    const meta = mod_color.meta_of(mod_color.Theme.default);

    var color_manager = try mod_color.ColorManager.init(
        allocator,
        &lcg,
        mod_color.Theme.default,
        meta.colors.len,
    );

    defer color_manager.free();

    var matrix = try create_test_matrix(
        allocator,
        &lcg,
        &color_manager,
    );

    defer matrix.free();

    const cells = matrix.matrix_current.?;
    const living_color = [3]u8{ 255, 0, 0 };

    cells[4] = .{ .status = true, .color = living_color };
    cells[1] = .{ .status = true, .color = living_color };
    cells[3] = .{ .status = true, .color = living_color };
    matrix.population = 3;

    try matrix.next();

    const next_cells = matrix.matrix_current.?;

    try std.testing.expect(next_cells[4].status);
    try std.testing.expectEqual(living_color, next_cells[4].color.?);
    try std.testing.expectEqual(4, matrix.alive_population());
}

test "next kills an isolated living cell" {
    const allocator = std.testing.allocator;
    var lcg = MiniLCG.init(3);

    const meta = mod_color.meta_of(mod_color.Theme.default);

    var color_manager = try mod_color.ColorManager.init(
        allocator,
        &lcg,
        mod_color.Theme.default,
        meta.colors.len,
    );

    defer color_manager.free();

    var matrix = try create_test_matrix(
        allocator,
        &lcg,
        &color_manager,
    );
    defer matrix.free();

    const cells = matrix.matrix_current.?;
    cells[4] = .{
        .status = true,
        .color = .{ 255, 0, 0 },
    };
    matrix.population = 1;

    try matrix.next();

    const next_cells = matrix.matrix_current.?;

    try std.testing.expect(!next_cells[4].status);
    try std.testing.expect(next_cells[4].color == null);
    try std.testing.expectEqual(0, matrix.alive_population());
}

test "next kills a living cell with four living neighbors" {
    const allocator = std.testing.allocator;
    var lcg = MiniLCG.init(4);

    const meta = mod_color.meta_of(mod_color.Theme.default);

    var color_manager = try mod_color.ColorManager.init(
        allocator,
        &lcg,
        mod_color.Theme.default,
        meta.colors.len,
    );

    defer color_manager.free();

    var matrix = try create_test_matrix(
        allocator,
        &lcg,
        &color_manager,
    );

    defer matrix.free();

    const cells = matrix.matrix_current.?;
    const living_color = [3]u8{ 255, 0, 0 };

    cells[4] = .{ .status = true, .color = living_color };
    cells[1] = .{ .status = true, .color = living_color };
    cells[3] = .{ .status = true, .color = living_color };
    cells[5] = .{ .status = true, .color = living_color };
    cells[7] = .{ .status = true, .color = living_color };
    matrix.population = 5;

    try matrix.next();

    const next_cells = matrix.matrix_current.?;

    try std.testing.expect(!next_cells[4].status);
    try std.testing.expect(next_cells[4].color == null);
    try std.testing.expectEqual(8, matrix.alive_population());
}
