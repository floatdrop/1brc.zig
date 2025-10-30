const std = @import("std");

const Stats = struct {
    min: i16 = 999,
    max: i16 = -999,
    avg: i64 = 0,
    n: i64 = 0,
};

pub fn parseNumber(s: []const u8) i16 {
    const decim: i16 = std.fmt.parseInt(i16, s[0 .. s.len - 2], 10) catch unreachable;
    const frac: u8 = s[s.len - 1] - '0';
    if (s[0] == '-') {
        return decim * 10 - frac;
    } else {
        return decim * 10 + frac;
    }
}

pub fn main() !void {
    const cwd = std.fs.cwd();

    var file = try cwd.openFile("measurements.txt", .{ .mode = .read_only });
    defer file.close();

    const file_stats = try file.stat();
    const file_size: usize = @intCast(file_stats.size);

    // Map the file into memory
    const mapped_memory = try std.posix.mmap(
        null, // Address hint (null for OS to choose)
        file_size, // Length of the mapping
        std.posix.PROT.READ, // Protection: read-only
        .{
            .TYPE = .PRIVATE,
            // On linux this could be benefitial
            // .POPULATE = true,
        },
        file.handle, // File descriptor
        0, // Offset within the file
    );
    defer std.posix.munmap(mapped_memory);

    var reader = std.Io.Reader.fixed(mapped_memory);

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

    while (try reader.takeDelimiter('\n')) |line| {
        const semicolon = std.mem.indexOfScalar(u8, line, ';') orelse unreachable;
        const name = line[0..semicolon];
        const temp = parseNumber(line[semicolon + 1 ..]);

        const entry = try map.getOrPut(name);

        if (!entry.found_existing) {
            entry.key_ptr.* = try allocator.dupe(u8, name);
            entry.value_ptr.* = Stats{};
        }

        var stats = entry.value_ptr;
        stats.min = @min(stats.min, temp);
        stats.max = @max(stats.max, temp);
        stats.n += 1;
        stats.avg += temp;
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
        std.debug.print("{s}={d}/{d}/{d}", .{ item.key_ptr.*, item.value_ptr.min, @divTrunc(item.value_ptr.avg, item.value_ptr.n), item.value_ptr.max });
    }
    std.debug.print("}}\n", .{});
}

test "parse temperature" {
    try std.testing.expectEqual(-1001, parseNumber("-100.1"));
    try std.testing.expectEqual(101, parseNumber("10.1"));
    try std.testing.expectEqual(1, parseNumber("0.1"));
    try std.testing.expectEqual(-1, parseNumber("-0.1"));
    try std.testing.expectEqual(-12, parseNumber("-1.2"));
}
