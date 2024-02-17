const std = @import("std");

const DICT_OK = 0;
const DICT_ERR = 1;

const DictEntry = struct {
    key: ?*void,
    val: ?*void,
    next: ?*DictEntry,
};

const Dict = struct {
    table: **DictEntry,
    Type: *DictType,
    size: u32,
    sizemask: u32,
    used: u32,
    privdata: ?*void,
};

const DictIterator = struct {
    ht: *Dict,
    index: i32,
    entry: *DictEntry,
    nextEntry: *DictEntry,
};

const DICT_HT_INITIAL_SIZE: u32 = 16;

// Function to compute the hash value for an integer key
pub fn dictIntHashFunction(ke: u32) u32 {
    var key: u32 = ke;
    key += (key << 15);
    key ^= (key >> 10);
    key += (key << 3);
    key ^= (key >> 6);
    key += (key << 11);
    key ^= (key >> 16);
    return key;
}

// -------------------------------------------------------TEST CHECK LEFT-----------------------------------------------------------------------------------------
const DictType = struct {
    hashFunction: fn (key: ?*const u8) u32,
    keyDup: fn (privdata: ?*void, key: ?*const u8) ?*void,
    valDup: fn (privdata: ?*void, obj: ?*const u8) ?*void,
    keyCompare: fn (privdata: ?*void, key1: ?*const u8, key2: ?*const u8) i32,
    keyDestructor: fn (privdata: ?*void, key: ?*const u8) void,
    valDestructor: fn (privdata: ?*void, obj: ?*const u8) void,
};

pub fn dictExpand(ht: *Dict, size: u32) c_int {
    var n: Dict = undefined; // the new hashtable
    const realsize: u32 = dictNextPower(size);
    var i: u32;

    // the size is invalid if it is smaller than the number of elements already inside the hashtable
    if (ht.used > size) {
        return DICT_ERR;
    }

    // Initialize the new hashtable
    _dictInit(&n, ht.type, ht.privdata);
    n.size = realsize;
    n.sizemask = realsize - 1;
    n.table = try _dictAlloc(realsize * @sizeOf(*DictEntry));

    // Initialize all the pointers to NULL
    std.mem.set(n.table, 0, realsize * @sizeOf(*DictEntry));

    // Copy all the elements from the old to the new table
    // Note that if the old hash table is empty ht.size is zero, so dictExpand just creates a new hash table.
    n.used = ht.used;
    for (i, ht.table) |slot| {
    var he: *DictEntry = slot;
    var nextHe: *DictEntry;

    if (he == null) {
        continue;
    }

    // For each hash entry on this slot...
    while (he != null) {
        const h: u32 = dictHashKey(ht, he.key) & n.sizemask;
        nextHe = he.next;
        he.next = n.table[h];
        n.table[h] = he;
        ht.used -= 1;
        // Pass to the next element
        he = nextHe;
    }
    if (ht.used == 0) {
        break; // Stop if all elements have been processed
    }
}

    std.debug.assert(ht.used == 0, "ht.used is not 0 after copy");

    _dictFree(ht.table);

    // Remap the new hashtable in the old
    ht.* = n;
    return DICT_OK;
}


pub fn dictKeyIndex(comptime T:type,ht: *Dict, key: T) i32 {
    var h: u32;
    var he: *DictEntry;

    // /* Expand the hashtable if needed */
    if (dictExpandIfNeeded(ht) == DICT_ERR) {
        return -1;
    }

    // /* Compute the key hash value */
    h = dictHashKey(ht, key) & ht.sizemask;

    // /* Search if this slot does not already contain the given key */
    he = ht.table[h];
    while (he != null) {
        if (dictCompareHashKeys(ht, key, he.key)) {
            return -1;
        }
        he = he.next;
    }

    return h;
}


pub fn dictAdd(comptime T1:type,comptime T2:type,ht: *Dict, key: T1, val: t2) i8 {
    var index: i8=undefined;
    var entry: *DictEntry=undefined;

    // /* Get the index of the new element, or -1 if
    //  * the element already exists. */
    const index = dictKeyIndex(t1,ht, key);
    if (index == -1) {
        return DICT_ERR;
    }

    // /* Allocates the memory and stores key */
    entry = try _dictAlloc(*DictEntry,@sizeOf(DictEntry));
    entry.next = ht.table[index];
    ht.table[index] = entry;

    // /* Set the hash entry fields. */
    dictSetHashKey(ht, entry, key);
    dictSetHashVal(ht, entry, val);
    ht.used += 1;
    return DICT_OK;
}

pub fn dictSetHashKey(comptime T:type,ht: *Dict, entry: *DictEntry, key: T) void {
    if (ht.Type.keyDup != null) {
        entry.key = ht.Type.keyDup(ht.privdata, key);
    } else {
        entry.key = key;
    }
}





// -------------------------------------------------------TEST CHECK LEFT-----------------------------------------------------------------------------------------


pub fn dictGenHashFunction(buf: []const u8, len: usize) u64 {
    var hash: u64 = 5381;

    var index: usize = 0;
    while (index < len) {
        hash = ((hash << 5) + hash) + buf[index];
        index += 1;
    }

    return hash;
}

pub fn _dictReset(ht: *Dict) void {
    ht.table = null;
    ht.size = 0;
    ht.sizemask = 0;
    ht.used = 0;
}

pub fn _dictInit(ht: *Dict, Type: *dictType, privDataPtr: void) i8 {
    _dictReset(ht);
    ht.Type = Type;
    ht.privdata = privDataPtr;
    return DICT_OK;
}

pub fn dictCreate(Type: *dictType, privDataPtr: void) !*Dict {
    var ht = try _dictAlloc(*Dict, @sizeOf(Dict));

    try _dictInit(ht, Type, privDataPtr);
    return ht;
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

pub fn dictExpandIfNeeded(ht: *Dict) i8 {
    if (ht.size == 0) {
        return dictExpand(ht, DICT_HT_INITIAL_SIZE);
    }
    if (ht.used == ht.size) {
        return dictExpand(ht, ht.size * 2);
    }
    return DICT_OK;
}

pub fn dictCompareHashKeys(comptime T: type,ht: *Dict, key1: T, key2: T) bool {
    if (ht.Type.keyCompare != null) {
        return ht.Type.keyCompare(ht.privdata, key1, key2);
    } else {
        // Assuming that the keys are pointers and we are doing a simple pointer comparison
        return key1 == key2;
    }
}

pub fn dictHashKey(comptime T: type,ht: *Dict, key:T) u32 {
    return ht.Type.hashFunction(T,key);
}






