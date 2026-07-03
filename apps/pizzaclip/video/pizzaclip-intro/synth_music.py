#!/usr/bin/env python3
"""PIZZA CLIP intro — warm minimal music bed (deterministic, royalty-free).
Soft e-piano chords + music-box melody + sub bass + early-reflection ambience.
Arc: calm cold-open -> lift at the reveal -> resolved warm close. ~26.8s."""
import numpy as np, wave

SR = 44100
TOTAL = 26.5
N = int(SR * TOTAL)
buf = np.zeros(N)

NOTE = {
    "Bb2":116.54,"C3":130.81,"D3":146.83,"E3":164.81,"F3":174.61,"G3":196.00,
    "A3":220.00,"Bb3":233.08,"C4":261.63,"D4":293.66,"E4":329.63,"F4":349.23,
    "G4":392.00,"A4":440.00,"Bb4":466.16,"C5":523.25,"D5":587.33,"E5":659.25,"F5":698.46,
    "F2":87.31,
}

def env_mallet(n, attack, tau):
    t = np.arange(n)/SR
    return np.minimum(t/attack,1.0) * np.exp(-np.maximum(t-attack,0)/tau)

def tone(freq, dur, kind="epiano", amp=0.2):
    n = int(dur*SR); t = np.arange(n)/SR
    if kind == "epiano":
        w = np.sin(2*np.pi*freq*t) + 0.32*np.sin(2*np.pi*2*freq*t) + 0.10*np.sin(2*np.pi*3*freq*t)
        e = env_mallet(n, 0.006, dur*0.45)
    elif kind == "bell":
        w = np.sin(2*np.pi*freq*t) + 0.45*np.sin(2*np.pi*2*freq*t) + 0.22*np.sin(2*np.pi*3.01*freq*t)
        e = env_mallet(n, 0.004, dur*0.5)
    elif kind == "bass":
        w = np.sin(2*np.pi*freq*t) + 0.16*np.sin(2*np.pi*2*freq*t)
        e = env_mallet(n, 0.012, dur*0.55)
    elif kind == "pad":
        det = 0.004
        w = (np.sin(2*np.pi*freq*t) + np.sin(2*np.pi*freq*(1+det)*t) + np.sin(2*np.pi*freq*(1-det)*t))/3
        e = np.ones(n); na = int(0.45*SR); nr = int(0.6*SR)
        na = min(na, n//2); nr = min(nr, n//2)
        e[:na] = 0.5-0.5*np.cos(np.pi*np.arange(na)/na)
        e[-nr:] = 0.5+0.5*np.cos(np.pi*np.arange(nr)/nr)
    return amp * w * e

def place(t0, sig):
    i = int(t0*SR); j = min(i+len(sig), N)
    if i < N: buf[i:j] += sig[:j-i]

# ---- structure ----
Lb = 2.7  # bar length
bars = [i*Lb for i in range(10)]
CH = {"F":["F3","A3","C4"], "Dm":["D3","F3","A3"], "Bb":["Bb3","D4","F4"], "C":["C4","E4","G4"]}
seq   = ["F","Dm","Bb","C","F","Dm","Bb","C","F","F"]
root  = ["F2","D3","Bb2","C3","F2","D3","Bb2","C3","F2","F2"]
pad_a = [0.09,0.09,0.12,0.12,0.16,0.16,0.17,0.17,0.14,0.11]
mel   = {
    "F":[(0.0,"C5"),(1.35,"A4")], "Dm":[(0.0,"A4"),(1.35,"F4")],
    "Bb":[(0.0,"D5"),(1.35,"F4")], "C":[(0.0,"G4"),(1.35,"E4")],
}

for bi, bt in enumerate(bars):
    ch = seq[bi]
    # pad chord
    for nm in CH[ch]:
        place(bt, tone(NOTE[nm], Lb*1.03, "pad", pad_a[bi]))
    # bass from the reveal (bar 3 ~ 8.1s) onward, two soft hits
    if bi >= 3:
        place(bt,      tone(NOTE[root[bi]], 1.2, "bass", 0.22))
        place(bt+1.35, tone(NOTE[root[bi]], 1.1, "bass", 0.17))
    # melody from the reveal through strengths (bars 3..7), resolve after
    if 3 <= bi <= 7:
        for off, nm in mel[ch]:
            place(bt+off, tone(NOTE[nm], 1.1, "epiano", 0.17))

# cold-open soft bell
place(0.45, tone(NOTE["C5"], 1.6, "bell", 0.12))
place(0.55, tone(NOTE["F4"], 1.6, "bell", 0.07))
# reveal sparkle (~9.7s, pizza assembling)
place(9.7,  tone(NOTE["F5"], 1.4, "bell", 0.11))
place(9.9,  tone(NOTE["A4"], 1.3, "bell", 0.06))
# resolve — warm rising close into S5 (~21.6s, bar8)
place(21.6, tone(NOTE["C5"], 1.6, "epiano", 0.16))
place(22.3, tone(NOTE["F5"], 2.4, "bell", 0.14))
place(24.3, tone(NOTE["F4"], 2.2, "epiano", 0.12))  # final settle

# ---- ambience (early reflections, vectorized) ----
def taps(x, delays, gains):
    out = x.copy()
    for d, g in zip(delays, gains):
        s = int(d*SR)
        if s < len(x): out[s:] += g*x[:len(x)-s]
    return out

L = taps(buf, [0.037,0.067,0.113,0.190], [0.30,0.22,0.15,0.09])
R = taps(buf, [0.044,0.074,0.121,0.205], [0.26,0.24,0.13,0.10])

# ---- master: fades, normalize, soft-clip ----
def fades(x):
    y = x.copy(); fi = int(0.3*SR); fo = int(1.9*SR)
    y[:fi] *= np.linspace(0,1,fi)
    y[-fo:] *= (0.5+0.5*np.cos(np.pi*np.arange(fo)/fo))
    return y
L, R = fades(L), fades(R)
peak = max(np.abs(L).max(), np.abs(R).max(), 1e-6)
g = 0.72/peak
L = np.tanh(L*g*1.1); R = np.tanh(R*g*1.1)

stereo = np.stack([L, R], axis=1)
stereo16 = np.int16(np.clip(stereo, -1, 1) * 32767)

with wave.open("assets/bgm.wav", "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(stereo16.tobytes())

print(f"wrote assets/bgm.wav  dur={TOTAL}s  peak_in={peak:.3f}  rms={np.sqrt((L**2).mean()):.3f}")
