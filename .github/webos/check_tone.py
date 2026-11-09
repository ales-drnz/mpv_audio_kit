# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

"""What ao_alsa wrote in the headless run: test/fixtures/sine_5s.flac is a
440 Hz sine, 44.1 kHz mono s16. Passes when the file holds at least 2 s of
it, not silence: its frequency from the zero crossings within 2 Hz.

Usage: python3 check_tone.py <raw file>
"""
import math
import struct
import sys

RATE = 44100
data = open(sys.argv[1], 'rb').read()
n = len(data) // 2
samples = struct.unpack(f'<{n}h', data[:n * 2])
seconds = n / RATE
rms = math.sqrt(sum(s * s for s in samples) / n) if n else 0.0
rises = sum(1 for a, b in zip(samples, samples[1:]) if a < 0 <= b)
freq = rises / seconds if n else 0.0
print(f'MAK_WEBOS_TONE {seconds:.2f} s, rms {rms:.0f}, {freq:.1f} Hz')
sys.exit(0 if seconds >= 2 and rms > 1000 and abs(freq - 440) <= 2 else 1)
