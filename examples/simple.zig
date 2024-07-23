const std = @import("std");
const regex = @import("regex-oniguruma");

pub fn main() !void {
    std.debug.print("Application Start\n", .{});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var matcher = try regex.compile(allocator, "abc(.(*COUNT[x]))*f");
    defer matcher.deinit();

    std.debug.print("-------- {}\n", .{matcher.match("abcdefg")});
    std.debug.print("-------- {}\n", .{matcher.match("uuuuu")});
    std.debug.print("-------- {}\n", .{matcher.match("as ab")});

    if (matcher.matchGroup("abcdefg")) |d| {
        std.debug.print("-------- {any}\n", .{d.groups()});
        std.debug.print("-------- {any}\n", .{d.findIndex(1)});
    }

    if (matcher.matchGroup("abcssf")) |d| {
        std.debug.print("-------- {any}\n", .{try d.findByTag("x")});
    }
}
