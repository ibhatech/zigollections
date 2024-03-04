const std = @import("std");
const expect = std.testing.expect;
const dict = @import("dict.zig");
const HashMap = dict.HashMap;

const mystr = struct { a: i32, b: bool };

test "Add #1" {
    const val = HashMap(bool, i32);
    const str = try val.CreateHashMap();
    const value: i32 = 10;
    try val.Add(str,true, value);
}

test "Add #2" {
    const val = HashMap(mystr, i32);
    const str = try val.CreateHashMap();
    std.debug.print("\n{}\n", .{@TypeOf(str)});
    const mystruct=mystr{
        .a=10,
        .b=true
    };
    const value:i32=10;
    try val.Add(str,mystruct, value);
}
