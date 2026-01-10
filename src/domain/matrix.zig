const std = @import("std");

const MiniLCG = @import("../commons/mini_lcg.zig").MiniLCG;
const helper = @import("helper.zig");

pub const Matrix = struct {
    allocator: *std.mem.Allocator,

    lcg: *MiniLCG,
    alive_probability: f32,

    cur_gen: i16 = 0,
    mut_gen: i16 = 0,

    matrix_current: ?[][]bool = null,
    matrix_next: ?[][]bool = null,

    population: usize = 0,

    pub fn init(allocator: *std.mem.Allocator, lcg: *MiniLCG, alive: f32, mut_gen: i16) Matrix {
        return Matrix{
            .allocator = allocator,
            .lcg = lcg,
            .alive_probability = alive,
            .mut_gen = mut_gen,
            .matrix_current = null,
            .matrix_next = null,
        };
    }

    pub fn build(self: *@This(), cols: usize, rows: usize) !void {
        self.matrix_current = try helper.defineMatrix(self.allocator, cols, rows);
        self.matrix_next = try helper.defineMatrix(self.allocator, cols, rows);

        self.population = 0;

        const matrix_current = self.matrix_current.?;
        for (0..rows) |y| {
            for (0..cols) |x| {
                const alive = self.lcg.float() < self.alive_probability;
                if (alive) {
                    self.population += 1;
                }

                matrix_current[y][x] = alive;
            }
        }
    }

    pub fn matrix(self: *@This()) ?[][]bool {
        return self.matrix_current;
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
                for (min_y..max_y + 1) |cy| {
                    for (min_x..max_x + 1) |cx| {
                        if (cy == y and cx == x) {
                            continue;
                        }

                        if (current_matrix[cy][cx]) {
                            count += 1;
                        }
                    }
                }

                var alive = false;
                if (!cell) {
                    alive = count == 3;
                } else {
                    alive = count == 2 or count == 3;
                }

                next_matrix[y][x] = alive;

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

        const rows = matrix_current.len;
        const cols = matrix_current[0].len;

        const cells: f32 = @floatFromInt(rows * cols);
        const mutation_count: usize = @intFromFloat(cells * 0.001);

        for (0..@max(1, mutation_count)) |_| {
            const y = self.lcg.randInRange(0, rows - 1);
            const x = self.lcg.randInRange(0, cols - 1);
            matrix_current[y][x] = !matrix_current[y][x];
        }

        self.cur_gen = 0;
    }

    pub fn free(self: *@This()) void {
        if (self.matrix_current != null) {
            helper.freeMatrix(self.allocator, self.matrix_current.?);
            self.matrix_current = null;
        }

        if (self.matrix_next != null) {
            helper.freeMatrix(self.allocator, self.matrix_next.?);
            self.matrix_next = null;
        }
    }
};
