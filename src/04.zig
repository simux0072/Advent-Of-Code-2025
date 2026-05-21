const std = @import("std");

const positions = enum {
    TopLeft,
    TopRight,
    BottomLeft,
    BottomRight,
    Top,
    Bottom,
    Left,
    Right,
    Middle,
};

const Grid = struct {
    height: usize = undefined,
    width: usize = undefined,
    data: []u8,
    available: usize = 0,

    pub fn init(data: []u8) Grid {
        var self = Grid{
            .data = data,
        };
        self.getDimensions();
        return self;
    }

    pub fn getDimensions(self: *Grid) void {
        for (self.data, 0..) |byte, index| {
            if (byte == '\n') {
                self.width = index;
                break;
            }
        }
        self.height = (self.data.len + 1) / (self.width + 1);
    }

    pub fn findAvailable(self: *Grid, surroundNumber: usize, removeFreed: bool) usize {
        var available: usize = 0;
        var index: usize = 0;
        for (self.data, 0..) |byte, trueIndex| {
            var currentSurround: usize = 0;
            switch (byte) {
                '@' => {
                    // X - Width; Y - Height
                    const coordinates: [2]usize = [2]usize{ @as(usize, @intCast(@rem(index, self.width))), index / self.width };
                    currentSurround = self.getNeighbours(coordinates);
                    index += 1;
                    if (currentSurround >= surroundNumber) continue;
                    available += 1;
                    if (removeFreed == false) continue;
                    self.data[trueIndex] = '.';
                },
                '.' => {
                    index += 1;
                    continue;
                },
                else => continue,
            }
        }
        return available;
    }

    pub fn getNeighbours(self: *Grid, coordinates: [2]usize) usize {
        const directions = [_][2]isize{ .{ -1, -1 }, .{ 0, -1 }, .{ 1, -1 }, .{ -1, 0 }, .{ 1, 0 }, .{ -1, 1 }, .{ 0, 1 }, .{ 1, 1 } };
        var currentSurround: usize = 0;
        for (directions) |dir| {
            const xCoordinate = @as(isize, @intCast(coordinates[0])) + dir[0];
            const yCoordenate = @as(isize, @intCast(coordinates[1])) + dir[1];
            if (xCoordinate < 0 or yCoordenate < 0 or xCoordinate >= @as(isize, @intCast(self.width)) or yCoordenate >= @as(i32, @intCast(self.height))) continue;
            if (self.data[(self.width + 1) * @as(usize, @intCast(yCoordenate)) + @as(usize, @intCast(xCoordinate))] == '@') currentSurround += 1;
        }
        return currentSurround;
    }

    pub fn findAllPossibleRemovals(self: *Grid, surroundNumber: usize) usize {
        var available = self.findAvailable(surroundNumber, true);
        var allRemoved = available;
        while (available != 0) {
            available = self.findAvailable(surroundNumber, true);
            allRemoved += available;
        }
        return allRemoved;
    }
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const inputFile = "src/input/04.txt";

    var arenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arenaAllocator.allocator();
    defer arenaAllocator.deinit();

    const content = try std.Io.Dir.cwd().readFileAlloc(io, inputFile, allocator, .unlimited);
    defer allocator.free(content);

    var grid = Grid.init(content);

    std.debug.print("--- First Part ---\n", .{});
    const available = grid.findAvailable(4, false);
    std.debug.print("Available: {d}\n", .{available});
    std.debug.print("--- Second Part ---\n", .{});
    const allRemoved = grid.findAllPossibleRemovals(4);
    std.debug.print("Number of Rolls removed: {d}\n", .{allRemoved});
}

test "Grid.getDimensions" {
    var testInput = "1111\n2222\n3333\n4444\n5555".*;
    var testGrid = Grid{ .data = &testInput };
    testGrid.getDimensions();
    try std.testing.expectEqual(4, testGrid.width);
    try std.testing.expectEqual(5, testGrid.height);

    var testTwoInput = "..@..\n@@.@@\n@@@@.\n@.@.@".*;
    testGrid = Grid{ .data = &testTwoInput };
    testGrid.getDimensions();
    try std.testing.expectEqual(5, testGrid.width);
    try std.testing.expectEqual(4, testGrid.height);
}

test "Grid Init" {
    var testInput = "1111111\n2222222\n3333333\n4444444".*;
    const testGridOne = Grid.init(&testInput);
    try std.testing.expectEqualSlices(u8, &testInput, testGridOne.data);
    try std.testing.expectEqual(7, testGridOne.width);
    try std.testing.expectEqual(4, testGridOne.height);

    var testTwoInput = ".@.\n@@@\n@.@\n...".*;
    const testGridTwo = Grid.init(&testTwoInput);
    try std.testing.expectEqualSlices(u8, &testTwoInput, testGridTwo.data);
    try std.testing.expectEqual(3, testGridTwo.width);
    try std.testing.expectEqual(4, testGridTwo.height);
}

test "Get Neighbours" {
    // Test: Center
    var centerData = "@@@\n@@@\n@@@".*;
    var coordinates = [2]usize{ 1, 1 };
    var grid = Grid{ .height = 3, .width = 3, .data = &centerData };
    var surround = grid.getNeighbours(coordinates);
    try std.testing.expectEqual(8, surround);

    // Test: Center (not fully surrounded)
    var centerDataNFS = "@@@\n@@.\n@@@".*;
    coordinates = [2]usize{ 1, 1 };
    grid.data = &centerDataNFS;
    surround = grid.getNeighbours(coordinates);
    try std.testing.expectEqual(7, surround);

    // Test: Top middle
    var topMiddleData = "@@@\n@..\n@@@".*;
    coordinates = [2]usize{ 1, 0 };
    grid.data = &topMiddleData;
    surround = grid.getNeighbours(coordinates);
    try std.testing.expectEqual(3, surround);

    // Test: Top Right
    var topRightData = "@.@\n.@@\n@@@".*;
    coordinates = [2]usize{ 2, 0 };
    grid.data = &topRightData;
    surround = grid.getNeighbours(coordinates);
    try std.testing.expectEqual(2, surround);

    // Test: Top Left
    var topLeftData = "@.@\n@..\n@@@".*;
    coordinates = [2]usize{ 0, 0 };
    grid.data = &topLeftData;
    surround = grid.getNeighbours(coordinates);
    try std.testing.expectEqual(1, surround);

    // Test: Middle Left
    var middleLeftData = "@@@\n@@.\n@@@".*;
    coordinates = [2]usize{ 0, 1 };
    grid.data = &middleLeftData;
    surround = grid.getNeighbours(coordinates);
    try std.testing.expectEqual(5, surround);

    // Test: Middle Right
    var middleRightData = ".@.\n@@@\n@@@".*;
    coordinates = [2]usize{ 2, 1 };
    grid.data = &middleRightData;
    surround = grid.getNeighbours(coordinates);
    try std.testing.expectEqual(4, surround);

    // Test: Bottom Left
    var bottomLeftData = "@.@\n@@.\n@@.".*;
    coordinates = [2]usize{ 0, 2 };
    grid.data = &bottomLeftData;
    surround = grid.getNeighbours(coordinates);
    try std.testing.expectEqual(3, surround);

    // Test: Bottom Middle
    var bottomMiddleData = "...\n...\n.@.".*;
    coordinates = [2]usize{ 1, 2 };
    grid.data = &bottomMiddleData;
    surround = grid.getNeighbours(coordinates);
    try std.testing.expectEqual(0, surround);

    // Test: Bottom Right
    var bottomRightData = "@@@\n@..\n@.@".*;
    coordinates = [2]usize{ 2, 2 };
    grid.data = &bottomRightData;
    surround = grid.getNeighbours(coordinates);
    try std.testing.expectEqual(0, surround);
}

test "Find Available" {
    var testOneData = "@@@.@\n@..@.\n@@.@@\n@@@..\n@.@.@\n@@@@@".*;
    var grid = Grid.init(&testOneData);
    var available = grid.findAvailable(4, false);
    try std.testing.expectEqual(10, available);

    var testTwoData = "@.@@..@@.@\n.@@.@@.@@.\n@@..@@..@@\n..@@..@@..\n@.@.@.@.@.\n.@.@.@.@.@\n@@@@....@@\n....@@@@..\n@@.@@.@@.@\n.@@.@@.@@.".*;
    grid = Grid.init(&testTwoData);
    available = grid.findAvailable(4, false);
    try std.testing.expectEqual(29, available);

    var testThreeData = "@.@.@\n.@.@.\n@@@.@\n..@@.\n@..@@".*;
    grid = Grid.init(&testThreeData);
    available = grid.findAvailable(4, false);
    try std.testing.expectEqual(8, available);

    var testFourData = "@@@...\n@@@...\n@@@...\n...@@.\n...@@.\n.....@".*;
    grid = Grid.init(&testFourData);
    available = grid.findAvailable(4, false);
    try std.testing.expectEqual(6, available);
}

test "Find All Possible Removals" {
    var testOneData = "@@@.@\n@..@.\n@@.@@\n@@@..\n@.@.@\n@@@@@".*;
    var grid = Grid.init(&testOneData);
    var possibleRemovals = grid.findAllPossibleRemovals(4);
    try std.testing.expectEqual(21, possibleRemovals);

    // X.XX..XX.X
    // .XX.XX.XX.
    // XX..XX..XX
    // ..XX..XX..
    // X.X.X.X.X.
    // .X.X.X.X.X
    // XXXX....XX
    // ....XXXX..
    // XX.XX.XX.X
    // .XX.XX.XX.
    var testTwoData = "@.@@..@@.@\n.@@.@@.@@.\n@@..@@..@@\n..@@..@@..\n@.@.@.@.@.\n.@.@.@.@.@\n@@@@....@@\n....@@@@..\n@@.@@.@@.@\n.@@.@@.@@.".*;
    grid = Grid.init(&testTwoData);
    possibleRemovals = grid.findAllPossibleRemovals(4);
    try std.testing.expectEqual(55, possibleRemovals);
}

test "First Part" {
    const content = @embedFile("input/test/04.txt");

    const allocator = std.testing.allocator;
    const mutableContent = try allocator.dupe(u8, content);
    defer allocator.free(mutableContent);

    var grid = Grid.init(mutableContent);
    const available = grid.findAvailable(4, false);

    try std.testing.expectEqual(13, available);
}

test "Second Part" {
    const content = @embedFile("input/test/04.txt");

    var allocator = std.testing.allocator;

    const mutableContent = try allocator.dupe(u8, content);
    defer allocator.free(mutableContent);

    var grid = Grid.init(mutableContent);
    const allRemoved = grid.findAllPossibleRemovals(4);

    try std.testing.expectEqual(43, allRemoved);
}
