const std = @import("std");

const ParseError = error{
    MissingLowerBound,
    MissingUpperBound,
};

const SearchRange = struct {
    upperStr: []const u8,
    upper: usize,
    lowerStr: []const u8,
    lower: usize,

    boundRange: usize = 0,
    possibleRepetitions: std.ArrayListUnmanaged(usize),

    pub fn init(self: *SearchRange, ranges: []const u8) !void {
        var it = std.mem.tokenizeScalar(u8, ranges, '-');
        self.lowerBound = it.next().?;
        self.upperBound = it.next().?;
        self.intLowerBound = try std.fmt.parseInt(usize, self.lowerBound, 10);
        self.intUpperBound = try std.fmt.parseInt(usize, self.upperBound, 10);
        try self.getDividers();
        return self.*;
    }

    pub fn getDividers(self: *SearchRange) !void {
        for (self.lowerBound.len..self.upperBound.len + 1) |value| {
            for (1..value) |index| {
                if (@rem(value, index) == 0) {
                    self.possibleRepetitions[self.boundRange][self.repetitionsSizes[self.boundRange]] = index;
                    self.repetitionsSizes[self.boundRange] += 1;
                }
            }
            self.boundRange += 1;
        }
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

fn firstPart(fileContent: []u8) !void {
    var it = std.mem.tokenizeAny(u8, fileContent, ",\r\n");
    while (it.next()) |ranges| {
        var range: SearchRange = .{};
        try range.init(ranges);
    }
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const inputFile = "./input/test/02.txt";

    var buffer: [1024]u8 = undefined;
    var gpa = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = gpa.allocator();
    defer gpa.reset();

    const file = try std.Io.Dir.openFile(std.Io.Dir.cwd(), io, inputFile, .{});
    defer file.close(io);

    const content = try std.Io.Dir.cwd().readFileAlloc(io, inputFile, allocator, .unlimited);
    defer allocator.free(content);

    std.debug.print("--- Part 1 ---\n", .{});
    try firstPart(content);
    // std.debug.print("Sum: {d}\n", .{sum});
    std.debug.print("--- Part 2 ---\n", .{});
}
