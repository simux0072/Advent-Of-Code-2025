const std = @import("std");

const Ranges = struct {
    allocator: std.mem.Allocator,
    ranges: std.ArrayList([2]usize),
    ids: std.ArrayList(usize),

    pub fn init(content: []const u8, allocator: std.mem.Allocator) !Ranges {
        var self: Ranges = .{ .allocator = allocator, .ranges = .empty, .ids = .empty };
        try self.createRanges(content);
        return self;
    }

    fn createRanges(self: *Ranges, content: []const u8) !void {
        const separatorIndex = std.mem.find(u8, content, "\n\n");
        var lineIter = std.mem.tokenizeAny(u8, content[0..separatorIndex.?], "\n");
        while (lineIter.next()) |newLines| {
            var numberIter = std.mem.tokenizeAny(u8, newLines, "-");
            const tempNumberRange = [2]usize{ try std.fmt.parseInt(usize, numberIter.next().?, 10), try std.fmt.parseInt(usize, numberIter.next().?, 10) };
            try self.ranges.append(self.allocator, tempNumberRange);
        }

        var numberIter = std.mem.tokenizeAny(u8, content[separatorIndex.? + 2 ..], "\n");
        while (numberIter.next()) |number| {
            try self.ids.append(self.allocator, try std.fmt.parseInt(usize, number, 10));
        }
    }

    pub fn deinit(self: *Ranges) void {
        self.ranges.deinit(self.allocator);
        self.ids.deinit(self.allocator);
    }
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const inputFile = "src/input/05.txt";
    const allocator = init.arena.allocator();

    const content = try std.Io.Dir.cwd().readFileAlloc(io, inputFile, allocator, .unlimited);

    std.debug.print("--- Part 1 ---\n", .{});
    var range = try Ranges.init(content, allocator);
    defer range.deinit();
    std.debug.print("--- Part 2 ---\n", .{});
}

test "Ranges Init" {
    const allocator = std.testing.allocator;

    const firstTestInput = "10-12\n13-14\n18-55\n332-400\n\n1\n10\n15\n200\n554";
    var ranges = try Ranges.init(firstTestInput, allocator);
    defer ranges.deinit();

    const firstTestExpectedRanges = [_][2]usize{ [2]usize{ 10, 12 }, [2]usize{ 13, 14 }, [2]usize{ 18, 55 }, [2]usize{ 332, 400 } };
    const firstTestExpectedIds = [_]usize{ 1, 10, 15, 200, 554 };

    try std.testing.expectEqualSlices([2]usize, &firstTestExpectedRanges, ranges.ranges.items);
    try std.testing.expectEqualSlices(usize, &firstTestExpectedIds, ranges.ids.items);

    const secondTestInput = "112-1004\n13-15\n21-222\n19-19\n\n110101\n13\n1\n0\n1551\n8";
    ranges.deinit();
    ranges = try Ranges.init(secondTestInput, allocator);

    const secondTestExpectedRanges = [_][2]usize{ [2]usize{ 112, 1004 }, [2]usize{ 13, 15 }, [2]usize{ 21, 222 }, [2]usize{ 19, 19 } };
    const secondTestExpectedIds = [_]usize{ 110101, 13, 1, 0, 1551, 8 };

    try std.testing.expectEqualSlices([2]usize, &secondTestExpectedRanges, ranges.ranges.items);
    try std.testing.expectEqualSlices(usize, &secondTestExpectedIds, ranges.ids.items);
}

test "Create Ranges" {
    const allocator = std.testing.allocator;

    const firstTestInput = "10-12\n13-14\n18-55\n332-400\n\n1\n10\n15\n200\n554";
    var ranges: Ranges = .{ .allocator = allocator, .ids = .empty, .ranges = .empty };
    defer ranges.deinit();

    try ranges.createRanges(firstTestInput);

    const firstTestExpectedRanges = [_][2]usize{ [2]usize{ 10, 12 }, [2]usize{ 13, 14 }, [2]usize{ 18, 55 }, [2]usize{ 332, 400 } };
    const firstTestExpectedIds = [_]usize{ 1, 10, 15, 200, 554 };

    try std.testing.expectEqualSlices([2]usize, &firstTestExpectedRanges, ranges.ranges.items);
    try std.testing.expectEqualSlices(usize, &firstTestExpectedIds, ranges.ids.items);

    const secondTestInput = "112-1004\n13-15\n21-222\n19-19\n\n110101\n13\n1\n0\n1551\n8";
    ranges.deinit();
    ranges = .{ .allocator = allocator, .ranges = .empty, .ids = .empty };
    try ranges.createRanges(secondTestInput);

    const secondTestExpectedRanges = [_][2]usize{ [2]usize{ 112, 1004 }, [2]usize{ 13, 15 }, [2]usize{ 21, 222 }, [2]usize{ 19, 19 } };
    const secondTestExpectedIds = [_]usize{ 110101, 13, 1, 0, 1551, 8 };

    try std.testing.expectEqualSlices([2]usize, &secondTestExpectedRanges, ranges.ranges.items);
    try std.testing.expectEqualSlices(usize, &secondTestExpectedIds, ranges.ids.items);
}
