const std = @import("std");

const BatteryCluster = struct {
    batteryStr: []const u8,
    allocator: std.mem.Allocator = undefined,
    highestBatteries: []usize = undefined,

    pub fn init(batteryCluster: []const u8, allocator: std.mem.Allocator, highestBatteriesSize: usize) !BatteryCluster {
        const highest = try allocator.alloc(usize, highestBatteriesSize);
        @memset(highest, 0);
        return .{ .batteryStr = batteryCluster, .allocator = allocator, .highestBatteries = highest };
    }

    pub fn printStr(self: *BatteryCluster) void {
        std.debug.print("{s}\n", .{self.batteryStr});
    }

    pub fn deinit(self: *BatteryCluster) void {
        self.allocator.free(self.highestBatteries);
    }
};

fn getHighest(batteryCluster: *BatteryCluster) void {
    for (batteryCluster.batteryStr) |batteryVoltage| {
        const digit = @as(usize, @intCast(batteryVoltage - '0'));
        if (batteryCluster.highestBatteries[0] == 0) {
            batteryCluster.highestBatteries[0] = digit;
        } else if (batteryCluster.highestBatteries[1] == 0) {
            batteryCluster.highestBatteries[1] = digit;
        } else if (batteryCluster.highestBatteries[0] < batteryCluster.highestBatteries[1]) {
            batteryCluster.highestBatteries[0] = batteryCluster.highestBatteries[1];
            batteryCluster.highestBatteries[1] = digit;
        } else if (batteryCluster.highestBatteries[1] < digit) {
            batteryCluster.highestBatteries[1] = digit;
        }
    }
}

fn firstPart(content: []const u8, allocator: std.mem.Allocator, highestBatteriesSize: usize) !usize {
    var it = std.mem.tokenizeAny(u8, content, "\n\r");
    var sum: usize = 0;
    while (it.next()) |batteryCluster| {
        var pack = try BatteryCluster.init(batteryCluster, allocator, highestBatteriesSize);
        defer pack.deinit();
        getHighest(&pack);
        sum += 10 * pack.highestBatteries[0] + pack.highestBatteries[1];
    }
    return sum;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const inputFile = "src/input/03.txt";

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const arenaAllocator = arena.allocator();

    const content = try std.Io.Dir.cwd().readFileAlloc(io, inputFile, arenaAllocator, .unlimited);
    defer arenaAllocator.free(content);

    std.debug.print("--- Part 1 ---\n", .{});
    const sum = try firstPart(content, arenaAllocator);
    std.debug.print("Sum: {d}\n", .{sum});
    std.debug.print("--- Part 2 ---\n", .{});
}

test "BatterPack Init" {
    const testAllocator = std.testing.allocator;

    var pack = try BatteryCluster.init("28475992", testAllocator, 2);
    defer pack.deinit();
    try std.testing.expectEqualStrings("28475992", pack.batteryStr);

    pack.deinit();
    pack = try BatteryCluster.init("222222", testAllocator, 2);
    try std.testing.expectEqualStrings("222222", pack.batteryStr);
}

test "Get Highest" {
    var highestBatteries = [_]usize{ 0, 0 };
    var pack = BatteryCluster{ .batteryStr = "3189", .highestBatteries = &highestBatteries };
    getHighest(&pack);
    try std.testing.expectEqualSlices(usize, &[_]usize{ 8, 9 }, pack.highestBatteries);

    highestBatteries = [_]usize{ 0, 0 };
    pack = BatteryCluster{ .batteryStr = "818181911112111", .highestBatteries = &highestBatteries };
    getHighest(&pack);
    try std.testing.expectEqualSlices(usize, &[_]usize{ 9, 2 }, pack.highestBatteries);
}

test "First Part" {
    const input = @embedFile("input/test/03.txt");
    const allocator = std.testing.allocator;

    const result = try firstPart(input, allocator, 2);
    try std.testing.expectEqual(357, result);
}
