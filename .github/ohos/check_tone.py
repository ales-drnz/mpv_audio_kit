# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

"""What the Oniro emulator's sound card played while the app ran, as QEMU's
wav audiodev wrote it: .github/ohos/sine_5s_cover.flac is a 440 Hz sine. Passes
when at least 1.5 s of it is there (the app plays past 2 s, then disposes
the player). The file is read in 50 ms windows, each a tone or silence; a
tone's frequency is the period between the rising zero crossings of the
first channel (a count would read a window that is part silence as a lower
tone), within 20 Hz of 440.

QEMU writes the sizes of the RIFF and data chunks only when it closes the
file, and the emulator is still running: the header is read by hand.

Usage: python3 check_tone.py <wav> [first byte of the run]
"""
import math
import struct
import sys

path = sys.argv[1]
start = int(sys.argv[2]) if len(sys.argv) > 2 else 0
raw = open(path, 'rb').read()
if raw[:4] != b'RIFF' or raw[8:12] != b'WAVE':
    print(f'MAK_OHOS_TONE FAIL {path} is not a WAV file')
    sys.exit(1)
pos, rate, channels, width, data_at = 12, 0, 0, 0, 0
while pos + 8 <= len(raw):
    cid, size = raw[pos:pos + 4], struct.unpack('<I', raw[pos + 4:pos + 8])[0]
    body = pos + 8
    if cid == b'fmt ':
        _, channels, rate, _, _, bits = struct.unpack('<HHIIHH', raw[body:body + 16])
        width = bits // 8
    elif cid == b'data':
        data_at = body
        break
    pos = body + size + (size & 1)
if width != 2 or not data_at:
    print(f'MAK_OHOS_TONE FAIL {path}: no 16-bit data')
    sys.exit(1)
frame = 2 * channels
# The run's first byte, on a frame of the data.
first = data_at + -(-(max(start, data_at) - data_at) // frame) * frame
frames = raw[first:]
n = len(frames) // frame
left = struct.unpack(f'<{n * channels}h', frames[:n * frame])[::channels]

win = rate // 20
labels = ''
for i in range(0, n - win + 1, win):
    w = left[i:i + win]
    if math.sqrt(sum(s * s for s in w) / win) < 500:
        labels += '-'
        continue
    rises = [k for k in range(1, win) if w[k - 1] < 0 <= w[k]]
    gaps = [b - a for a, b in zip(rises, rises[1:])]
    if len(gaps) < 3 or max(gaps) > 1.5 * sorted(gaps)[len(gaps) // 2]:
        labels += '?'
        continue
    freq = rate * len(gaps) / (rises[-1] - rises[0])
    labels += 'a' if abs(freq - 440) <= 20 else '?'

tone = labels.count('a') / 20
ok = tone >= 1.5
print(f'MAK_OHOS_TONE {"PASS" if ok else "FAIL"} {n / rate:.2f} s at {rate} Hz x{channels}: '
      f'{tone:.2f} s of 440 Hz, {labels.count("?")} other windows')
print(f'MAK_OHOS_TONE windows {labels}')
sys.exit(0 if ok else 1)
