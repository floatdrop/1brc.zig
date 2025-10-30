const std = @import("std");

const Stats = struct {
    min: f64 = 99,
    max: f64 = -99,
    avg: f64 = 0,
    n: usize = 0,
};

pub fn main() !void {
    const cwd = std.fs.cwd();

    var file = try cwd.openFile("measurements.txt", .{ .mode = .read_only });
    defer file.close();

    var buffer: [8192]u8 = undefined;
    var reader = file.reader(&buffer);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var map = std.StringHashMap(Stats).init(allocator);

    defer {
        var key_iter = map.keyIterator();
        while (key_iter.next()) |key| {
            allocator.free(key.*);
        }
        map.deinit();
    }

    while (try reader.interface.takeDelimiter('\n')) |line| {
        const semicolon = std.mem.indexOf(u8, line, ";") orelse unreachable;
        const name = line[0..semicolon];
        const temp = try std.fmt.parseFloat(f64, line[semicolon + 1 ..]);

        const entry = try map.getOrPut(name);

        if (!entry.found_existing) {
            entry.key_ptr.* = try allocator.dupe(u8, name);
            entry.value_ptr.* = Stats{};
        }

        var stats = entry.value_ptr;
        stats.min = @min(stats.min, temp);
        stats.max = @max(stats.max, temp);
        stats.n += 1;
        stats.avg = stats.avg + (temp - stats.avg) / @as(f64, @floatFromInt(stats.n));
    }

    std.debug.print("{{", .{});
    var print_comma = false;
    var iter = map.iterator();
    while (iter.next()) |item| {
        if (print_comma) {
            std.debug.print(", ", .{});
        } else {
            print_comma = true;
        }
        std.debug.print("{s}={d:.1}/{d:.1}/{d:.1}", .{ item.key_ptr.*, item.value_ptr.min, item.value_ptr.avg, item.value_ptr.max });
    }
    std.debug.print("}}\n", .{});
}
