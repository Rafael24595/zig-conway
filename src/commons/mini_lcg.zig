pub const MiniLCG = struct {
    seed: u64 = 1,

    pub fn init(seed: u64) @This() {
        return MiniLCG{ .seed = seed };
    }

    fn next(self: *@This()) u64 {
        const mul = @mulWithOverflow(self.seed, 1664525);
        const add = @addWithOverflow(mul[0], 1013904223);
        self.seed = add[0];
        return self.seed;
    }

    pub fn randInRange(self: *@This(), min: usize, max: usize) u8 {
        var rnd: u64 = self.next();

        rnd = ((rnd >> 16) ^ (rnd >> 8)) & 0xFFFF;

        const min64: u64 = @intCast(min);
        const max64: u64 = @intCast(max);

        const range: u64 = max64 - min64 + 1;
        const value: u64 = rnd % range;

        return @intCast(min64 + value);
    }

    pub fn float(self: *@This()) f32 {
        const rnd = self.next() >> 40;
        const rnd32: f32 = @floatFromInt(rnd);
        return rnd32 / (1 << 24);
    }
};
