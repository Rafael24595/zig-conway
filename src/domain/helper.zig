const std = @import("std");

pub fn defineMatrix(allocator: *std.mem.Allocator, cols: usize, rows: usize) ![][]bool {
    const matrix = try allocator.alloc([]bool, rows);

    for (0..rows) |y| {
        matrix[y] = try allocator.alloc(bool, cols);
        @memset(matrix[y], false);
    }

    return matrix;
}

pub fn freeMatrix(allocator: *std.mem.Allocator, matrix: [][]bool) void {
    for (matrix) |row| {
        allocator.free(row);
    }

    allocator.free(matrix);

    return;
}
