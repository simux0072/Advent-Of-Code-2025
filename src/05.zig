const std = @import("std");

const RangePossibilities = union(enum) {
    ShiftedRight: usize,
    ShiftedLeft: usize,
    Bigger: usize,
    Smaller: void,
    NewRange: void,
};

const Ranges = struct {
    allocator: std.mem.Allocator,
    ranges: std.ArrayList([2]usize),
    freshIDs: usize,

    fn init(content: []const u8, allocator: std.mem.Allocator) !Ranges {
        var self: Ranges = .{ .allocator = allocator, .ranges = .empty, .freshIDs = 0 };
        try self.createRanges(content);
        return self;
    }

    fn createRanges(self: *Ranges, content: []const u8) !void {
        const separatorIndex = std.mem.find(u8, content, "\n\n");
        var lineIter = std.mem.tokenizeAny(u8, content[0..separatorIndex.?], "\n");
        while (lineIter.next()) |newLines| {
            var numberIter = std.mem.tokenizeAny(u8, newLines, "-");
            const tempNumberRange = [2]usize{ try std.fmt.parseInt(usize, numberIter.next().?, 10), try std.fmt.parseInt(usize, numberIter.next().?, 10) };
            switch (checkRanges(self.ranges.items, tempNumberRange)) {
                .Smaller => continue,
                .Bigger => |index| self.ranges.items[index] = tempNumberRange,
                .ShiftedLeft => |index| self.ranges.items[index][0] = tempNumberRange[0],
                .ShiftedRight => |index| self.ranges.items[index][1] = tempNumberRange[1],
                .NewRange => try self.ranges.append(self.allocator, tempNumberRange),
            }
        }
        try self.compactRange();
        return self.checkIDs(content[separatorIndex.? + 2 ..]);
    }

    fn checkIDs(self: *Ranges, content: []const u8) !void {
        var numberIter = std.mem.tokenizeAny(u8, content, "\n");
        while (numberIter.next()) |number| {
            const numberInt = try std.fmt.parseInt(usize, number, 10);
            for (self.ranges.items) |range| {
                if (range[0] <= numberInt and range[1] >= numberInt) {
                    self.freshIDs += 1;
                    break;
                }
            }
        }
    }

    fn compactRange(self: *Ranges) !void {
        if (self.ranges.items.len == 0) return error.ArrayHasZeroElements;
        for (0..self.ranges.items.len - 1) |firstRangeIndex| {
            switch (checkRanges(self.ranges.items[firstRangeIndex + 1 ..], self.ranges.items[firstRangeIndex])) {
                .Smaller => {
                    _ = self.ranges.swapRemove(firstRangeIndex);
                    return try self.compactRange();
                },
                .Bigger => |index| {
                    _ = self.ranges.swapRemove(firstRangeIndex + 1 + index);
                    return try self.compactRange();
                },
                .ShiftedLeft => |index| {
                    self.ranges.items[firstRangeIndex + 1 + index][0] = self.ranges.items[firstRangeIndex][0];
                    _ = self.ranges.swapRemove(firstRangeIndex);
                    return try self.compactRange();
                },
                .ShiftedRight => |index| {
                    self.ranges.items[firstRangeIndex + 1 + index][1] = self.ranges.items[firstRangeIndex][1];
                    _ = self.ranges.swapRemove(firstRangeIndex);
                    return try self.compactRange();
                },
                .NewRange => continue,
            }
        }
        return;
    }

    fn findAllFreshIDs(self: *Ranges) usize {
        var allFreshIDs: usize = 0;
        for (self.ranges.items) |range| {
            allFreshIDs += range[1] - range[0] + 1;
        }
        return allFreshIDs;
    }

    fn deinit(self: *Ranges) void {
        self.ranges.deinit(self.allocator);
    }
};

fn checkRanges(rangesToCheck: [][2]usize, range: [2]usize) RangePossibilities {
    for (rangesToCheck, 0..) |possibleRange, rangeIndex| {
        if (range[0] > possibleRange[1] + 1 or range[1] < possibleRange[0] - 1) continue;
        if (range[0] >= possibleRange[0] - 1 and range[1] <= possibleRange[1] + 1) return RangePossibilities.Smaller;
        if (range[0] < possibleRange[0] - 1 and range[1] > possibleRange[1] + 1) return RangePossibilities{ .Bigger = rangeIndex };
        if (range[0] < possibleRange[0] - 1) return RangePossibilities{ .ShiftedLeft = rangeIndex };
        if (range[1] > possibleRange[1] + 1) return RangePossibilities{ .ShiftedRight = rangeIndex };
    }
    return RangePossibilities.NewRange;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const inputFile = "src/input/05.txt";
    const allocator = init.arena.allocator();

    const content = try std.Io.Dir.cwd().readFileAlloc(io, inputFile, allocator, .unlimited);

    std.debug.print("--- Part 1 ---\n", .{});
    var range = try Ranges.init(content, allocator);
    std.debug.print("FreshIDs: {d}\n", .{range.freshIDs});
    defer range.deinit();
    std.debug.print("--- Part 2 ---\n", .{});
    range.deinit();
    range = try Ranges.init(content, allocator);
    const allFreshIDs = range.findAllFreshIDs();
    std.debug.print("Number of possible freshIDs: {d}\n", .{allFreshIDs});
}

test "Ranges Init" {
    const allocator = std.testing.allocator;

    const firstTestInput = "10-12\n13-14\n18-55\n332-400\n\n1\n10\n15\n200\n554";
    var ranges = try Ranges.init(firstTestInput, allocator);
    defer ranges.deinit();

    const firstTestExpectedRanges = [_][2]usize{ [2]usize{ 10, 14 }, [2]usize{ 18, 55 }, [2]usize{ 332, 400 } };

    try std.testing.expectEqualSlices([2]usize, &firstTestExpectedRanges, ranges.ranges.items);

    const secondTestInput = "112-1004\n13-15\n21-222\n19-19\n\n110101\n13\n1\n0\n1551\n8";
    ranges.deinit();
    ranges = try Ranges.init(secondTestInput, allocator);

    const secondTestExpectedRanges = [_][2]usize{ [2]usize{ 21, 1004 }, [2]usize{ 13, 15 }, [2]usize{ 19, 19 } };

    try std.testing.expectEqualSlices([2]usize, &secondTestExpectedRanges, ranges.ranges.items);
}

test "Create Ranges" {
    const allocator = std.testing.allocator;

    const firstTestInput = "10-12\n13-14\n18-55\n332-400\n\n1\n10\n15\n200\n554";
    var ranges: Ranges = .{ .allocator = allocator, .ranges = .empty, .freshIDs = 0 };
    defer ranges.deinit();

    try ranges.createRanges(firstTestInput);

    const firstTestExpectedRanges = [_][2]usize{ [2]usize{ 10, 14 }, [2]usize{ 18, 55 }, [2]usize{ 332, 400 } };
    const firstTestFreshIDs = 1;

    try std.testing.expectEqualSlices([2]usize, &firstTestExpectedRanges, ranges.ranges.items);
    try std.testing.expectEqual(firstTestFreshIDs, ranges.freshIDs);

    const secondTestInput = "112-1004\n13-15\n21-222\n19-19\n\n110101\n13\n1\n0\n1551\n8";
    const secondTestFreshIDs = 1;
    ranges.deinit();
    ranges = .{ .allocator = allocator, .ranges = .empty, .freshIDs = 0 };
    try ranges.createRanges(secondTestInput);

    const secondTestExpectedRanges = [_][2]usize{ [2]usize{ 21, 1004 }, [2]usize{ 13, 15 }, [2]usize{ 19, 19 } };

    try std.testing.expectEqualSlices([2]usize, &secondTestExpectedRanges, ranges.ranges.items);
    try std.testing.expectEqual(secondTestFreshIDs, ranges.freshIDs);
}

test "Part 1" {
    const allocator = std.testing.allocator;
    const content = @embedFile("input/test/05.txt");

    var ranges = try Ranges.init(content, allocator);
    defer ranges.deinit();

    try std.testing.expectEqual(3, ranges.freshIDs);
}

test "Part 2" {
    const allocator = std.testing.allocator;
    const content = @embedFile("input/test/05.txt");

    var ranges = try Ranges.init(content, allocator);
    defer ranges.deinit();

    const allFreshIDs = ranges.findAllFreshIDs();

    try std.testing.expectEqual(14, allFreshIDs);
}
