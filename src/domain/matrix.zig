const std = @import("std");

const MiniLCG = @import("../commons/mini_lcg.zig").MiniLCG;
const ColorManager = @import("color.zig").ColorManager;

const Cell = struct {
    color: ?[3]u8,
    status: bool,
};

pub const Matrix = struct {
    allocator: *std.mem.Allocator,

    lcg: *MiniLCG,
    color_manager: *ColorManager,

    alive_probability: f32,

    cur_gen: i16 = 0,
    mut_gen: i16 = 0,

    matrix_current: ?[][]Cell = null,
    matrix_next: ?[][]Cell = null,

    population: usize = 0,

    pub fn init(allocator: *std.mem.Allocator, lcg: *MiniLCG, color_manager: *ColorManager, alive: f32, mut_gen: i16) Matrix {
        return Matrix{
            .allocator = allocator,
            .lcg = lcg,
            .color_manager = color_manager,
            .alive_probability = alive,
            .mut_gen = mut_gen,
            .matrix_current = null,
            .matrix_next = null,
        };
    }

    pub fn build(self: *@This(), c: usize, r: usize) !void {
        self.matrix_current = try define_matrix(self.allocator, c, r);
        self.matrix_next = try define_matrix(self.allocator, c, r);

        self.population = 0;

        self.add_status();
        self.add_color();
    }

    fn add_status(self: *@This()) void {
        const matrix_current = self.matrix_current.?;
        for (matrix_current) |row| {
            for (row) |*cell| {
                const alive = self.lcg.float() < self.alive_probability;
                if (alive) {
                    self.population += 1;
                }

                cell.*.status = alive;
            }
        }
    }

    fn add_color(self: *@This()) void {
        const matrix_current = self.matrix_current.?;

        const area = 1;
        for (matrix_current, 0..) |row, y| {
            for (row, 0..) |*cell, x| {
                const min_y = y -| area;
                const max_y = @min(matrix_current.len - 1, y + area);

                const min_x = x -| area;
                const max_x = @min(row.len - 1, x + area);

                var col: ?[3]u8 = null;
                for (min_y..max_y + 1) |cy| {
                    for (min_x..max_x + 1) |cx| {
                        if (cy == y and cx == x) {
                            continue;
                        }

                        if (matrix_current[cy][cx].status and matrix_current[cy][cx].color != null) {
                            col = matrix_current[cy][cx].color;
                        }
                    }
                }

                if (col == null) {
                    col = self.color_manager.rand_color();
                }

                cell.*.color = col;
            }
        }
    }

    pub fn matrix(self: *@This()) ?[][]Cell {
        return self.matrix_current;
    }

    pub fn cols(self: *@This()) usize {
        if (self.matrix_current) |mtrx| {
            return mtrx[0].len;
        }
        return 0;
    }

    pub fn rows(self: *@This()) usize {
        if (self.matrix_current) |mtrx| {
            return mtrx.len;
        }
        return 0;
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

        const area = 1;
        for (current_matrix, 0..) |row, y| {
            for (row, 0..) |cell, x| {
                const min_y = y -| area;
                const max_y = @min(current_matrix.len - 1, y + area);

                const min_x = x -| area;
                const max_x = @min(row.len - 1, x + area);

                var count: usize = 0;
                var parents: [8]?[3]u8 = .{null} ** 8;
                for (min_y..max_y + 1) |cy| {
                    for (min_x..max_x + 1) |cx| {
                        if (cy == y and cx == x) {
                            continue;
                        }

                        if (current_matrix[cy][cx].status) {
                            parents[count] = current_matrix[cy][cx].color.?;
                            count += 1;
                        }
                    }
                }

                var alive = false;
                var color: ?[3]u8 = null;

                if (!cell.status and count == 3) {
                    var compacted: [8][3]u8 = undefined;
                    const colors = compact_parents(&parents, &compacted);

                    color = self.color_manager.mix_or_select(0.3, colors);
                    alive = true;
                }

                if (cell.status and (count == 2 or count == 3)) {
                    color = cell.color;
                    alive = true;
                }

                next_matrix[y][x].status = alive;
                next_matrix[y][x].color = color;

                if (alive) {
                    self.population += 1;
                }
            }
        }

        const tmp = self.matrix_current;

        self.matrix_current = self.matrix_next;
        self.matrix_next = tmp;
    }

    fn mutate(self: *@This()) !void {
        if (self.mut_gen < 0) {
            return;
        }

        if (self.cur_gen < self.mut_gen) {
            self.cur_gen += 1;
            return;
        }

        const matrix_current = self.matrix_current.?;

        const r = matrix_current.len;
        const c = matrix_current[0].len;

        const cells: f32 = @floatFromInt(r * c);
        const mutation_count: usize = @intFromFloat(cells * 0.001);

        for (0..@max(1, mutation_count)) |_| {
            const y = self.lcg.randInRange(0, r - 1);
            const x = self.lcg.randInRange(0, c - 1);

            const sta = !matrix_current[y][x].status;

            var col: ?[3]u8 = null;
            if (sta) {
                col = self.color_manager.rand_color();
            }

            matrix_current[y][x].status = sta;
            matrix_current[y][x].color = col;
        }

        self.cur_gen = 0;
    }

    pub fn free(self: *@This()) void {
        if (self.matrix_current != null) {
            free_matrix(self.allocator, self.matrix_current.?);
            self.matrix_current = null;
        }

        if (self.matrix_next != null) {
            free_matrix(self.allocator, self.matrix_next.?);
            self.matrix_next = null;
        }
    }
};

pub fn define_matrix(allocator: *std.mem.Allocator, cols: usize, rows: usize) ![][]Cell {
    const matrix = try allocator.alloc([]Cell, rows);

    for (0..rows) |y| {
        matrix[y] = try allocator.alloc(Cell, cols);
        for (matrix[y]) |*cell| {
            cell.*.status = false;
            cell.*.color = null;
        }
    }

    return matrix;
}

pub fn free_matrix(allocator: *std.mem.Allocator, matrix: [][]Cell) void {
    for (matrix) |row| {
        allocator.free(row);
    }

    allocator.free(matrix);

    return;
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
