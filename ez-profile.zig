pub fn trace(loc: std.builtin.SourceLocation, comptime Id: type) Trace {
    _ = Id;

    const state = struct {
        const no_index = std.math.maxInt(usize);
        var index: usize = no_index;
    };

    if (state.index == state.no_index) {
        state.index = measurements.len;
        measurements.append(.{ .loc = loc }) catch @panic("Increase `max_measurements`");
    }

    return .{
        .index = state.index,
        .start = now(),
    };
}

fn now() std.time.Instant {
    return std.time.Instant.now() catch @panic("std.time.Instant.now() is unsupported");
}

const Trace = struct {
    index: usize,
    start: std.time.Instant,

    pub fn end(t: Trace) void {
        const n = now();
        const time = n.since(t.start);
        const measurement = &measurements.slice()[t.index];
        measurement.samples += 1;
        measurement.total_time += time;
        measurement.min_time = @min(measurement.min_time, time);
        measurement.max_time = @max(measurement.max_time, time);
    }
};

const log_scope = std.log.scoped(.ez_profile);

pub fn report() void {
    reportInner() catch |err| log_scope.err("{}", .{err});
}

fn reportInner() !void {
    const file = try std.fs.cwd().createFile("ez-profile-out.json", .{});
    defer file.close();

    var buffered_file = std.io.bufferedWriter(file.writer());

    try std.json.stringify(measurements.slice(), .{}, buffered_file.writer());
    try buffered_file.flush();
}

pub var measurements: std.BoundedArray(Measurement, max_measurements) = .{};

pub const Measurement = struct {
    loc: std.builtin.SourceLocation,
    samples: u32 = 0,
    min_time: u64 = std.math.maxInt(u64),
    max_time: u64 = 0,
    total_time: u64 = 0,
};

const ez_profile = @import("ez-profile.zig");

const root = @import("root");
const std = @import("std");

const max_measurements = if (@hasDecl(root, "max_measurements")) root.max_measurements else 1024;
