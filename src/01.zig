const std = @import("std");

fn reduceNumber(rotNum: *usize, base: usize, numZerosTotal: ?*usize) void {
    if (rotNum.* >= base) {
        const reduction = rotNum.* / base;
        rotNum.* -= base * reduction;
        if (numZerosTotal != null) numZerosTotal.?.* += reduction;
    }
}

fn firstPart(content: []const u8, base: usize) !usize {
    var it = std.mem.tokenizeAny(u8, content, "\n\r");
    var rotNum: usize = 50;
    var numZerosFromExact: usize = 0;

    while (it.next()) |line| {
        var rot = try std.fmt.parseInt(usize, line[1..], 10);
        reduceNumber(&rot, base, null);
        switch (line[0]) {
            'L' => {
                switch (rotNum > rot) {
                    true => rotNum -= rot,
                    false => {
                        rotNum += base - rot;
                        reduceNumber(&rotNum, base, null);
                    },
                }
            },
            'R' => {
                switch (rotNum + rot >= base) {
                    true => {
                        rotNum += rot;
                        reduceNumber(&rotNum, base, null);
                    },
                    else => rotNum += rot,
                }
            },
            else => return error.IncorrectFileFormatting,
        }
        if (rotNum == 0) {
            numZerosFromExact += 1;
        } else {
            continue;
        }
    }
    return numZerosFromExact;
}

fn secondPart(content: []const u8, base: usize) !usize {
    var it = std.mem.tokenizeAny(u8, content, "\n\r");

    var rotNum: usize = 50;
    var numZerosTotal: usize = 0;

    while (it.next()) |line| {
        var rot = try std.fmt.parseInt(usize, line[1..], 10);
        switch (line[0]) {
            'L' => {
                reduceNumber(&rot, base, &numZerosTotal);
                switch (rotNum > rot) {
                    true => rotNum -= rot,
                    false => {
                        if (rotNum != 0 and rot - rotNum != 0) {
                            numZerosTotal += 1;
                        }
                        rotNum += base - rot;
                        reduceNumber(&rotNum, base, &numZerosTotal);
                    },
                }
            },
            'R' => {
                reduceNumber(&rot, base, &numZerosTotal);
                switch (rotNum + rot >= base) {
                    true => {
                        rotNum += rot;
                        reduceNumber(&rotNum, base, &numZerosTotal);
                    },
                    else => rotNum += rot,
                }
            },
            else => return error.IncorrectFileFormatting,
        }
    }
    return numZerosTotal;
}

pub fn main(init: std.process.Init) !void {
    const inputFile = "src/input/01.txt";

    const io = init.io;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const content = try std.Io.Dir.cwd().readFileAlloc(io, inputFile, allocator, .unlimited);

    std.debug.print("--- Part 1 ---\n", .{});
    const numZerosFromExact = try firstPart(content, 100);
    std.debug.print("Number of Exact Zeros: {d}\n", .{numZerosFromExact});
    std.debug.print("--- Part 2 ---\n", .{});
    const numZerosTotal = try secondPart(content, 100);
    std.debug.print("Number of Zeros in Total: {d}\n", .{numZerosTotal});
}
