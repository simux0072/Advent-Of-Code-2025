const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const io = b.graph.io;

    const all_step = b.step("all", "Test, build, and run all Advent of Code days");
    const test_step = b.step("test", "Run tests for all src/*.zig files");
    const run_step = b.step("run", "Build and run all src/*.zig files");

    // Make plain `zig build` do everything.
    b.default_step = all_step;
    all_step.dependOn(test_step);
    all_step.dependOn(run_step);

    run_step.dependOn(test_step);
    var src_dir = std.Io.Dir.openDir(std.Io.Dir.cwd(), io, "src/", .{ .iterate = true }) catch |err| {
        std.debug.panic("failed to open src directory: {}", .{err});
    };
    defer src_dir.close(io);

    var zig_files = std.ArrayList([]const u8).empty;
    defer zig_files.deinit(b.allocator);

    var it = src_dir.iterate();
    while (it.next(io) catch |err| {
        std.debug.panic("failed to iterate src directory: {}", .{err});
    }) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".zig")) continue;

        const name_copy = b.dupe(entry.name);
        zig_files.append(b.allocator, name_copy) catch @panic("OOM");
    }

    std.mem.sort([]const u8, zig_files.items, {}, lessThanString);

    var previous_test: ?*std.Build.Step = null;
    var previous_run: ?*std.Build.Step = null;

    for (zig_files.items) |file_name| {
        const stem = file_name[0 .. file_name.len - ".zig".len];
        const src_path = b.fmt("src/{s}", .{file_name});

        // -----------------------------
        // Tests
        // -----------------------------

        const unit_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(src_path),
                .target = target,
                .optimize = optimize,
            }),
        });

        const run_tests = b.addRunArtifact(unit_tests);

        test_step.dependOn(&run_tests.step);
        previous_test = &run_tests.step;

        // -----------------------------
        // Executable
        // -----------------------------

        const exe = b.addExecutable(.{
            .name = b.fmt("aoc-{s}", .{stem}),
            .root_module = b.createModule(.{
                .root_source_file = b.path(src_path),
                .target = target,
                .optimize = optimize,
            }),
        });

        // Optional: install built binaries into zig-out/bin.
        b.installArtifact(exe);

        const run_banner = b.addSystemCommand(&.{
            "printf",
            b.fmt("\n========== Running: src/{s} ==========\n", .{file_name}),
        });

        if (previous_run) |prev| {
            run_banner.step.dependOn(prev);
        } else {
            run_banner.step.dependOn(test_step);
        }

        const run_exe = b.addRunArtifact(exe);
        run_exe.has_side_effects = true;
        run_exe.step.dependOn(&run_banner.step);

        // If your AoC programs expect argv[1] to be the input path, uncomment:
        //
        // run_exe.addFileArg(b.path(b.fmt("src/input/{s}.txt", .{stem})));
        //
        // If they read files themselves using relative paths like
        // "src/input/01.txt", leave this commented out.

        run_step.dependOn(&run_exe.step);
        previous_run = &run_exe.step;
    }
}

fn lessThanString(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.lessThan(u8, lhs, rhs);
}
