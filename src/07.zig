const std = @import("std");

fn calcTachyonManifold(content: []const u8, allocator: std.mem.Allocator) !usize {
    var splitters: usize = 0;
    var iter = std.mem.tokenizeScalar(u8, content, '\n');
    const startLine = iter.next();

    if (startLine == null) return error.IterIsNull;
    var queue = try std.ArrayList(usize).initCapacity(allocator, startLine.?.len);
    defer queue.deinit(allocator);

    for (startLine.?, 0..) |char, index| {
        if (char == 'S') {
            queue.appendAssumeCapacity(index);
            break;
        }
    }

    while (iter.next()) |line| {
        var queueIndex: usize = queue.items.len;
        while (queueIndex > 0) : (queueIndex -= 1) {
            switch (line[queue.items[queueIndex - 1]]) {
                '.' => continue,
                '^' => {
                    splitters += 1;
                    if (queue.items.len == 1) {
                        queue.insertAssumeCapacity(queueIndex, queue.items[queueIndex - 1] + 1);
                        queue.items[queueIndex - 1] = queue.items[queueIndex - 1] - 1;
                        continue;
                    }
                    if (queueIndex == queue.items.len) {
                        queue.insertAssumeCapacity(queueIndex, queue.items[queueIndex - 1] + 1);
                    } else if (queue.items[queueIndex] != queue.items[queueIndex - 1] + 1) {
                        queue.insertAssumeCapacity(
                            queueIndex,
                            queue.items[queueIndex - 1] + 1,
                        );
                    }

                    if (queueIndex == 1) {
                        queue.items[queueIndex - 1] = queue.items[queueIndex - 1] - 1;
                    } else if (queue.items[queueIndex - 2] == queue.items[queueIndex - 1] - 1) {
                        _ = queue.orderedRemove(queueIndex - 1);
                    } else queue.items[queueIndex - 1] = queue.items[queueIndex - 1] - 1;
                },
                else => unreachable,
            }
        }
    }
    return splitters;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const inputFile = "src/input/07.txt";

    const content = try std.Io.Dir.cwd().readFileAlloc(io, inputFile, init.gpa, .unlimited);
    defer init.gpa.free(content);

    std.debug.print("--- Part 1 ---\n", .{});
    const splits = try calcTachyonManifold(content, init.gpa);
    std.debug.print("Splitters Encountered: {d}\n", .{splits});
    std.debug.print("--- Part 2 ---\n", .{});
}

test "Task 1" {
    const content = @embedFile("input/test/07.txt");

    const splits = calcTachyonManifold(content, std.testing.allocator);
    try std.testing.expectEqual(21, splits);
}
