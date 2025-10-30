const std = @import("std");

pub fn main() !void {
    const cwd = std.fs.cwd();

    var file = try cwd.openFile("measurements.txt", .{ .mode = .read_only });
    defer file.close();

    const file_stats = try file.stat();
    const file_size: usize = @intCast(file_stats.size);

    const mapped_memory = try std.posix.mmap(
        null,
        file_size,
        std.posix.PROT.READ,
        .{
            .TYPE = .PRIVATE,
            // On linux this could be benefitial
            // .POPULATE = true,
        },
        file.handle,
        0,
    );
    defer std.posix.munmap(mapped_memory);

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const allocator = general_purpose_allocator.allocator();

    const cpu_count: usize = try std.Thread.getCpuCount();

    var pool: std.Thread.Pool = undefined;
    try pool.init(std.Thread.Pool.Options{ .allocator = allocator, .n_jobs = cpu_count });
    defer pool.deinit();

    const chunk_size = mapped_memory.len / cpu_count;
    const maps = try allocator.alloc(std.StringHashMap(Stats), cpu_count + 1);
    defer {
        for (maps) |*map| {
            var key_iter = map.keyIterator();
            while (key_iter.next()) |key| {
                allocator.free(key.*);
            }
            map.deinit();
        }
        allocator.free(maps);
    }

    {
        var i: usize = 0;
        var wg = std.Thread.WaitGroup{};
        var iter = std.mem.window(u8, mapped_memory, chunk_size, chunk_size);
        while (iter.next()) |buf| : (i += 1) {
            maps[i] = std.StringHashMap(Stats).init(allocator);
            pool.spawnWg(&wg, parseLines, .{ allocator, buf, &maps[i] });
        }
        wg.wait();
    }

    var map = std.StringHashMap(Stats).init(allocator);
    defer {
        var key_iter = map.keyIterator();
        while (key_iter.next()) |key| {
            allocator.free(key.*);
        }
        map.deinit();
    }

    for (maps) |m| {
        var iter = m.iterator();
        while (iter.next()) |i| {
            const name = i.key_ptr.*;
            const entry = map.getOrPut(name) catch unreachable;
            if (!entry.found_existing) {
                entry.key_ptr.* = allocator.dupe(u8, name) catch unreachable;
                entry.value_ptr.* = Stats{};
            }

            entry.value_ptr.join(i.value_ptr);
        }
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

pub fn parseLines(allocator: std.mem.Allocator, buffer: []const u8, map: *std.StringHashMap(Stats)) void {
    var start_index: usize = std.mem.indexOfScalar(u8, buffer, '\n') orelse 0;

    while (std.mem.indexOfScalarPos(u8, buffer, start_index, '\n')) |eol| : (start_index = eol + 1) {
        const line = buffer[start_index..eol];
        const semicolon = std.mem.indexOfScalar(u8, line, ';') orelse continue;
        const name = line[0..semicolon];
        const temp = parseNumber(line[semicolon + 1 ..]);

        const entry = map.getOrPut(name) catch unreachable;
        if (!entry.found_existing) {
            entry.key_ptr.* = allocator.dupe(u8, name) catch unreachable;
            entry.value_ptr.* = Stats{};
        }

        entry.value_ptr.add(temp);
    }
}

const Stats = struct {
    min: i16 = 999,
    max: i16 = -999,
    avg: i64 = 0,
    n: i64 = 0,

    pub fn join(self: *Stats, other: *Stats) void {
        self.min = @min(self.min, other.min);
        self.max = @max(self.max, other.max);
        self.n += other.n;
        self.avg += other.avg;
    }

    pub fn add(self: *Stats, temp: i16) void {
        self.min = @min(self.min, temp);
        self.max = @max(self.max, temp);
        self.n += 1;
        self.avg += temp;
    }
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

test "parse temperature" {
    try std.testing.expectEqual(-1001, parseNumber("-100.1"));
    try std.testing.expectEqual(101, parseNumber("10.1"));
    try std.testing.expectEqual(1, parseNumber("0.1"));
    try std.testing.expectEqual(-1, parseNumber("-0.1"));
    try std.testing.expectEqual(-12, parseNumber("-1.2"));
}
