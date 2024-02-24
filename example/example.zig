const ez = @import("ez-profile");
const std = @import("std");

pub fn main() !void {
    defer ez.report();

    const list = try createList(std.heap.page_allocator);
    defer list.deinit();

    const list2 = try createListAssumeCapacity(std.heap.page_allocator);
    defer list2.deinit();

    sortItems(list.items);
    sortItems(list2.items);
    try printItems(list.items);
    try printItems(list2.items);
}

fn createList(alloctor: std.mem.Allocator) !std.ArrayList(usize) {
    const trace = ez.trace(@src(), opaque {});
    defer trace.end();

    var res = std.ArrayList(usize).init(alloctor);
    errdefer res.deinit();

    for (0..1024) |item|
        try res.append(item);

    return res;
}

fn createListAssumeCapacity(alloctor: std.mem.Allocator) !std.ArrayList(usize) {
    const trace = ez.trace(@src(), opaque {});
    defer trace.end();

    var res = std.ArrayList(usize).init(alloctor);
    errdefer res.deinit();

    try res.ensureTotalCapacityPrecise(1024);
    for (0..1024) |item|
        res.appendAssumeCapacity(item);

    return res;
}

fn sortItems(slice: []usize) void {
    const trace = ez.trace(@src(), opaque {});
    defer trace.end();

    std.sort.insertion(usize, slice, {}, std.sort.desc(usize));
}

fn printItems(slice: []usize) !void {
    const trace = ez.trace(@src(), opaque {});
    defer trace.end();

    const stdout = std.io.getStdOut();
    var buf_stdout = std.io.bufferedWriter(stdout.writer());
    const out = buf_stdout.writer();

    for (slice, 0..) |item, i|
        try out.print("[{}] = {}\n", .{ i, item });

    try buf_stdout.flush();
}
