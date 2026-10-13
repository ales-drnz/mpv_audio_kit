"""Generates the package icon (imgs/mpv_audio_kit.png) and the README
diagrams in imgs/diagrams, as PNG only.

The branding is flat colors: the icon's navy plate with a white glyph, and
light blue for your code in the diagrams.
Library nodes take the navy and your code's nodes the light blue. The
PNGs are transparent, so they sit on the page's own ground: text inside a
node relies on the node's fill, and the free text, arrows and bands use mid
tones that read on white and on GitHub's dark ground alike. The SVGs are
drawn in a temporary directory and exported at 2x with rsvg-convert.

The drawing kit is in base.py: the palette, the canvas with its helpers
and the rules every diagram follows (one width, the type sizes, the arrow
weights, the radii, the closing caption). The diagrams are grouped by
kind: signals.py draws the signal itself (effects, spectrum, demuxer
cache), system.py the parts and the time (architecture, analysis cache
feed, media session, playWhenReady), flows.py the flows and sequences
(lifecycle, prefetch, cover art, errors, on_load hook, source resolver).

Run from the repository root: python3 tool/diagrams/generate.py
"""
import os, subprocess, sys, tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from base import NAVY  # noqa: E402
from flows import cover, errors, hook, lifecycle, prefetch, resolver  # noqa: E402
from signals import cache, effects, spectrum  # noqa: E402
from system import architecture, cache_feed, media, timeline  # noqa: E402

OUT = os.path.join('imgs', 'diagrams')
ICON = os.path.join('imgs', 'mpv_audio_kit.png')
# The icon's glyph: white on the navy disc. The diagrams keep the light
# blue, which also reads on a light page, where white would vanish.
GLYPH = '#FFFFFF'

ALL = [architecture, lifecycle, effects, timeline, prefetch, cover, errors, hook, resolver, spectrum, media,
       cache_feed, cache]


def icon_svg():
    """The package icon: nine rounded bars, symmetric around the tallest,
    on a round plate like mpv_studio's."""
    k = 0.86  # the bars keep clear of the rim
    bars = ''.join(
        f'<rect x="{512 + k * (116 + 93 * i - 512):.1f}" y="{512 - k * h / 2:.1f}" width="{k * 48:.1f}" '
        f'height="{k * h:.1f}" rx="{k * 24:.1f}" fill="{GLYPH}"/>'
        for i, h in enumerate((120, 220, 420, 300, 700, 300, 420, 220, 120)))
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024" '
            'role="img" aria-label="mpv_audio_kit">\n'
            f'<circle cx="512" cy="512" r="512" fill="{NAVY}"/>\n{bars}\n</svg>\n')


def render(svg_text, png, tmp, zoom=None):
    svg = os.path.join(tmp, os.path.basename(png)[:-4] + '.svg')
    with open(svg, 'w') as fh:
        fh.write(svg_text)
    subprocess.run(['rsvg-convert'] + (['-z', zoom] if zoom else []) + [svg, '-o', png], check=True)


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for f in ALL:
            d = f('light')
            render(d.svg(), os.path.join(OUT, f'{d.name}.png'), tmp, zoom='2')
        render(icon_svg(), ICON, tmp)
    print('Icon written to', ICON, 'and', len(ALL), 'diagrams to', OUT)
