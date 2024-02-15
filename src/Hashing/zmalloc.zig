const std = @import("std");

var used_memory: usize = 0;

pub fn zmalloc(comptime T: type, size: T) !?[]u8 {
    const total_size: usize = size + @sizeOf(usize);
    const allocator = std.heap.page_allocator;
    const memory = try allocator.alloc(u8, total_size);
    used_memory += total_size;
    return memory;
}

pub fn zfree(ptr: []u8) !void {
    const allocator = std.heap.page_allocator;
    const val: usize = ptr.len;
    used_memory -= val;
    defer allocator.free(ptr);
    return;
}

pub fn zstrdup(s: []const u8) !?[]u8 {
    const l: usize = std.mem.len(s) + 1;
    const p = try zmalloc(l);
    std.mem.copy(p, s);
    return p;
}

pub fn zmalloc_used_memory(void) usize {
    return used_memory;
}
