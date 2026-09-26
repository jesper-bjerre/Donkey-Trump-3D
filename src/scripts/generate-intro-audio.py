#!/usr/bin/env python3
"""Generate the iOS intro's original pulse/triangle/noise effects.

Run: python3 src/scripts/generate-intro-audio.py
Uses only the standard library. No recordings or melodies from other games.
The existing web-game WAVs stay unchanged.
"""

import math
from pathlib import Path
import random
import struct
import wave

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "DonkeyTrump3D/Resources/Audio"
RANDOM = random.Random(31)


def silence(seconds):
    return [0.0] * round(seconds * RATE)


def tone(start, end, seconds, *, shape="pulse", volume=0.4, noise=0.0):
    samples = []
    phase = 0.0
    count = round(seconds * RATE)
    for i in range(count):
        progress = i / max(1, count - 1)
        phase += start * (end / start) ** progress / RATE
        cycle = phase % 1
        oscillator = 1 - 4 * abs(cycle - 0.5) if shape == "triangle" else (1 if cycle < 0.25 else -1)
        envelope = min(1, i / (RATE * 0.003)) * (1 - progress) ** 1.4
        samples.append(((1 - noise) * oscillator + noise * RANDOM.uniform(-1, 1)) * volume * envelope)
    return samples


def mix(*tracks):
    result = [0.0] * max(map(len, tracks))
    for track in tracks:
        for i, sample in enumerate(track):
            result[i] += sample
    return result


def notes(pitches, seconds, *, shape="pulse", volume=0.35):
    return [sample for pitch in pitches for sample in tone(pitch, pitch, seconds, shape=shape, volume=volume)]


def write(name, samples):
    assert all(math.isfinite(value) and abs(value) < 1 for value in samples), f"Clipping: {name}"
    # Remove the narrow pulse's DC offset and taper both ends to prevent clicks.
    mean = sum(samples) / len(samples)
    fade = round(RATE * 0.004)
    pcm = []
    for i, value in enumerate(samples):
        envelope = min(1, i / fade, (len(samples) - 1 - i) / fade)
        value = (value - mean) * envelope
        assert abs(value) < 1, f"Clipping after DC removal: {name}"
        pcm.append(round(value * 32767))
    with wave.open(str(OUT / f"intro-{name}.wav"), "wb") as output:
        output.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes(struct.pack(f"<{len(pcm)}h", *pcm))
    print(f"intro-{name}.wav: {len(samples) / RATE:.2f}s")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    # Weighty, short footsteps below the march; alternating pitch comes from the timeline.
    write("step", mix(tone(125, 48, 0.1, shape="triangle", volume=0.58),
                      tone(650, 150, 0.035, volume=0.22, noise=0.8)))
    # A hollow rung knock and a bright arcade blip, pitched up for each climbing beat.
    write("climb", mix(tone(293.66, 440, 0.11, volume=0.33),
                       tone(1800, 900, 0.045, volume=0.14, noise=0.45)))
    write("drop", notes([587.33, 440, 293.66], 0.065, volume=0.34)
          + tone(110, 50, 0.12, shape="triangle", volume=0.5))
    # Six pen strokes fit inside the 1.92-second on-screen signature.
    strokes = []
    for i in range(6):
        strokes += tone(1300 + i * 130, 650, 0.18, volume=0.3, noise=0.87) + silence(0.12)
    write("sign", strokes)
    write("stamp", mix(tone(135, 42, 0.23, shape="triangle", volume=0.64),
                       tone(1500, 100, 0.09, volume=0.35, noise=0.85)))
    # The creak ends before the 0.36-second tilt; impact is triggered at its landing.
    write("creak", mix(tone(180, 75, 0.32, volume=0.3, noise=0.15),
                       tone(690, 230, 0.32, volume=0.16)))
    write("impact", mix(tone(95, 32, 0.28, shape="triangle", volume=0.58),
                        tone(2300, 120, 0.16, volume=0.23, noise=0.8),
                        tone(370, 355, 0.24, volume=0.13)))
    # Original D-major answer to the web intro's march, before the gameplay jingle.
    write("ready", mix(notes([293.66, 369.99, 440, 587.33], 0.12, volume=0.3)
                       + tone(880, 587.33, 0.3, volume=0.28),
                       notes([146.83, 110, 146.83], 0.26, shape="triangle", volume=0.45)))


if __name__ == "__main__":
    main()
