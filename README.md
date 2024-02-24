<!---
README.md is autogenerated. Please edit example/README.md.template instead.
-->
# ez-profile

A small library for quick and dirty profiling. It's a single file, so you can just copy it into
your project to get started.

To use `ez-profile`, add the following lines to the functions you want to trace:
```zig
const trace = @import("ez-profile.zig").trace(@src(), opaque{});
defer trace.end();
```

And add the following line where you want `ez-profile` to report its measurements:
```zig
defer @import("ez-profile.zig").report();
```

You can also add it as a module in your `build.zig` and import it with `@import("ez-profile")` from
anywhere.

`ez-profile` outputs a small json file called `./ez-profile-out.json`. You can use command line
tools `jq` to get a table:

```
$ jq -r '(.[] | [(.loc | "\(.file):\(.line):\(.column): \(.fn_name)" ), .samples, .total_time]) | @tsv' ez-profile-out.json |
    sort -k3 -h |
    column -t -s "$(printf '\t')"
example/example.zig:20:28: createList                1  49464
example/example.zig:33:28: createListAssumeCapacity  1  15008
example/example.zig:47:28: sortItems                 2  180622
example/example.zig:54:28: printItems                2  1613993
```

Or simply paste the data into a website like https://www.convertjson.com/json-to-html-table.htm

## Example

```zig
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

```
