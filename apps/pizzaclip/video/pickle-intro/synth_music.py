#!/usr/bin/env python3
"""PICkle intro — fresh, zingy minimal music bed (deterministic, royalty-free).
Brighter G-major e-piano + music-box melody + sub bass + water-drop 'plips'
synced to the capture and the jar-fill drops. ~26.5s. Lighter/crisper than pizza."""
import numpy as np, wave

SR = 44100
TOTAL = 26.5
N = int(SR * TOTAL)
buf = np.zeros(N)

NOTE = {
    "E2":82.41,"G2":98.00,"A2":110.00,"B2":123.47,"C3":130.81,"D3":146.83,"E3":164.81,
    "G3":196.00,"A3":220.00,"B3":246.94,"C4":261.63,"D4":293.66,"E4":329.63,"Fs4":369.99,
    "G4":392.00,"A4":440.00,"B4":493.88,"C5":523.25,"D5":587.33,"E5":659.25,"Fs5":739.99,"G5":783.99,
}

def env_mallet(n, attack, tau):
    t = np.arange(n)/SR
    return np.minimum(t/attack,1.0) * np.exp(-np.maximum(t-attack,0)/tau)

def tone(freq, dur, kind="epiano", amp=0.2):
    n = int(dur*SR); t = np.arange(n)/SR
    if kind == "epiano":
        w = np.sin(2*np.pi*freq*t) + 0.34*np.sin(2*np.pi*2*freq*t) + 0.13*np.sin(2*np.pi*3*freq*t)
        e = env_mallet(n, 0.005, dur*0.42)
    elif kind == "bell":
        w = np.sin(2*np.pi*freq*t) + 0.5*np.sin(2*np.pi*2*freq*t) + 0.26*np.sin(2*np.pi*3.01*freq*t)
        e = env_mallet(n, 0.004, dur*0.5)
    elif kind == "bass":
        w = np.sin(2*np.pi*freq*t) + 0.16*np.sin(2*np.pi*2*freq*t)
        e = env_mallet(n, 0.012, dur*0.5)
    elif kind == "pad":
        det = 0.004
        w = (np.sin(2*np.pi*freq*t) + np.sin(2*np.pi*freq*(1+det)*t) + np.sin(2*np.pi*freq*(1-det)*t))/3
        e = np.ones(n); na = min(int(0.4*SR), n//2); nr = min(int(0.55*SR), n//2)
        e[:na] = 0.5-0.5*np.cos(np.pi*np.arange(na)/na)
        e[-nr:] = 0.5+0.5*np.cos(np.pi*np.arange(nr)/nr)
    return amp * w * e

def plip(amp=0.10):
    n = int(0.15*SR); t = np.arange(n)/SR
    f = 1500*np.exp(-t*9) + 720
    ph = 2*np.pi*np.cumsum(f)/SR
    return amp*np.sin(ph)*np.exp(-t/0.038)

def place(t0, sig):
    i = int(t0*SR); j = min(i+len(sig), N)
    if i < N: buf[i:j] += sig[:j-i]

# ---- structure: G major, I–vi–IV–V ----
Lb = 2.7
bars = [i*Lb for i in range(10)]
CH = {"G":["G3","B3","D4"], "Em":["E3","G3","B3"], "C":["C4","E4","G4"], "D":["D4","Fs4","A4"]}
seq   = ["G","Em","C","D","G","Em","C","D","G","G"]
root  = ["G2","E2","C3","D3","G2","E2","C3","D3","G2","G2"]
pad_a = [0.09,0.09,0.12,0.12,0.16,0.16,0.17,0.17,0.14,0.11]
mel = {
    "G":[(0.0,"D5"),(1.35,"B4")], "Em":[(0.0,"B4"),(1.35,"G4")],
    "C":[(0.0,"E5"),(1.35,"G4")], "D":[(0.0,"A4"),(1.35,"Fs5")],
}

for bi, bt in enumerate(bars):
    ch = seq[bi]
    for nm in CH[ch]:
        place(bt, tone(NOTE[nm], Lb*1.03, "pad", pad_a[bi]))
    if bi >= 3:
        place(bt,      tone(NOTE[root[bi]], 1.2, "bass", 0.22))
        place(bt+1.35, tone(NOTE[root[bi]], 1.1, "bass", 0.17))
    if 3 <= bi <= 7:
        for off, nm in mel[ch]:
            place(bt+off, tone(NOTE[nm], 1.05, "epiano", 0.17))

# cold-open soft bell + the capture 'snap' plip
place(0.5,  tone(NOTE["D5"], 1.5, "bell", 0.12))
place(0.6,  tone(NOTE["G4"], 1.5, "bell", 0.07))
place(2.05, plip(0.12))  # S1 capture
# reveal sparkle + a plip per screenshot dropping into the jar (synced to stagger .18 from 10.0)
place(9.7,  tone(NOTE["G5"], 1.4, "bell", 0.10))
for k in range(5):
    place(10.0 + k*0.18, plip(0.11))
# resolve — warm rising close into S5
place(21.6, tone(NOTE["D5"], 1.5, "epiano", 0.16))
place(22.3, tone(NOTE["G5"], 2.3, "bell", 0.13))
place(24.3, tone(NOTE["G4"], 2.1, "epiano", 0.12))

# ---- ambience (early reflections) ----
def taps(x, delays, gains):
    out = x.copy()
    for d, g in zip(delays, gains):
        s = int(d*SR)
        if s < len(x): out[s:] += g*x[:len(x)-s]
    return out
L = taps(buf, [0.035,0.063,0.107,0.183], [0.28,0.20,0.14,0.08])
R = taps(buf, [0.041,0.070,0.115,0.197], [0.24,0.22,0.12,0.09])

def fades(x):
    y = x.copy(); fi = int(0.3*SR); fo = int(1.9*SR)
    y[:fi] *= np.linspace(0,1,fi)
    y[-fo:] *= (0.5+0.5*np.cos(np.pi*np.arange(fo)/fo))
    return y
L, R = fades(L), fades(R)
peak = max(np.abs(L).max(), np.abs(R).max(), 1e-6)
g = 0.72/peak
L = np.tanh(L*g*1.1); R = np.tanh(R*g*1.1)

stereo16 = np.int16(np.clip(np.stack([L, R], axis=1), -1, 1) * 32767)
with wave.open("assets/bgm.wav", "wb") as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(stereo16.tobytes())
print(f"wrote assets/bgm.wav dur={TOTAL}s peak_in={peak:.3f} rms={np.sqrt((L**2).mean()):.3f}")
