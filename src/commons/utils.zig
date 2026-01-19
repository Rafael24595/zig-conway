const std = @import("std");

const Printer = @import("../io/printer.zig").Printer;

pub const TimeUnit = struct {
    label: []const u8,
    time: i64,
};

pub const Millisecond: TimeUnit = .{ .label = "ms", .time = 1 };
pub const Second: TimeUnit = .{ .label = "s", .time = 1000 };
pub const Minute: TimeUnit = .{ .label = "m", .time = Second.time * 60 };
pub const Hour: TimeUnit = .{ .label = "h", .time = Minute.time * 60 };
pub const Day: TimeUnit = .{ .label = "d", .time = Hour.time * 24 };
pub const Year: TimeUnit = .{ .label = "y", .time = Day.time * 365 };

const TimeUnits: [6]TimeUnit = .{ Year, Day, Hour, Minute, Second, Millisecond };

pub fn millisecondsToTime(alloc: std.mem.Allocator, ms: i64, limit: ?TimeUnit) ![]const u8 {
    var buffer = try std.ArrayList(u8).initCapacity(alloc, 0);
    defer buffer.deinit(alloc);

    var fix_ms = ms;
    for (TimeUnits) |unit| {
        if (limit != null and std.mem.eql(u8, unit.label, limit.?.label)) {
            break;
        }

        const amount = @divFloor(fix_ms, unit.time);
        if (amount > 0 or buffer.capacity > 0 or std.mem.eql(u8, unit.label, "ms")) {
            const uAmount: usize = @intCast(amount);

            const time = if (std.mem.eql(u8, unit.label, "ms"))
                try std.fmt.allocPrint(alloc, "{d:0<3}{s}", .{ uAmount, unit.label })
            else
                try std.fmt.allocPrint(alloc, "{d:0<1}{s}", .{ uAmount, unit.label });

            defer alloc.free(time);

            try buffer.appendSlice(alloc, time);
        }

        fix_ms = @mod(fix_ms, unit.time);
    }

    return try std.fmt.allocPrint(alloc, "{s}", .{buffer.items});
}

pub const TypeFormatter = union(enum) {
    none,
    str: []const u8,
    bool: bool,
    int: i64,
    float: f64,

    pub fn format(self: TypeFormatter, printer: *Printer) ![]u8 {
        return switch (self) {
            .none => "",
            .str => |s| printer.format("{s}", .{s}),
            .bool => |b| printer.format("{s}", .{if (b) "true" else "false"}),
            .int => |i| printer.format("{d}", .{i}),
            .float => |f| printer.format("{d:.2}", .{f}),
        };
    }
};
