const w4 = @import("w4");
const Game = @import("Game");

freq1: u32,
freq2: u32,
attack: u32,
decay: u32,
sustain: u32,
release: u32,
volume: u32,
channel: u32,
mode: u32,

pub fn init(
    freq1: u32,
    freq2: u32,
    attack: u32,
    decay: u32,
    sustain: u32,
    release: u32,
    volume: u32,
    channel: u32,
    mode: u32,
) @This() {
    return .{
        .freq1 = freq1,
        .freq2 = freq2,
        .attack = attack,
        .decay = decay,
        .sustain = sustain,
        .release = release,
        .volume = volume,
        .channel = channel,
        .mode = mode,
    };
}

pub fn manySounds(sounds: []@This()) void {
    for (sounds) |s| {
        playSound(s.freq1, s.freq2, s.attack, s.decay, s.sustain, s.release, s.volume, s.channel, s.mode);
    }
}

pub fn playSound(s: @This()) void {
    const freq = s.freq1 | s.freq2 << 16;
    const duration = s.attack << 24 | s.decay << 16 | s.sustain | s.release << 8;
    const flags = s.channel | s.mode << 2;

    w4.tone(freq, duration, s.volume, flags);
}
