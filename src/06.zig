const std = @import("std");

const MathProblemType = enum {
    Multiply,
    Sum,
};

const HomeWork = struct {
    problems: std.ArrayList(usize),
    symbols: std.ArrayList(MathProblemType),
    allocator: std.mem.Allocator,
    numProblems: usize,
    numRows: usize,
    sum: usize,

    fn completeHomeWork(self: *HomeWork) void {
        for (0..self.numProblems) |numIndex| {
            var newNum: usize = 0;
            for (0..self.numRows - 1) |rowIndex| {
                switch (self.symbols.items[numIndex]) {
                    MathProblemType.Sum => newNum += self.problems.items[numIndex + rowIndex * self.numProblems],
                    MathProblemType.Multiply => {
                        if (newNum == 0) {
                            newNum = self.problems.items[numIndex];
                        } else {
                            newNum *= self.problems.items[numIndex + rowIndex * self.numProblems];
                        }
                    },
                }
            }
            self.sum += newNum;
        }
    }

    fn deinit(self: *HomeWork) void {
        self.problems.deinit(self.allocator);
        self.symbols.deinit(self.allocator);
    }
};

fn readHomeWork(content: []const u8, allocator: std.mem.Allocator) !HomeWork {
    var homeWork: HomeWork = .{ .sum = 0, .numProblems = 0, .numRows = 0, .problems = .empty, .symbols = .empty, .allocator = allocator };
    var number = std.ArrayList(u8).empty;
    var numStarted: bool = false;
    for (content) |char| {
        switch (char) {
            '\n' => {
                homeWork.numRows += 1;
                if (numStarted) {
                    numStarted = false;
                    try homeWork.problems.append(homeWork.allocator, try std.fmt.parseInt(usize, number.items, 10));
                    number.deinit(homeWork.allocator);
                    number = .empty;
                }
            },
            '*' => {
                try homeWork.symbols.append(homeWork.allocator, MathProblemType.Multiply);
                homeWork.numProblems += 1;
            },
            '+' => {
                try homeWork.symbols.append(homeWork.allocator, MathProblemType.Sum);
                homeWork.numProblems += 1;
            },
            ' ' => {
                if (numStarted) {
                    numStarted = false;
                    try homeWork.problems.append(homeWork.allocator, try std.fmt.parseInt(usize, number.items, 10));
                    number.deinit(homeWork.allocator);
                    number = .empty;
                }
            },
            else => |c| {
                numStarted = true;
                try number.append(homeWork.allocator, c);
            },
        }
    }
    defer number.deinit(homeWork.allocator);
    return homeWork;
}

fn readHomeWorkDown(content: []const u8, allocator: std.mem.Allocator) !void {
    var homeWork = HomeWork{ .sum = 0, .numProblems = 0, .numRows = 0, .problems = .empty, .symbols = .empty, .allocator = allocator };
    const count = std.mem.count(u8, content, '\n') + 1;
    const buffer = try allocator.alloc([]const u8, count);
    defer allocator.free(buffer);
    var iter = std.mem.tokenizeScalar(u8, content, '\n');
    var index: usize = 0;
    while (iter.next()) |line| : (index += 1) {
        buffer[index] = line;
    }
    var number = std.ArrayList(u8).empty;
    for (0..buffer[0].len) |charIndex| {}
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const inputFile = "src/input/06.txt";

    const content = try std.Io.Dir.cwd().readFileAlloc(io, inputFile, init.gpa, .unlimited);
    defer init.gpa.free(content);

    std.debug.print("--- Part 1 ---\n", .{});
    var homeWork = try readHomeWork(content, init.gpa);
    defer homeWork.deinit();
    homeWork.completeHomeWork();
    std.debug.print("Sum: {d}\n", .{homeWork.sum});
}

test "Read HomeWork" {
    const content = @embedFile("input/test/06.txt");

    const testOneProblems = [_]usize{ 123, 328, 51, 64, 45, 64, 387, 23, 6, 98, 215, 314 };
    const testOneSymbols = [_]MathProblemType{
        MathProblemType.Multiply,
        MathProblemType.Sum,
        MathProblemType.Multiply,
        MathProblemType.Sum,
    };

    var homeWork = try readHomeWork(content, std.testing.allocator);
    defer homeWork.deinit();

    try std.testing.expectEqual(4, homeWork.numProblems);
    try std.testing.expectEqual(4, homeWork.numRows);
    try std.testing.expectEqualSlices(usize, &testOneProblems, homeWork.problems.items);
    try std.testing.expectEqualSlices(MathProblemType, &testOneSymbols, homeWork.symbols.items);
}

test "Part 1" {
    const content = @embedFile("input/test/06.txt");

    var homeWork = try readHomeWork(content, std.testing.allocator);
    defer homeWork.deinit();

    homeWork.completeHomeWork();

    try std.testing.expectEqual(4277556, homeWork.sum);
}
