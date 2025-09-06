const w4 = @import("w4");

const Sound = struct {
    freq1: u8,
    freq2: u8,
    attack: u8,
    decay: u8,
    sustain: u8,
    release: u8,
    volume: u8,
    channel: u8,
    mode: u8,
};

pub fn playSound(
    freq1: u32,
    freq2: u32,
    attack: u32,
    decay: u32,
    sustain: u32,
    release: u32,
    volume: u32,
    channel: u32,
    mode: u32,
) void {
    const freq = freq1 | freq2 << 16;
    const duration = attack << 24 | decay << 16 | sustain | release << 8;
    const flags = channel | mode << 2;

    w4.tone(freq, duration, volume, flags);
}
