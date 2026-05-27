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
        if (range[0] >= possibleRange[0] and range[1] <= possibleRange[1]) return RangePossibilities.Smaller;
        if (range[0] < possibleRange[0] and range[1] > possibleRange[1]) return RangePossibilities{ .Bigger = rangeIndex };
        if (range[0] < possibleRange[0]) return RangePossibilities{ .ShiftedLeft = rangeIndex };
        if (range[1] > possibleRange[1]) return RangePossibilities{ .ShiftedRight = rangeIndex };
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
    std.debug.print("Number of all possible freshIDs: {d}\n", .{allFreshIDs});
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

test "Check IDs" {
    const allocator = std.testing.allocator;

    const firstTestInput = "12\n35\n47\n58\n80\n110\n195\n215\n305\n390\n405\n450\n490";
    var ranges = Ranges{ .allocator = allocator, .ranges = .empty, .freshIDs = 0 };
    try ranges.ranges.appendSlice(ranges.allocator, &[_][2]usize{
        .{ 10, 60 },
        .{ 45, 130 },
        .{ 100, 220 },
        .{ 190, 320 },
        .{ 300, 410 },
        .{ 380, 500 },
    });
    try ranges.checkIDs(firstTestInput);
    try std.testing.expectEqual(13, ranges.freshIDs);

    const secondTestInput = "5\n42\n88\n99\n205\n270\n310\n348\n501\n575\n620\n648\n803\n900\n945\n1102\n1200\n1298";
    ranges.deinit();
    ranges = .{ .allocator = allocator, .ranges = .empty, .freshIDs = 0 };
    try ranges.ranges.appendSlice(ranges.allocator, &[_][2]usize{
        .{ 0, 99 },
        .{ 200, 349 },
        .{ 500, 649 },
        .{ 800, 949 },
        .{ 1100, 1299 },
    });
    try ranges.checkIDs(secondTestInput);
    try std.testing.expectEqual(18, ranges.freshIDs);

    const thirdTestInput = "1\n25\n49\n101\n200\n250\n299\n451\n600\n695\n851\n999\n1201\n1350\n1499\n1701\n2000\n5000";
    ranges.deinit();
    ranges = .{ .allocator = allocator, .freshIDs = 0, .ranges = .empty };
    try ranges.ranges.appendSlice(ranges.allocator, &[_][2]usize{
        .{ 50, 100 },
        .{ 300, 450 },
        .{ 700, 850 },
        .{ 1000, 1200 },
        .{ 1500, 1700 },
    });
    try ranges.checkIDs(thirdTestInput);
    try std.testing.expectEqual(0, ranges.freshIDs);

    const fourthTestInput = "3\n20\n55\n86\n100\n160\n250\n261\n399\n400\n490\n551\n660\n700\n785\n801\n900\n1000\n1100\n1151\n1300\n1399\n1450\n1451\n1800";
    ranges.deinit();
    ranges = .{ .allocator = allocator, .freshIDs = 0, .ranges = .empty };
    try ranges.ranges.appendSlice(ranges.allocator, &[_][2]usize{
        .{ 20, 85 },
        .{ 150, 260 },
        .{ 400, 550 },
        .{ 700, 800 },
        .{ 1000, 1150 },
        .{ 1300, 1450 },
    });
    defer ranges.deinit();
    try ranges.checkIDs(fourthTestInput);
    try std.testing.expectEqual(13, ranges.freshIDs);
}

test "Compact Range" {
    const allocator = std.testing.allocator;

    var range = Ranges{ .allocator = allocator, .ranges = .empty, .freshIDs = 0 };
    const firstTestExpectedRanges = [_][2]usize{
        .{ 650, 750 },
        .{ 200, 280 },
        .{ 1050, 1150 },
        .{ 5, 40 },
        .{ 850, 950 },
        .{ 350, 430 },
        .{ 1500, 1600 },
        .{ 80, 120 },
        .{ 1250, 1380 },
        .{ 500, 580 },
    };
    try range.ranges.appendSlice(
        range.allocator,
        &[_][2]usize{
            .{ 650, 750 },
            .{ 200, 280 },
            .{ 1050, 1150 },
            .{ 5, 40 },
            .{ 850, 950 },
            .{ 350, 430 },
            .{ 1500, 1600 },
            .{ 80, 120 },
            .{ 1250, 1380 },
            .{ 500, 580 },
        },
    );
    defer range.deinit();
    try range.compactRange();
    try std.testing.expectEqualSlices([2]usize, &firstTestExpectedRanges, range.ranges.items);

    const secondTestExpectedRanges = [_][2]usize{ .{ 700, 1200 }, .{ 300, 640 }, .{ 10, 250 } };
    range.deinit();
    range = Ranges{ .allocator = allocator, .freshIDs = 0, .ranges = .empty };
    try range.ranges.appendSlice(range.allocator, &[_][2]usize{
        .{ 800, 950 },
        .{ 300, 420 },
        .{ 60, 160 },
        .{ 1050, 1200 },
        .{ 10, 80 },
        .{ 500, 640 },
        .{ 140, 250 },
        .{ 920, 1080 },
        .{ 380, 530 },
        .{ 700, 830 },
    });

    try range.compactRange();
    try std.testing.expectEqualSlices([2]usize, &secondTestExpectedRanges, range.ranges.items);

    const thirdTestExpectedRanges = [_][2]usize{ .{ 200, 350 }, .{ 1400, 1700 }, .{ 10, 100 }, .{ 1100, 1250 }, .{ 500, 950 } };
    range.deinit();
    range = Ranges{ .allocator = allocator, .ranges = .empty, .freshIDs = 0 };
    try range.ranges.appendSlice(range.allocator, &[_][2]usize{
        .{ 800, 950 },
        .{ 1550, 1700 },
        .{ 50, 100 },
        .{ 1100, 1250 },
        .{ 500, 650 },
        .{ 10, 50 },
        .{ 1400, 1550 },
        .{ 200, 350 },
        .{ 650, 800 },
    });
    try range.compactRange();
    try std.testing.expectEqualSlices([2]usize, &thirdTestExpectedRanges, range.ranges.items);

    const fourthTestExpectedRanges = [_][2]usize{ .{ 20, 80 }, .{ 400, 750 }, .{ 1700, 1800 }, .{ 150, 350 }, .{ 900, 1000 }, .{ 1100, 1500 } };
    range.deinit();
    range = Ranges{ .allocator = allocator, .ranges = .empty, .freshIDs = 0 };
    try range.ranges.appendSlice(range.allocator, &[_][2]usize{
        .{ 1230, 1400 },
        .{ 550, 750 },
        .{ 1700, 1800 },
        .{ 250, 350 },
        .{ 900, 1000 },
        .{ 1100, 1250 },
        .{ 20, 80 },
        .{ 1400, 1500 },
        .{ 150, 250 },
        .{ 400, 600 },
    });
    try range.compactRange();
    try std.testing.expectEqualSlices([2]usize, &fourthTestExpectedRanges, range.ranges.items);
}

test "Find All Fresh IDs" {
    const allocator = std.testing.allocator;
    var ranges = Ranges{ .allocator = allocator, .ranges = .empty, .freshIDs = 0 };
    defer ranges.deinit();
    try ranges.ranges.appendSlice(ranges.allocator, &[_][2]usize{
        .{ 300, 450 },
        .{ 20, 45 },
        .{ 780, 850 },
        .{ 5, 5 },
        .{ 1200, 1350 },
        .{ 90, 140 },
        .{ 600, 610 },
        .{ 1500, 1800 },
        .{ 400, 405 },
        .{ 50, 75 },
    });
    try std.testing.expectEqual(795, ranges.findAllFreshIDs());

    ranges.deinit();
    ranges = Ranges{ .allocator = allocator, .ranges = .empty, .freshIDs = 0 };
    try ranges.ranges.appendSlice(ranges.allocator, &[_][2]usize{
        .{ 1000, 1000 },
        .{ 75, 200 },
        .{ 5000, 5099 },
        .{ 10, 12 },
        .{ 800, 900 },
        .{ 420, 500 },
        .{ 2000, 2200 },
        .{ 150, 155 },
        .{ 3300, 3400 },
        .{ 0, 9 },
    });
    try std.testing.expectEqual(730, ranges.findAllFreshIDs());

    ranges.deinit();
    ranges = Ranges{ .allocator = allocator, .ranges = .empty, .freshIDs = 0 };
    try ranges.ranges.appendSlice(ranges.allocator, &[_][2]usize{
        .{ 540, 600 },
        .{ 1800, 1900 },
        .{ 30, 30 },
        .{ 700, 710 },
        .{ 100, 299 },
        .{ 4000, 4500 },
        .{ 8, 20 },
        .{ 2500, 2550 },
        .{ 1000, 1024 },
        .{ 350, 351 },
    });
    try std.testing.expectEqual(966, ranges.findAllFreshIDs());
}

test "Check Ranges" {
    var testOneRanges = [_][2]usize{ .{ 50, 150 }, .{ 500, 600 }, .{ 900, 1000 }, .{ 1300, 1500 }, .{ 1800, 1950 }, .{ 2200, 2400 } };
    const testOneNewRange = [2]usize{ 80, 120 };
    const testOneOutput = checkRanges(&testOneRanges, testOneNewRange);
    try std.testing.expectEqual(std.meta.activeTag(testOneOutput), RangePossibilities.Smaller);

    var testTwoRanges = [_][2]usize{
        .{ 100, 200 },
        .{ 600, 750 },
        .{ 1000, 1100 },
        .{ 1400, 1600 },
        .{ 2000, 2200 },
        .{ 2500, 2600 },
    };
    const testTwoNewRange = [2]usize{ 1300, 1700 };
    const testTwoOutput = checkRanges(&testTwoRanges, testTwoNewRange);
    try std.testing.expectEqual(std.meta.activeTag(testTwoOutput), RangePossibilities.Bigger);
    try std.testing.expectEqual(3, testTwoOutput.Bigger);

    var testThreeRanges = [_][2]usize{
        .{ 50, 200 },
        .{ 400, 600 },
        .{ 900, 1050 },
        .{ 1300, 1500 },
        .{ 1800, 2000 },
        .{ 2300, 2600 },
    };
    const testThreeNewRange = [2]usize{ 2500, 2900 };
    const testThreeOutput = checkRanges(&testThreeRanges, testThreeNewRange);
    try std.testing.expectEqual(std.meta.activeTag(testThreeOutput), RangePossibilities.ShiftedRight);
    try std.testing.expectEqual(5, testThreeOutput.ShiftedRight);

    var testFourRanges = [_][2]usize{
        .{ 400, 700 },
        .{ 1000, 1200 },
        .{ 1500, 1700 },
        .{ 2000, 2200 },
        .{ 2500, 2700 },
        .{ 3000, 3200 },
    };
    const testFourNewRange = [2]usize{ 200, 550 };
    const testFourOutput = checkRanges(&testFourRanges, testFourNewRange);
    try std.testing.expectEqual(std.meta.activeTag(testFourOutput), RangePossibilities.ShiftedLeft);
    try std.testing.expectEqual(0, testFourOutput.ShiftedLeft);

    var testFiveRanges = [_][2]usize{
        .{ 2000, 2200 },
        .{ 500, 600 },
        .{ 2700, 2900 },
        .{ 100, 200 },
        .{ 1400, 1600 },
        .{ 900, 1000 },
    };
    const testFiveNewRange = [2]usize{ 1200, 1350 };
    const testFiveOutput = checkRanges(&testFiveRanges, testFiveNewRange);
    try std.testing.expectEqual(std.meta.activeTag(testFiveOutput), RangePossibilities.NewRange);
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
