const std = @import("std");

// oniguruma.zig
const c = @cImport({
    @cInclude("oniguruma.h");
});

pub const Error = error{
    Invalid,
};

pub fn compile(allocator: std.mem.Allocator, pattern: [:0]const u8) !Matcher {
    var encondings = try allocator.alloc(c.OnigEncoding, 1);
    errdefer allocator.free(encondings);

    encondings[0] = &c.OnigEncodingASCII;

    var res = c.onig_initialize(encondings.ptr, 1);
    if (res != c.ONIG_NORMAL) {
        return Error.Invalid;
    }

    const regex = try allocator.create(c.OnigRegex);
    errdefer allocator.destroy(regex);

    const errorInfos = try allocator.create(c.OnigErrorInfo);
    errdefer allocator.destroy(errorInfos);

    res = c.onig_new(regex, pattern.ptr, pattern.ptr + pattern.len, c.ONIG_OPTION_DEFAULT, c.ONIG_ENCODING_ASCII(), c.ONIG_SYNTAX_DEFAULT(), errorInfos);
    if (res != c.ONIG_NORMAL) {
        return Error.Invalid;
    }

    const region = c.onig_region_new();

    return Matcher{
        .allocator = allocator,
        .encondings = encondings.ptr,
        .regex = regex,
        .errorInfos = errorInfos,
        .region = region,
    };
}

pub const Matcher = struct {
    const Self = @This();

    allocator: std.mem.Allocator,

    encondings: [*]c.OnigEncoding,
    regex: *c.OnigRegex,
    errorInfos: *c.OnigErrorInfo,
    region: [*]c.OnigRegion,

    pub fn deinit(self: *Self) void {
        c.onig_region_free(self.region, 1);
        c.onig_free(self.regex.*);
        _ = c.onig_end();

        self.allocator.free(self.encondings[0..1]);
        self.allocator.destroy(self.regex);
        self.allocator.destroy(self.errorInfos);
        self.allocator.free(self.region[0..1]);
    }

    pub fn match(self: *Self, input: [:0]const u8) bool {
        const r = c.onig_search(self.regex.*, input.ptr, input.ptr + input.len, input.ptr, input.ptr + input.len, self.region, c.ONIG_OPTION_DEFAULT);
        if (r == c.ONIG_MISMATCH) {
            return false;
        }
        return true;
    }

    pub fn matchGroup(self: *Self, input: [:0]const u8) ?Group {
        const r = c.onig_search(self.regex.*, input.ptr, input.ptr + input.len, input.ptr, input.ptr + input.len, self.region, c.ONIG_OPTION_DEFAULT);
        if (r == c.ONIG_MISMATCH) {
            return null;
        }
        return Group{ .region = self.region[0] };
    }
};

pub const Group = struct {
    region: c.OnigRegion,

    pub fn groups(self: Group) usize {
        return @as(usize, @intCast(self.region.num_regs));
    }

    pub fn findAll(self: Group) [][2]usize {
        const reg = self.region;
        const size = @as(usize, @intCast(reg.num_regs));

        var matrix: [std.math.maxInt(u16)][2]usize = undefined;

        for (0..size) |i| {
            const start = @as(usize, @intCast(reg.beg[i]));
            const end = @as(usize, @intCast(reg.end[i]));
            matrix[i] = [2]usize{ start, end };
        }
        return matrix[0..size];
    }

    pub fn findIndex(self: Group, index: usize) ?[2]usize {
        const reg = self.region;
        const size = @as(usize, @intCast(reg.num_regs));

        if (index >= size) return null;

        const start = @as(usize, @intCast(reg.beg[index]));
        const end = @as(usize, @intCast(reg.end[index]));
        return [2]usize{ start, end };
    }
};
