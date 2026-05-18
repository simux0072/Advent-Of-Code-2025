const std = @import("std");

fn reduceNumber(rotNum: *usize, base: usize, numZerosTotal: *usize) void {
    if (rotNum.* >= base) {
        const reduction = rotNum.* / base;
        rotNum.* -= base * reduction;
        numZerosTotal.* += reduction;
    }
}

pub fn main(init: std.process.Init) !void {
    const fileName = "01.txt";
    const fileLocation = "./input/test";

    var rotNum: usize = 50;
    const base = 100;

    const io = init.io;
    const cwd = std.Io.Dir.cwd();

    const input_dir = try cwd.openDir(io, fileLocation, .{});
    defer input_dir.close(io);

    const file = try input_dir.openFile(io, fileName, .{});
    defer file.close(io);

    var lineContent: [10]u8 = undefined;

    var fileReader = file.reader(io, &lineContent);
    const reader = &fileReader.interface;

    var numZerosFromExact: usize = 0;
    var numZerosTotal: usize = 0;

    while (reader.takeDelimiterExclusive('\n')) |value| {
        reader.toss(1);

        var rot = try std.fmt.parseInt(usize, value[1..], 10);

        switch (value[0]) {
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
        if (rotNum == 0) {
            numZerosFromExact += 1;
        } else {
            continue;
        }
    } else |_| {
        std.debug.print("Finished task!\n--- PART 1 ---\nNumber of Zeros: {d}\n", .{numZerosFromExact});
        std.debug.print("--- PART 2 ---\nNumber of Zeros: {d}", .{numZerosTotal});
    }
}
