const std = @import("std");

const BatteryCluster = struct {
    batteryStr: []const u8,
    allocator: std.mem.Allocator = undefined,
    highestBatteries: []u8 = undefined,

    pub fn init(batteryCluster: []const u8, allocator: std.mem.Allocator, highestBatteriesSize: usize) !BatteryCluster {
        const highest = try allocator.alloc(u8, highestBatteriesSize);
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

fn getHighest(batteryCluster: *BatteryCluster) !usize {
    for (batteryCluster.batteryStr, 0..) |batteryVoltage, batteryIndex| {
        if (batteryIndex < batteryCluster.highestBatteries.len) {
            batteryCluster.highestBatteries[batteryIndex] = batteryVoltage;
            continue;
        }
        for (batteryCluster.highestBatteries[0 .. batteryCluster.highestBatteries.len - 1], 0..) |voltage, index| {
            if (voltage >= batteryCluster.highestBatteries[index + 1]) continue;
            @memmove(batteryCluster.highestBatteries[index .. batteryCluster.highestBatteries.len - 1], batteryCluster.highestBatteries[index + 1 ..]);
            batteryCluster.highestBatteries[batteryCluster.highestBatteries.len - 1] = batteryVoltage;
            break;
        }
        if (batteryCluster.highestBatteries[batteryCluster.highestBatteries.len - 1] < batteryVoltage) batteryCluster.highestBatteries[batteryCluster.highestBatteries.len - 1] = batteryVoltage;
    }
    return try std.fmt.parseInt(usize, batteryCluster.highestBatteries, 10);
}

fn findHighestSum(content: []const u8, allocator: std.mem.Allocator, highestBatteriesSize: usize) !usize {
    var it = std.mem.tokenizeAny(u8, content, "\n\r");
    var sum: usize = 0;
    while (it.next()) |batteryCluster| {
        var pack = try BatteryCluster.init(batteryCluster, allocator, highestBatteriesSize);
        defer pack.deinit();
        const newSum = try getHighest(&pack);
        sum += newSum;
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
    var sum = try findHighestSum(content, arenaAllocator, 2);
    std.debug.print("Sum: {d}\n", .{sum});
    std.debug.print("--- Part 2 ---\n", .{});
    sum = try findHighestSum(content, arenaAllocator, 12);
    std.debug.print("Sum: {d}\n", .{sum});
}

test "BatterPack Init" {
    const testAllocator = std.testing.allocator;

    var pack = try BatteryCluster.init("28475992", testAllocator, 2);
    defer pack.deinit();
    const testOneHighestBatteries = [_]u8{ 0, 0 };
    try std.testing.expectEqualStrings("28475992", pack.batteryStr);
    try std.testing.expectEqualSlices(u8, &testOneHighestBatteries, pack.highestBatteries);

    pack.deinit();
    const testTwoHighestBatteries = [_]u8{ 0, 0, 0, 0, 0 };
    pack = try BatteryCluster.init("222222", testAllocator, 5);
    try std.testing.expectEqualStrings("222222", pack.batteryStr);
    try std.testing.expectEqualSlices(u8, &testTwoHighestBatteries, pack.highestBatteries);
}

test "Get Highest" {
    var testOneHighestBatteries = [_]u8{ 0, 0 };
    var pack = BatteryCluster{ .batteryStr = "3189", .highestBatteries = &testOneHighestBatteries };
    var number = try getHighest(&pack);
    try std.testing.expectEqualSlices(u8, &[_]u8{ '8', '9' }, pack.highestBatteries);
    try std.testing.expectEqual(89, number);

    var testTwoHighestBatteries = [_]u8{ 0, 0, 0, 0 };
    pack = BatteryCluster{ .batteryStr = "818181911112111", .highestBatteries = &testTwoHighestBatteries };
    number = try getHighest(&pack);
    try std.testing.expectEqualSlices(u8, &[_]u8{ '9', '2', '1', '1' }, pack.highestBatteries);
    try std.testing.expectEqual(9211, number);
}

test "First Part" {
    const input = @embedFile("input/test/03.txt");
    const allocator = std.testing.allocator;

    const result = try findHighestSum(input, allocator, 2);
    try std.testing.expectEqual(357, result);
}

test "Second Part" {
    const input = @embedFile("input/test/03.txt");
    const allocator = std.testing.allocator;

    const result = try findHighestSum(input, allocator, 12);

    try std.testing.expectEqual(3121910778619, result);
}
