const std = @import("std");

const SearchRange = struct {
    upperStr: []const u8,
    upper: usize,
    lowerStr: []const u8,
    lower: usize,

    pub fn init(ranges: []const u8) !SearchRange {
        var it = std.mem.tokenizeScalar(u8, ranges, '-');
        const lowerBound = it.next().?;
        const upperBound = it.next().?;
        const intLowerBound = try std.fmt.parseInt(usize, lowerBound, 10);
        const intUpperBound = try std.fmt.parseInt(usize, upperBound, 10);
        return .{ .upperStr = upperBound, .lowerStr = lowerBound, .upper = intUpperBound, .lower = intLowerBound };
    }

    pub fn printStr(self: *SearchRange) void {
        std.debug.print("{s}:{s}\n", .{ self.lowerStr, self.upperStr });
    }

    pub fn printInt(self: *SearchRange) void {
        std.debug.print("{d}:{d}\n", .{ self.lower, self.upper });
    }
};

fn repeatNTimes(initNumber: usize, times: usize) usize {
    const numDigits: usize = @intCast(std.math.log10(initNumber) + 1);
    var base: usize = 1;
    for (0..numDigits) |_| {
        base *= 10;
    }

    var number: usize = initNumber;
    for (0..times - 1) |_| {
        number = number * base + initNumber;
    }

    return number;
}

fn findRepetitions(searchRange: SearchRange, checkRepetition: ?usize, seenNumbers: *std.AutoHashMap(usize, void)) !usize {
    var sum: usize = 0;
    // Go through the whole range checking if that specific
    for (searchRange.lowerStr.len..searchRange.upperStr.len + 1) |numDigits| {
        // Check if there there is a request for a specific repetition
        if (checkRepetition) |repetitions| {
            if (@rem(numDigits, repetitions) != 0) continue;
            // Get the first checkRepetition number of digits (which later to repeat) as the base number
            // If it matches lowerStr, then just take the first checkRepetition number of characters and convert them into usize
            // Else create a new base 10 number that is checkRepetition number times lower than 10^numDigits
            var baseNumber = if (numDigits == searchRange.lowerStr.len) try std.fmt.parseInt(usize, searchRange.lowerStr[0 .. searchRange.lowerStr.len / repetitions], 10) else try std.math.powi(usize, 10, (numDigits / repetitions) - 1);
            while (true) : (baseNumber += 1) {
                const checkNum = repeatNTimes(baseNumber, repetitions);
                if (checkNum > searchRange.upper) break;
                if (seenNumbers.get(checkNum) != null) continue;
                if (checkNum < searchRange.lower) continue;
                sum += checkNum;
                try seenNumbers.put(checkNum, {});
            }
        } else {
            for (2..numDigits + 1) |repetitionNum| {
                if (@rem(numDigits, repetitionNum) != 0) continue;
                var baseNumber: usize = if (numDigits == searchRange.lowerStr.len) try std.fmt.parseInt(usize, searchRange.lowerStr[0 .. searchRange.lowerStr.len / repetitionNum], 10) else try std.math.powi(usize, 10, (numDigits / repetitionNum) - 1);
                while (@as(usize, @intCast(std.math.log10(baseNumber) + 1)) * repetitionNum == numDigits) : (baseNumber += 1) {
                    const checkNum = repeatNTimes(baseNumber, repetitionNum);
                    if (checkNum > searchRange.upper) break;
                    if (seenNumbers.get(checkNum) != null) continue;
                    if (checkNum < searchRange.lower) continue;
                    sum += checkNum;
                    try seenNumbers.put(checkNum, {});
                }
            }
        }
    }
    return sum;
}

fn firstPart(fileContent: []u8, alloc: std.mem.Allocator) !usize {
    var it = std.mem.tokenizeAny(u8, fileContent, ",\r\n");
    var sum: usize = 0;
    while (it.next()) |ranges| {
        const searchRange: SearchRange = try SearchRange.init(ranges);
        // searchRange.printInt();
        var seenNumbers = std.AutoHashMap(usize, void).init(alloc);
        defer seenNumbers.deinit();
        sum += try findRepetitions(searchRange, 2, &seenNumbers);
    }
    return sum;
}

fn secondPart(fileContent: []u8, alloc: std.mem.Allocator) !usize {
    var it = std.mem.tokenizeAny(u8, fileContent, ",\r\n");
    var sum: usize = 0;
    while (it.next()) |ranges| {
        const searchRange: SearchRange = try SearchRange.init(ranges);
        // searchRange.printInt();
        var seenNumbers = std.AutoHashMap(usize, void).init(alloc);
        defer seenNumbers.deinit();
        sum += try findRepetitions(searchRange, null, &seenNumbers);
    }
    return sum;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const inputFile = "./input/02.txt";

    var buffer: [1024]u8 = undefined;
    var gpa = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = gpa.allocator();
    defer gpa.reset();

    const content = try std.Io.Dir.cwd().readFileAlloc(io, inputFile, allocator, .unlimited);
    defer allocator.free(content);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const arenaAllocator = arena.allocator();

    std.debug.print("--- Part 1 ---\n", .{});
    var sum = try firstPart(content, arenaAllocator);
    std.debug.print("Sum: {d}\n", .{sum});
    std.debug.print("--- Part 2 ---\n", .{});
    sum = try secondPart(content, arenaAllocator);
    std.debug.print("Sum: {d}\n", .{sum});
}
