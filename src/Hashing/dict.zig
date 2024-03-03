const std = @import("std");
const autoHash = std.hash.autoHash;
const Wyhash = std.hash.Wyhash;
pub fn HashMap(
    comptime K: type,
    comptime V: type,
) type {
    return struct {

        // ---------------------------DECLARATION OF CONST VALUES---------------------------
        const Self = @This();
        const DICT_OK = 0;
        const DICT_ERR = 1;
        const DICT_HT_INITIAL_SIZE: u32 = 16;
        // ---------------------------DECLARATION OF CONST VALUES---------------------------

        // ---------------------------DECLARATION OF STRCUTS---------------------------

        pub const DictEntry = struct {
            key: *K,
            val: *V,
            next: ?*DictEntry,
        };

        pub const Dict = struct {
            table: ?[]?*DictEntry = null,
            size: u32,
            sizemask: u32,
            used: u32,
        };

        const DictIterator = struct {
            ht: ?*Dict,
            index: i32,
            entry: ?*DictEntry,
            nextEntry: ?*DictEntry,
        };

        // ---------------------------DECLARATION OF STRCUTS---------------------------

        // ---------------------------CREATION OF HASH TABLE---------------------------

        pub fn _dictReset(ht: ?*Dict) !void {
            ht.?.size = 0;
            ht.?.sizemask = 0;
            ht.?.used = 0;
        }

        pub fn _dictInit(ht: ?*Dict) !i8 {
            try _dictReset(ht);
            return DICT_OK;
        }

        pub fn CreateHashMap() !?*Dict {
            const allocator = std.heap.page_allocator;

            const htt = try allocator.create(Dict);
            var ht: ?*Dict = @ptrCast(htt);
            _ = try _dictInit(ht);
            ht.?.used = 0;
            return ht;
        }

        // ---------------------------CREATION OF HASH TABLE---------------------------

        // ---------------------------OPERATIONS ON HASH TABLES---------------------------

        pub fn uint32(input: u32) u32 {
            var x: u32 = input;
            x ^= x >> 16;
            x *%= 0x7feb352d;
            x ^= x >> 15;
            x *%= 0x846ca68b;
            x ^= x >> 16;
            return x;
        }

        fn hash(key: K) !u32 {
            if (std.meta.hasUniqueRepresentation(K)) {
                return @truncate(Wyhash.hash(0, std.mem.asBytes(&key)));
            } else {
                var hasher = Wyhash.init(0);
                autoHash(&hasher, key);
                return @truncate(hasher.final());
            }
        }

        pub fn dictHashKey(ht: ?*Dict, key: *K) !u32 {
            _ = ht;
            // const val: u32 = @intCast(key.*); //using casting
            // return uint32(val);
            return hash(key.*);
        }

        fn dictNextPower(size: u32) u32 {
            var i: u32 = DICT_HT_INITIAL_SIZE;

            if (size >= 2147483648) {
                return 2147483648;
            }

            while (true) {
                if (i >= size) {
                    return i;
                }
                i *= 2;
            }
        }

        pub fn dictExpand(ht: ?*Dict, size: u32) !i8 {
            var n: Dict = undefined; // the new hashtable
            const realsize: u32 = dictNextPower(size);

            // the size is invalid if it is smaller than the number of elements already inside the hashtable
            if (ht.?.used > size) {
                return DICT_ERR;
            }

            // // Initialize the new hashtable

            n.size = realsize;
            n.sizemask = realsize - 1;

            const allocator = std.heap.page_allocator;
            const array = try allocator.alloc(*DictEntry, realsize);

            // std.debug.print("type 1 {} \n", .{@TypeOf(array)});

            n.table = @ptrCast(array);

            // std.debug.print("type 2 {} \n", .{@TypeOf(n.table)});

            for (0..realsize) |i| {
                n.table.?[i] = null;
            }

            // // Copy all the elements from the old to the new table
            // // Note that if the old hash table is empty ht.size is zero, so dictExpand just creates a new hash table.
            n.used = ht.?.used;

            for (0..ht.?.size) |i| {
                var he: ?*DictEntry = n.table.?[i];
                var nextHe: ?*DictEntry = null;

                if (he == null) {
                    continue;
                }

                while (he != null) {
                    const vaa: u32 = try dictHashKey(ht, he.?.key);
                    const h: u32 = vaa & n.sizemask;
                    nextHe = he.?.next;
                    he.?.next = n.table.?[h];
                    n.table.?[h] = he;
                    ht.?.used -= 1;
                    // Pass to the next element
                    he = nextHe;
                }
                if (ht.?.used == 0) {
                    break;
                }
            }

            ht.?.* = n;

            return DICT_OK;
        }

        pub fn dictCompareHashKeys(ht: ?*Dict, key1: *K, key2: *K) !bool {
            _ = ht;
            return std.meta.eql(key1.*, key2.*);
            // return key1.* == key2.*;
        }

        pub fn dictKeyIndex(ht: ?*Dict, key: *K) !i32 {
            var h: u32 = undefined;
            var he: ?*DictEntry = undefined;

            // // /* Compute the key hash value */
            const vv: u32 = try dictHashKey(ht, key);
            h = vv & ht.?.sizemask;

            // /* Search if this slot does not already contain the given key */

            if (ht.?.table.?[h] != null) {
                he = ht.?.table.?[h];
                while (he != null) {
                    if (try dictCompareHashKeys(ht, key, he.?.key)) {
                        return -1;
                    }
                    if (he.?.next != undefined) {
                        he = he.?.next;
                    } else {
                        break;
                    }
                }
            }

            return @intCast(h);
        }

        pub fn dictAdd(ht: ?*Dict, key: *K, val: *V) !i8 {
            var index: i32 = undefined;
            var entry: ?*DictEntry = null;

            // /* Get the index of the new element, or -1 if
            //  * the element already exists. */

            var chec: i8 = 0;

            if (ht.?.size == 0) {
                chec = try dictExpand(ht, DICT_HT_INITIAL_SIZE);
            }
            if (ht.?.used == ht.?.size) {
                chec = try dictExpand(ht, ht.?.size * 2);
            }

            if (chec == DICT_ERR) {
                return DICT_ERR;
            }
            // std.debug.print("flag1 \n", .{});
            index = try dictKeyIndex(ht, key);
            if (index == -1) {
                return DICT_ERR;
            }

            const allocator = std.heap.page_allocator;

            const entr = try allocator.create(*DictEntry);
            entry = @ptrCast(entr);

            const indexcast: usize = @intCast(index);

            entry.?.next = ht.?.table.?[indexcast];
            ht.?.table.?[indexcast] = entry;

            // std.debug.print("type 1 {} \n", .{@TypeOf(ht.table[indexcast])});

            // /* Set the hash entry fields. */
            entry.?.key = key;
            entry.?.val = val;
            ht.?.used += 1;

            return DICT_OK;
        }

        pub fn dictFind(ht: ?*Dict, key: *K) !?*DictEntry {
            var he: ?*DictEntry = undefined;
            var h: u32 = undefined;

            if (ht.?.size == 0) {
                return null;
            }
            const vv: u32 = try dictHashKey(ht, key);
            h = vv & ht.?.sizemask;

            // std.debug.print("find {} {} {} \n", .{ h, vv, ht.?.sizemask });

            he = ht.?.table.?[h];

            while (he != null) {
                if (try dictCompareHashKeys(ht, key, he.?.key)) {
                    return he;
                }
                if (he.?.next != null) {
                    he = he.?.next;
                } else {
                    break;
                }
            }

            return null;
        }

        pub fn dictGenericDelete(ht: ?*Dict, key: *K, nofree: bool) !bool {
            var h: usize = 0;
            var he: ?*DictEntry = null;
            var prevHe: ?*DictEntry = null;

            if (ht.?.size == 0) {
                return false;
            }
            const vv: u32 = try dictHashKey(ht, key);
            h = vv & ht.?.sizemask;

            // std.debug.print("del {} {} {} \n", .{ h, vv, ht.?.sizemask });

            if (ht.?.table.?[h] == null) {
                return false;
            }

            he = ht.?.table.?[h];

            while (he != null) {
                if (try dictCompareHashKeys(ht, key, he.?.key)) {

                    // Unlink the element from the list

                    if (prevHe == null) {
                        ht.?.table.?[h] = he.?.next;
                    } else {
                        prevHe.?.next = he.?.next;
                    }

                    if (!nofree) {
                        // std.debug.print("{}",)
                        // dictFreeEntryKey(ht, he);
                        // dictFreeEntryVal(ht, he);
                    }

                    ht.?.used -= 1;
                    return true;
                }

                // std.debug.print("checkk \n", .{});

                if (he.?.next != null) {
                    he = he.?.next;
                } else {
                    break;
                }

                prevHe = he;
            }
            return false; // not found
        }

        pub fn dictDelete(ht: ?*Dict, key: *K) !bool {
            const ch = try dictGenericDelete(ht, key, false);
            return ch;
        }

        pub fn dictDeleteNoFree(ht: ?*Dict, key: *K) !bool {
            const ch = try dictGenericDelete(ht, key, true);
            return ch;
        }

        pub fn dictUpdate(ht: ?*Dict, key: *K, val: *V) !bool {
            const dictentr: ?*DictEntry = try dictFind(ht, key);

            if (dictentr == null) {
                return false;
            }

            dictentr.?.*.val = val;

            return true;
        }

        pub fn Add(ht: ?*Dict, key: K, val: V) !void {
            const check = try dictAdd(ht, @constCast(&key), @constCast(&val));

            if (check == DICT_OK) {
                return;
            } else {
                std.debug.print("ERROR 1", .{});
            }
        }

        pub fn Get(ht: ?*Dict, key: K) !V {
            const find = try dictFind(ht, @constCast(&key));
            if (find == null) {
                std.debug.print(" \n ERROR 2 \n", .{});
                return undefined;
            }
            return find.?.val.*;
        }

        pub fn Update(ht: ?*Dict, key: K, val: V) !void {
            const check = try dictUpdate(ht, @constCast(&key), @constCast(&val));
            if (check == false) {
                std.debug.print("ERROR 3", .{});
                return;
            }
            return;
        }

        pub fn Delete(ht: ?*Dict, key: K) !void {
            const check = try dictDelete(ht, @constCast(&key));
            if (check == false) {
                std.debug.print("ERROR 4", .{});
                return;
            }
            return;
        }
        pub fn dictResize(ht: ?*Dict) !void {
            var minimal: usize = ht.?.used;

            if (minimal < DICT_HT_INITIAL_SIZE) {
                minimal = DICT_HT_INITIAL_SIZE;
            }
            try dictExpand(ht, minimal);
        }
        // pub fn dictClear(ht: ?*Dict) !void {
        //     var i: u32 = 0;
        //     while (i < ht.?.size) {
        //         if (ht.?.used <= 0) {
        //             break;
        //         }
        //         // const index:usize=
        //         var he: ?*DictEntry = ht.?.table.?[(@intCast(i))];
        //         if (he == null) {
        //             i += 1;
        //             continue;
        //         }
        //         while (he != null) {
        //             const nextHe = he.?.next;

        //             const tempptr = he;

        //             const allocator = std.heap.page_allocator;

        //             defer allocator.destroy(tempptr);

        //             ht.?.used -= 1;
        //             he = nextHe;
        //         }
        //         i += 1;
        //     }

        //     const allocator = std.heap.page_allocator;
        //     defer allocator.free(ht.?.table);

        //     // try _dictReset(ht);
        // }

        pub fn dictGetIterator(ht: ?*Dict) !?*DictIterator {
            const allocator = std.heap.page_allocator;
            const itr = try allocator.create(DictIterator);
            const iter: ?*DictIterator = @ptrCast(itr);
            iter.?.ht = ht;
            iter.?.index = -1;
            iter.?.entry = null;
            iter.?.nextEntry = null;
            return iter;
        }

        pub fn dictGetRandomKey(ht: ?*Dict) !?*DictEntry {
            var he: ?*DictEntry = null;
            var h: u32 = undefined;
            var listlen: i32 = 0;
            var listele: i32 = 0;
            var index: usize = 0;

            if (ht.?.size == 0) {
                return null;
            }

            var prng = std.rand.DefaultPrng.init(blk: {
                var seed: u64 = undefined;
                try std.os.getrandom(std.mem.asBytes(&seed));
                break :blk seed;
            });
            const rand = prng.random();

            while (true) {
                const h1 = rand.int(u32);
                h = h1 & ht.?.sizemask;
                index = @intCast(h);
                he = ht.?.table.?[index];
                if (he != null) {
                    break;
                }
            }

            while (he != null) {
                he = he.?.next;
                listlen += 1;
            }

            const c = rand.int(i32);

            listele = @mod(c, listlen);
            he = ht.?.table.?[index];
            while (listele > 0) {
                he = he.?.next;
                listele -= 1;
            }

            return he;
        }
    };
}