const std = @import("std");

const MiniLCG = @import("../commons/mini_lcg.zig").MiniLCG;
const ColorManager = @import("color.zig").ColorManager;

const SearchArea = 1;

const Cell = struct {
    color: ?[3]u8,
    status: bool,
};

pub const LinearMatrix = struct {
    allocator: *std.mem.Allocator,

    lcg: *MiniLCG,
    color_manager: *ColorManager,

    alive_probability: f32,

    cur_gen: i16 = 0,
    mut_gen: i16 = 0,

    cols: usize = 0,
    rows: usize = 0,

    matrix_current: ?[]Cell = null,
    matrix_next: ?[]Cell = null,

    population: usize = 0,

    pub fn init(allocator: *std.mem.Allocator, lcg: *MiniLCG, color_manager: *ColorManager, alive: f32, mut_gen: i16) LinearMatrix {
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

        const min_y = y -| SearchArea;
        const max_y = @min(self.rows - 1, y + SearchArea);

        const min_x = x -| SearchArea;
        const max_x = @min(self.cols - 1, x + SearchArea);

        var color: ?[3]u8 = null;
        for (min_y..max_y + 1) |cy| {
            const row_start = y * self.cols;

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

    pub fn cols_len(self: *@This()) usize {
        return self.cols;
    }

    pub fn rows_len(self: *@This()) usize {
        return self.rows;
    }

    pub fn current_generation(self: *@This()) i16 {
        return self.cur_gen;
    }

    pub fn mutation_generation(self: *@This()) i16 {
        return self.mut_gen;
    }

    pub fn alive_population(self: *@This()) usize {
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
            for (0..self.cols) |x| {
                const cursor = y * self.cols + x;

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

        const min_y = y -| SearchArea;
        const max_y = @min(self.rows - 1, y + SearchArea);

        const min_x = x -| SearchArea;
        const max_x = @min(self.cols - 1, x + SearchArea);

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
                .color = self.color_manager.mix_or_select(0.3, colors),
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

    fn mutate(self: *@This()) !void {
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
            const y = self.lcg.randInRange(0, self.rows - 1);
            const x = self.lcg.randInRange(0, self.cols - 1);

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
