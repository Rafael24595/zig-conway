const std = @import("std");
const builtin = @import("builtin");

pub const HIDE_CURSOR = "\x1b[?25l";
pub const SHOW_CURSOR = "\x1b[?25h";

pub const CLEAN_CONSOLE = "\x1B[2J\x1B[H";
pub const RESET_CURSOR = "\x1b[H";

pub const COLOR_WRAPPER_BYTES = 25;
pub const COLOR_WRAPPER_PREFIX = "\x1b[38;2;{d};{d};{d}m";
pub const COLOR_WRAPPER_SUFIX = "\x1b[0m";

pub const WinSize = struct {
    cols: usize,
    rows: usize,
};

pub fn enableANSI() !void {
    if (builtin.os.tag == .windows) {
        const oHandle = std.os.windows.kernel32.GetStdHandle(std.os.windows.STD_OUTPUT_HANDLE);
        if (oHandle == null) {
            return;
        }

        const handle = oHandle.?;
        var mode: u32 = 0;
        if (std.os.windows.kernel32.GetConsoleMode(handle, &mode) == 0) {
            return;
        }

        _ = std.os.windows.kernel32.SetConsoleMode(handle, mode | 0x0004);
    }
}

pub fn enableUTF8() !void {
    if (builtin.os.tag == .windows) {
        _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);
    }
}

pub fn winSize() !WinSize {
    return switch (builtin.os.tag) {
        .linux => linuxWinSize(),
        .windows => windowsWinSize(),
        else => WinSize{ .cols = 0, .rows = 0 },
    };
}

pub fn linuxWinSize() !WinSize {
    var ws: std.posix.winsize = undefined;

    const err = std.os.linux.ioctl(
        std.posix.STDOUT_FILENO,
        std.os.linux.T.IOCGWINSZ,
        @intFromPtr(&ws),
    );

    if (err == -1) {
        return error.IoctlFailed;
    }

    const cols: usize = @intCast(ws.col);
    const rows: usize = @intCast(ws.row);

    return WinSize{ .cols = cols, .rows = rows };
}

pub fn windowsWinSize() !WinSize {
    var info: std.os.windows.CONSOLE_SCREEN_BUFFER_INFO = undefined;

    const hConsole = std.os.windows.kernel32.GetStdHandle(std.os.windows.STD_OUTPUT_HANDLE) orelse return error.NoStdout;

    const ok = std.os.windows.kernel32.GetConsoleScreenBufferInfo(hConsole, &info);
    if (ok == 0) return error.WinAPI;

    const rows: usize = @intCast(info.srWindow.Bottom - info.srWindow.Top + 1);
    const cols: usize = @intCast(info.srWindow.Right - info.srWindow.Left + 1);

    return WinSize{ .cols = cols, .rows = rows };
}
