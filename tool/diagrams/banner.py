"""Generates the README banner (imgs/header/banner.png), as PNG only.

A 1280x320 card with its own ground, so it reads on light and dark pages
and on pub.dev: a light blue tint on the left with the icon, the wordmark
and the tagline, a navy band on the right, and a frame of the mpv_studio
player (imgs/playback.gif) in a window that sits across the two. The
cursor the recording caught over the waveform is painted out with the
same pixels from a nearby frame, where that part of the waveform is
identical and the pointer is elsewhere.

The SVG is drawn in a temporary directory and exported at 3x with
rsvg-convert, so the text uses Fira Sans from the system. Pillow reads
the GIF frame.

Run from the repository root: python3 tool/diagrams/banner.py
"""
import base64, io, os, subprocess, tempfile
from PIL import Image, ImageChops

OUT = os.path.join('imgs', 'header', 'banner.png')
GIF = os.path.join('imgs', 'playback.gif')
NAVY = '#0D2A75'
LIGHT_BLUE = '#A8EDFA'
GROUND = '#EEF8FC'      # light blue tint behind the lockup
TAG_INK = '#3B4A66'     # tagline, 8.6:1 on the tint
W, H, R = 1280, 320, 16
CAP = 0.691             # Fira Sans Medium cap height, in em

FRAME = 88              # the player with the waveform, cover and controls
DONOR = 86              # same view, pointer and hover line elsewhere
PATCH = (880, 40, 1060, 345)  # where frame 88 has the pointer, hover line and time label


def esc(t):
    return t.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def text(x, y, t, size, color, weight=400, tracking=0.0):
    ls = f' letter-spacing="{tracking * size:.2f}"' if tracking else ''
    return (f'<text x="{x:.2f}" y="{y:.2f}" font-family="Fira Sans" font-size="{size}" font-weight="{weight}" '
            f'fill="{color}"{ls}>{esc(t)}</text>')


def disc(cx, cy, d):
    """The package icon: nine rounded bars on a navy plate. Bars 0.045 d
    wide and 0.035 d apart, the centre one 0.62 d tall."""
    bw, gap = max(0.045 * d, 2.5), 0.035 * d
    x = cx - (9 * bw + 8 * gap) / 2
    out = [f'<circle cx="{cx}" cy="{cy}" r="{d / 2}" fill="{NAVY}"/>']
    for h in (120, 220, 420, 300, 700, 300, 420, 220, 120):
        hh = 0.62 * d * h / 700
        out.append(f'<rect x="{x:.2f}" y="{cy - hh / 2:.2f}" width="{bw:.2f}" height="{hh:.2f}" '
                   f'rx="{bw / 2:.2f}" fill="{LIGHT_BLUE}"/>')
        x += bw + gap
    return '\n'.join(out)


def lockup(x, cy, d, wm, lines, size, gap, lead):
    """Icon, wordmark and tagline. The icon spans the text block, from the
    wordmark's cap height to the last tagline baseline."""
    first = 0.62 * wm + 14
    top = cy - (CAP * wm + first + lead * (len(lines) - 1)) / 2
    base = top + CAP * wm
    tx = x + d + gap
    out = [disc(x + d / 2, cy, d), text(tx - 2, base, 'mpv_audio_kit', wm, NAVY, 500, -0.02)]
    for i, ln in enumerate(lines):
        out.append(text(tx, base + first + i * lead, ln, size, TAG_INK))
    return '\n'.join(out)


def screenshot():
    """Frame FRAME of the GIF with the pointer painted out from DONOR."""
    gif = Image.open(GIF)
    gif.seek(DONOR)
    donor = gif.convert('RGB')
    gif.seek(FRAME)
    frame = gif.convert('RGB')
    box = PATCH
    diff = ImageChops.difference(frame.crop(box), donor.crop(box)).convert('L')
    mask = diff.point(lambda v: 255 if v > 12 else 0)
    frame.paste(donor.crop(box), box[:2], mask)
    buf = io.BytesIO()
    frame.save(buf, 'PNG')
    return frame.size, 'data:image/png;base64,' + base64.b64encode(buf.getvalue()).decode()


def banner_svg():
    (fw, fh), uri = screenshot()
    sw = 536                      # the bottom edge cuts under the artist line
    sh = sw * fh / fw
    sx, sy = 664, 48
    b = [f'<clipPath id="card"><rect width="{W}" height="{H}" rx="{R}"/></clipPath>',
         f'<clipPath id="win"><rect x="{sx}" y="{sy}" width="{sw}" height="{sh:.1f}" rx="12"/></clipPath>',
         '<filter id="shadow" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="14"/></filter>',
         '<g clip-path="url(#card)">',
         f'<rect width="{W}" height="{H}" fill="{GROUND}"/>',
         f'<rect x="808" width="{W - 808}" height="{H}" fill="{NAVY}"/>',
         f'<rect x="{sx}" y="{sy + 10}" width="{sw}" height="{sh:.1f}" rx="12" fill="#06143A" fill-opacity="0.35" '
         'filter="url(#shadow)"/>',
         f'<image x="{sx}" y="{sy}" width="{sw}" height="{sh:.1f}" clip-path="url(#win)" preserveAspectRatio="none" '
         f'xlink:href="{uri}"/>',
         f'<rect x="{sx + .5}" y="{sy + .5}" width="{sw - 1}" height="{sh - 1:.1f}" rx="11.5" fill="none" '
         'stroke="#FFFFFF" stroke-opacity="0.16"/>',
         lockup(64, H / 2, 96, 52, ['Audio engine for Flutter,', 'built on mpv and ffmpeg.'], 24, 28, 32),
         '</g>',
         f'<rect x="0.5" y="0.5" width="{W - 1}" height="{H - 1}" rx="{R - .5}" fill="none" stroke="{NAVY}" '
         'stroke-opacity="0.14"/>']
    return (f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
            f'viewBox="0 0 {W} {H}" width="{W}" height="{H}" role="img" '
            f'aria-label="mpv_audio_kit, audio engine for Flutter, with the mpv_studio player">\n'
            + '\n'.join(b) + '\n</svg>\n')


os.makedirs(os.path.dirname(OUT), exist_ok=True)
with tempfile.TemporaryDirectory() as tmp:
    svg = os.path.join(tmp, 'banner.svg')
    with open(svg, 'w') as fh:
        fh.write(banner_svg())
    subprocess.run(['rsvg-convert', '-z', '3', svg, '-o', OUT], check=True)
print('Banner written to', OUT)
