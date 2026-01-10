const std = @import("std");

pub const Printer = struct {
    arena: *std.heap.ArenaAllocator,
    out: std.fs.File,

    pub fn print(self: *Printer, bytes: []const u8) !void {
        try self.out.writeAll(bytes);
    }

    pub fn printf(self: *Printer, comptime fmt: []const u8, args: anytype) !void {
        const msg = try self.format(fmt, args);
        try self.print(msg);
    }

    pub fn format(self: *Printer, comptime fmt: []const u8, args: anytype) ![]u8 {
        return try std.fmt.allocPrint(self.arena.allocator(), fmt, args);
    }

    pub fn reset(self: *Printer) void {
        _ = self.arena.reset(.free_all);
    }
};