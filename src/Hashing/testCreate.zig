const std = @import("std");
const expect = std.testing.expect;
const dict = @import("dict.zig");
const HashMap = dict.HashMap;

const mystr = struct { a: i32, b: bool };

test "Creation #1" {
    const val = HashMap(bool, i32);
    const str = try val.CreateHashMap();
    std.debug.print("\n{}\n", .{@TypeOf(str)});
}

test "Creation #2" {
    const val = HashMap(mystr, i32);
    const str = try val.CreateHashMap();
    std.debug.print("\n{}\n", .{@TypeOf(str)});
}

