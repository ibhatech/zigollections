const std = @import("std");
const expect = std.testing.expect;
const dict = @import("dict.zig");
const HashMap = dict.HashMap;

const mystr = struct { a: i32, b: bool };

test "Delete #1" {
    const val = HashMap(bool, i32);
    const str = try val.CreateHashMap();
    const value: i32 = 10;
    const mybool: bool = true;
    try val.Add(str, mybool, value);
    try val.Delete(str, mybool);
    const find = try val.Get(str, mybool);
    _=find;

}

test "Delete #2" {
    const val = HashMap(mystr, i32);
    const str = try val.CreateHashMap();
    const mystruct = mystr{ .a = 10, .b = true };
    const value: i32 = 10;
    try val.Add(str, mystruct, value);
    try val.Delete(str, mystruct);
    const find = try val.Get(str, mystruct);
    _=find;
}
