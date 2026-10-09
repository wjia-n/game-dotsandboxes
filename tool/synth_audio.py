#!/usr/bin/env python3
"""Synthesize all SFX + music WAVs for Dots & Boxes (wooden toy box identity).

- Wooden knocks: decaying resonant partials (marimba-like: 1, ~4, ~10)
- Crayon scratches: stick-slip band-passed noise
- Music: gentle wooden-marimba loops (deterministic, loopable)
Output: assets/audio/*.wav, 22050 Hz mono 16-bit.
"""
import math, os, wave, struct, random

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "audio")
os.makedirs(OUT, exist_ok=True)
rng = random.Random(1234)

def save(name, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    gain = min(1.0, 0.85 / peak)
    frames = b"".join(struct.pack("<h", int(max(-1, min(1, s * gain)) * 32767)) for s in samples)
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(frames)
    print("wrote", name, f"{len(samples)/SR:.2f}s")

def wood_tone(freq, dur, vol=1.0, decay=6.0, partials=(1.0, 4.0, 10.0), pvol=(1.0, 0.35, 0.12)):
    """Marimba-ish wooden bar: sine partials with fast-decaying uppers + mallet noise tick."""
    n = int(SR * dur)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        env = math.exp(-t * decay)
        v = 0.0
        for p, pv in zip(partials, pvol):
            v += pv * math.sin(2 * math.pi * freq * p * t) * math.exp(-t * decay * (1 + p * 0.9))
        out[i] = vol * v * env
    # mallet tick
    tick = int(SR * 0.008)
    for i in range(min(tick, n)):
        out[i] += vol * 0.25 * (rng.random() * 2 - 1) * math.exp(-i / (SR * 0.003))
    return out

def mix(dst, src, at=0.0, vol=1.0):
    o = int(SR * at)
    need = o + len(src)
    if len(dst) < need:
        dst.extend([0.0] * (need - len(dst)))
    for i, s in enumerate(src):
        dst[o + i] += s * vol
    return dst

def midi(m):
    return 440.0 * 2 ** ((m - 69) / 12)

# ---------------- SFX ----------------
# click: short wooden UI tap
click = wood_tone(midi(88), 0.09, vol=0.5, decay=55)
save("click.wav", click)

# crayon: stick-slip scratch ~ bandpassed noise with AM wobble
def crayon(dur=0.22, base=3200.0):
    n = int(SR * dur)
    out = [0.0] * n
    lp = 0.0
    for i in range(n):
        t = i / SR
        env = math.sin(math.pi * i / n) ** 0.7          # swell in/out
        slip = 0.5 + 0.5 * math.sin(2 * math.pi * (37 + 9 * math.sin(2 * math.pi * 3 * t)) * t)
        raw = (rng.random() * 2 - 1)
        lp += 0.35 * (raw - lp)                        # crude lowpass -> band-ish
        hp = raw - lp
        out[i] = env * slip * (0.55 * hp + 0.25 * lp)
    return out
save("crayon.wav", crayon())

# invalid: dull low thud
inv = wood_tone(midi(38), 0.28, vol=0.9, decay=14, partials=(1.0, 2.02), pvol=(1.0, 0.2))
save("invalid.wav", inv)

# knock: box-claim wood knock
knock = wood_tone(midi(64), 0.16, vol=0.8, decay=22)
save("knock.wav", knock)

# pop: claim pop (pitch-dropping blip like a snug puzzle piece)
def pop():
    n = int(SR * 0.14)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        f = 760 * math.exp(-t * 18) + 220
        out[i] = math.sin(2 * math.pi * f * t) * math.exp(-t * 30)
    return out
save("pop.wav", pop())

# undo: soft reverse scratch
u = crayon(0.16); u.reverse(); save("undo.wav", u)

# start: xylophone arpeggio C5-E5-G5-C6
st = []
for j, m in enumerate((72, 76, 79, 84)):
    st = mix(st, wood_tone(midi(m), 0.35, vol=0.55, decay=9), at=j * 0.11)
save("start.wav", st)

# win: ascending wooden jingle
wn = []
for j, m in enumerate((72, 76, 79, 84, 79, 84, 88)):
    wn = mix(wn, wood_tone(midi(m), 0.4, vol=0.5, decay=8), at=j * 0.14)
save("win.wav", wn)

# lose: gentle descending phrase
lo = []
for j, m in enumerate((76, 74, 72, 69)):
    lo = mix(lo, wood_tone(midi(m), 0.5, vol=0.5, decay=7), at=j * 0.22)
save("lose.wav", lo)

# tie: neutral little two-note
ti = []
for j, m in enumerate((72, 76)):
    ti = mix(ti, wood_tone(midi(m), 0.4, vol=0.5, decay=8), at=j * 0.2)
save("tie.wav", ti)

# ---------------- MUSIC ----------------
def compose(notes, bpm, beats):
    """notes: list of (midi, startBeat, durBeats, vol). Returns loopable samples."""
    total = beats * 60.0 / bpm
    out = []
    for m, sb, db, vol in notes:
        start = sb * 60.0 / bpm
        dur = db * 60.0 / bpm
        tone = wood_tone(midi(m), min(dur * 1.6, 2.2), vol=vol, decay=5.5)
        out = mix(out, tone, at=start)
    # gentle fade edges so the loop point is seamless
    n = int(SR * total)
    if len(out) < n:
        out.extend([0.0] * (n - len(out)))
    out = out[:n]
    fade = int(SR * 0.05)
    for i in range(fade):
        g = i / fade
        out[i] *= g
        out[n - 1 - i] *= g
    # make the tail echo the head for a seamless loop: crossfade last 0.4s with first 0.4s
    xf = int(SR * 0.4)
    head = out[:xf]
    for i in range(xf):
        g = i / xf
        out[n - xf + i] = out[n - xf + i] * (1 - g) + head[i] * g
    return out[:n - xf] + head  # same length, loop point blends

# menu: calm 92bpm, 8 bars, C major lullaby (pentatonic melody + soft roots)
menu_notes = []
mel = [72, 76, 79, 76, 81, 79, 76, 74, 72, 0, 74, 76, 79, 81, 79, 76]
bass = [48, 43, 45, 43, 48, 43, 45, 43]
for bar in range(8):
    b = bar * 4
    for k in range(4):
        m = mel[(bar * 4 + k) % len(mel)]
        if m:
            menu_notes.append((m, b + k, 0.9, 0.42))
    menu_notes.append((bass[bar % len(bass)], b, 3.6, 0.30))
    menu_notes.append((bass[bar % len(bass)] + 7, b + 2, 1.6, 0.22))
save("menu_music.wav", compose(menu_notes, 92, 32))

# game: playful 104bpm, 8 bars, a little bouncier
game_notes = []
gmel = [76, 79, 81, 79, 84, 81, 79, 76, 77, 81, 84, 81, 86, 84, 81, 79,
        76, 79, 81, 84, 81, 79, 76, 74, 76, 79, 74, 72, 0, 0, 0, 0]
gbass = [48, 48, 45, 45, 41, 41, 43, 43]
for bar in range(8):
    b = bar * 4
    for k in range(8):
        m = gmel[(bar * 8 + k) % len(gmel)]
        if m:
            game_notes.append((m, b + k * 0.5, 0.45, 0.36))
    game_notes.append((gbass[bar % len(gbass)], b, 3.6, 0.26))
save("game_music.wav", compose(game_notes, 104, 32))

print("done")
