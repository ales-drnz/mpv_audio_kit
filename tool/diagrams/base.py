"""Shared drawing kit for the README diagrams: the palette, the D canvas
with its helpers, and the signal shapes the waveform diagrams draw.

The rules every diagram follows, so the thirteen read as one set in the
README, where each one is shown at the column's full width:
- the canvas is W wide and keeps M clear on the left and the right;
- node titles 14, semibold; text 12; headings 13, semibold; 11 only for
  axis ticks and inline code;
- main arrows 2.2, secondary 1.7; a label sits about 9 above its arrow;
- corners: bands and containers 14, nodes and panels 10, small parts 6;
- the closing caption is one centered line, 20 above the bottom edge;
- red only for errors and failures.
"""
import math

W = 960   # every diagram has the same width, so the text has the same size on the page
M = 20    # outer margin, left and right

NAVY = '#0D2A75'
LIGHT_BLUE = '#A8EDFA'
SANS = "Noto Sans, system-ui, -apple-system, Segoe UI, sans-serif"
MONO = "Noto Sans Mono, ui-monospace, SFMono-Regular, Menlo, monospace"

# Inks that sit on a fill, never on the page ground.
ON_NAVY = '#C9DBFF'     # secondary text on navy
ON_APP = '#1D3F7E'      # secondary text on the light blue
INK2 = '#59636E'        # secondary text on the neutral fill
FAIL_INK = '#B42318'    # text on the soft red fill

PAL = {
    # ink: text inside neutral nodes, on their own fill. label, muted, line,
    # main, fail and band sit on the page ground, light or dark.
    'light': dict(ink='#1F2328', label='#6B7689', muted='#6B7689', line='#7D8796', main='#2F6FD6',
                  fail='#D1392B', failSoft='#FDE3E0', neutral='#E6EBF3', band='#7D8796'),
}


def esc(t):
    return t.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def text_w(t, size=12, mono=False, weight=400):
    """Rough advance width of a Noto Sans or Noto Sans Mono run, enough to
    size chips and keep labels apart."""
    em = 0.6 if mono else 0.53
    return len(t) * size * em * (1.05 if weight >= 600 else 1)


# ---------------------------------------------------------------- signal shapes
WAVE_LOW, WAVE_HIGH = 0.45, 0.55


def hit_env(t):
    """Two decaying hits over a quiet floor, peaking near 1."""
    def hit(t0, a, k):
        return a * math.exp(-(t - t0) * k) if t >= t0 else a * math.exp((t - t0) * 60)
    return 0.12 + hit(0.1, 0.88, 7.0) + hit(0.58, 0.45, 8.0)


def wave(t, low=1.0, high=1.0, env=None):
    """A stylised music signal at time t in [0, 1]: a slow bass partial and a
    faster upper partial under a two-hit envelope (a loud hit, then a
    softer one). low and high scale the two partials, so an equalizer can be
    drawn as a change of shape and not only of size."""
    e = env(t) if env else hit_env(t)
    return e * (WAVE_LOW * low * math.sin(2 * math.pi * 4.0 * t + 0.4)
                + WAVE_HIGH * high * math.sin(2 * math.pi * 31.0 * t + 1.1))


def wave_path(fn, x, y, w, amp, n=900):
    """SVG path of fn(t) for t in [0, 1], drawn from x to x + w around the
    baseline y, fn's 1.0 mapped to amp pixels upwards."""
    pts = [f'{x + w * i / n:.1f},{y - amp * fn(i / n):.1f}' for i in range(n + 1)]
    return 'M' + ' L'.join(pts)


def hann(t):
    return 0.5 - 0.5 * math.cos(2 * math.pi * t)


# ---------------------------------------------------------------- the canvas
class D:
    def __init__(self, name, h, theme, label, w=W):
        self.name, self.w, self.h, self.t, self.c = name, w, h, theme, PAL[theme]
        self.label = label
        self.body = []

    def add(self, s):
        self.body.append(s)

    def svg(self):
        c = self.c
        marks = ''.join(
            f'<marker id="m{n}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="10" markerHeight="10" '
            f'markerUnits="userSpaceOnUse" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{col}"/></marker>'
            for n, col in (('main', c['main']), ('sec', c['line']), ('fail', c['fail'])))
        # the stripes mark work in progress, such as a loading state
        stripes = ('<pattern id="stripes" width="8" height="8" patternUnits="userSpaceOnUse" '
                   'patternTransform="rotate(45)"><rect width="3" height="8" fill="#FFFFFF" fill-opacity="0.16"/>'
                   '</pattern>')
        return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {self.w} {self.h}" width="{self.w}" height="{self.h}" '
                f'role="img" aria-label="{esc(self.label)}">\n<defs>\n{marks}\n{stripes}\n</defs>\n'
                + '\n'.join(self.body) + '\n</svg>\n')

    # ------------------------------------------------------------ nodes and text
    # role: lib (navy), app (light blue), neutral, fail, ghost (dimmed text)
    def node(self, x, y, w, h, title, sub=None, role='lib', mono=True, r=10, sub2=None, size=14):
        c = self.c
        fill, tc, sc = {'lib': (NAVY, '#FFFFFF', ON_NAVY), 'app': (LIGHT_BLUE, NAVY, ON_APP),
                        'fail': (c['failSoft'], FAIL_INK, INK2), 'ghost': (c['neutral'], INK2, INK2),
                        'neutral': (c['neutral'], c['ink'], INK2)}[role]
        self.add(f'<rect x="{x - w / 2}" y="{y - h / 2}" width="{w}" height="{h}" rx="{r}" fill="{fill}"/>')
        lines = [s for s in (sub, sub2) if s]
        ty = y + 5 - 9 * len(lines)
        self.add(f'<text x="{x}" y="{ty}" text-anchor="middle" font-family="{MONO if mono else SANS}" font-size="{size}" font-weight="600" fill="{tc}">{esc(title)}</text>')
        for i, s in enumerate(lines):
            self.add(f'<text x="{x}" y="{ty + 19 + 16 * i}" text-anchor="middle" font-family="{SANS}" font-size="12" fill="{sc}">{esc(s)}</text>')

    def outline(self, x, y, w, h, r=10):
        """A hairline around a centered node, so a neutral node keeps its edge on a tinted band."""
        self.add(f'<rect x="{x - w / 2}" y="{y - h / 2}" width="{w}" height="{h}" rx="{r}" fill="none" '
                 f'stroke="{self.c["line"]}" stroke-opacity="0.6" stroke-width="1"/>')

    def text(self, x, y, t, anchor='middle', color='muted', size=12, mono=False, weight=400):
        col = self.c.get(color, color)
        self.add(f'<text x="{x}" y="{y}" text-anchor="{anchor}" font-family="{MONO if mono else SANS}" font-size="{size}" font-weight="{weight}" fill="{col}">{esc(t)}</text>')

    def heading(self, x, y, t, sub=None, anchor='start', mono=False):
        """A section or row heading, with an optional plain line under it."""
        self.text(x, y, t, anchor=anchor, color='label', size=13, mono=mono, weight=600)
        if sub:
            self.text(x, y + 17, sub, anchor=anchor)

    def rich(self, x, y, parts, anchor='start', size=12):
        """One line of mixed runs, as (text, kind) pairs: kind is 'text', 'strong'
        (label color, semibold) or 'code' (mono, label color). The renderer
        lays the runs out, so no width guessing."""
        runs = []
        for t, k in parts:
            if k == 'code':
                runs.append(f'<tspan font-family="{MONO}" font-size="{size - 1}" fill="{self.c["label"]}">{esc(t)}</tspan>')
            elif k == 'strong':
                runs.append(f'<tspan font-weight="600" fill="{self.c["label"]}">{esc(t)}</tspan>')
            else:
                runs.append(f'<tspan>{esc(t)}</tspan>')
        self.add(f'<text x="{x}" y="{y}" text-anchor="{anchor}" font-family="{SANS}" font-size="{size}" '
                 f'fill="{self.c["muted"]}" xml:space="preserve">{"".join(runs)}</text>')

    def caption(self, t):
        """The closing line under a diagram: plain text or rich runs, centered."""
        if isinstance(t, str):
            self.text(self.w / 2, self.h - 20, t)
        else:
            self.rich(self.w / 2, self.h - 20, t, anchor='middle')

    def legend(self, x, y, t, kind='line', anchor='start'):
        """A swatch and its meaning. kind: line (a faint trace), area (a tinted
        span), play and bg (the two track bars)."""
        c = self.c
        sw = {'line': 24, 'area': 14, 'play': 28, 'bg': 28}[kind]
        if anchor == 'end':
            x -= sw + 8 + text_w(t)
        elif anchor == 'middle':
            x -= (sw + 8 + text_w(t)) / 2
        if kind == 'line':
            self.add(f'<line x1="{x}" y1="{y - 4}" x2="{x + sw}" y2="{y - 4}" stroke="{c["line"]}" stroke-opacity="0.5" stroke-width="1.6"/>')
        elif kind == 'area':
            self.rect(x, y - 10, sw, 11, c['band'], op=0.4, r=2)
        else:
            self.track(x, x + sw, y - 4, h=10, kind=kind)
        self.text(x + sw + 8, y, t, anchor='start')

    # ------------------------------------------------------------ lines
    def arrow(self, d, kind='main', dash=False, head=True, width=None, both=False):
        """kind: main (blue), sec (grey), fail (red). both puts a head at each end."""
        c = self.c
        col = {'main': c['main'], 'sec': c['line'], 'fail': c['fail']}[kind]
        w = width or (2.2 if kind == 'main' else 1.7)
        dsh = ' stroke-dasharray="5 5"' if dash else ''
        mk = f' marker-end="url(#m{kind})"' if head else ''
        if both:
            mk += f' marker-start="url(#m{kind})"'
        self.add(f'<path d="{d}" fill="none" stroke="{col}" stroke-width="{w}"{dsh}{mk}/>')

    def rule(self, y):
        """A faint divider between two parts of a diagram, margin to margin."""
        self.add(f'<line x1="{M}" y1="{y}" x2="{self.w - M}" y2="{y}" stroke="{self.c["line"]}" stroke-opacity="0.35" stroke-width="1"/>')

    def guide(self, x, y0, y1):
        """A dotted vertical marking a moment on a timeline."""
        self.add(f'<line x1="{x}" y1="{y0}" x2="{x}" y2="{y1}" stroke="{self.c["line"]}" stroke-width="1" '
                 f'stroke-dasharray="3 4"/>')

    def lifeline(self, x, y0, y1):
        self.add(f'<line x1="{x}" y1="{y0}" x2="{x}" y2="{y1}" stroke="{self.c["line"]}" stroke-width="1.2" '
                 f'stroke-dasharray="4 5"/>')

    def bracket(self, x0, x1, y, label=None, up=False, tick=6, weight=400, size=12):
        """A thin bracket along a span. Ticks point down at what it groups,
        label above; with up, ticks point up at what it measures, label below."""
        k = -tick if up else tick
        self.add(f'<path d="M{x0},{y + k} L{x0},{y} L{x1},{y} L{x1},{y + k}" fill="none" '
                 f'stroke="{self.c["line"]}" stroke-width="1.3"/>')
        if label:
            ly = y + 17 if up else y - 9
            self.text((x0 + x1) / 2, ly, label, size=size, weight=weight, color='label' if weight >= 600 else 'muted')

    # ------------------------------------------------------------ areas
    def rect(self, x, y, w, h, fill, r=0, op=1, stroke=None, sw=1.5, sop=1):
        st = f' stroke="{stroke}" stroke-width="{sw}" stroke-opacity="{sop}"' if stroke else ''
        self.add(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{r}" fill="{fill}" fill-opacity="{op}"{st}/>')

    def band(self, x, y, w, h, title):
        """A tinted container with its name in the top left corner."""
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="{self.c["band"]}" fill-opacity="0.12"/>')
        self.text(x + 16, y + 24, title, anchor='start', color='label', size=13, weight=600)

    def lane(self, x, y, w, h, title, sub=None):
        """A swimlane: the band's tint, its name and a short subtitle on the left."""
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="{self.c["band"]}" fill-opacity="0.12"/>')
        self.text(x + 18, y + h / 2 - (2 if sub else -4), title, anchor='start', color='label', size=13, weight=600)
        if sub:
            self.text(x + 18, y + h / 2 + 15, sub, anchor='start')

    def panel(self, x, y, w, h, centre_line=False):
        """A tinted panel holding a small plot; centre_line adds a faint zero line."""
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="10" fill="{self.c["band"]}" fill-opacity="0.12"/>')
        if centre_line:
            self.add(f'<line x1="{x + 10}" y1="{y + h / 2}" x2="{x + w - 10}" y2="{y + h / 2}" stroke="{self.c["line"]}" '
                     f'stroke-width="1" stroke-opacity="0.45"/>')

    def chip(self, x, y, t, w=None, size=12, mono=False, style='outline', h=28):
        """A pill centered on x. outline: one item of a list of cases; neutral
        and fail: a literal value, such as a URL."""
        c = self.c
        w = w or text_w(t, size, mono) + 24
        if style == 'outline':
            fill, op, tc = c['band'], 0.12, c['muted']
            st = f' stroke="{c["line"]}" stroke-opacity="0.55" stroke-width="1"'
        else:
            fill, op, tc = {'neutral': (c['neutral'], 1, c['ink']), 'fail': (c['failSoft'], 1, FAIL_INK)}[style]
            st = ''
        self.add(f'<rect x="{x - w / 2:.1f}" y="{y - h / 2}" width="{w:.1f}" height="{h}" rx="{h / 2}" fill="{fill}" '
                 f'fill-opacity="{op}"{st}/>')
        self.text(x, y + size * 0.36, t, size=size, mono=mono, color=tc)
        return w

    def chips(self, cx, y, items, gap=10, **kw):
        """A centered row of outline chips."""
        ws = [text_w(t, kw.get('size', 12)) + 24 for t in items]
        x = cx - (sum(ws) + gap * (len(ws) - 1)) / 2
        for t, w in zip(items, ws):
            self.chip(x + w / 2, y, t, w=w, **kw)
            x += w + gap

    def seg(self, x0, x1, y, h, label, role='lib', stripes=False, mono=True, size=13, r=6):
        """A segment of a state strip on a timeline."""
        c = self.c
        fill, tc = {'lib': (NAVY, '#FFFFFF'), 'ghost': (c['neutral'], INK2), 'fail': (c['failSoft'], FAIL_INK)}[role]
        self.add(f'<rect x="{x0}" y="{y - h / 2}" width="{x1 - x0}" height="{h}" rx="{r}" fill="{fill}"/>')
        if stripes:
            self.add(f'<rect x="{x0}" y="{y - h / 2}" width="{x1 - x0}" height="{h}" rx="{r}" fill="url(#stripes)"/>')
        self.add(f'<text x="{(x0 + x1) / 2}" y="{y + size * 0.36:.1f}" text-anchor="middle" '
                 f'font-family="{MONO if mono else SANS}" font-size="{size}" font-weight="600" fill="{tc}">{esc(label)}</text>')

    def track(self, x0, x1, y, h=12, kind='play'):
        """A track on a timeline: play is solid, bg (opened in the background) a dashed outline."""
        m = self.c['main']
        if kind == 'play':
            self.add(f'<rect x="{x0}" y="{y - h / 2}" width="{x1 - x0}" height="{h}" rx="{h / 2}" fill="{m}"/>')
        else:
            self.add(f'<rect x="{x0}" y="{y - h / 2}" width="{x1 - x0}" height="{h}" rx="{h / 2}" fill="{m}" '
                     f'fill-opacity="0.18" stroke="{m}" stroke-width="1.4" stroke-dasharray="4 3"/>')

    # ------------------------------------------------------------ marks
    def dot(self, x, y, kind='main', r=4.5):
        col = {'main': self.c['main'], 'sec': self.c['line'], 'fail': self.c['fail']}[kind]
        self.add(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{col}"/>')

    def badge(self, x, y, n, kind='main'):
        """A numbered step marker, for sequences."""
        self.dot(x, y, kind, r=11)
        self.add(f'<text x="{x}" y="{y + 4.2}" text-anchor="middle" font-family="{SANS}" font-size="12" '
                 f'font-weight="700" fill="#FFFFFF">{n}</text>')

    def cross(self, x, y, s=6, kind='line'):
        col = self.c[kind] if kind in self.c else kind
        self.add(f'<path d="M{x - s},{y - s} L{x + s},{y + s} M{x + s},{y - s} L{x - s},{y + s}" '
                 f'stroke="{col}" stroke-width="2.4" stroke-linecap="round"/>')

    def probe(self, x, y, y_end):
        """A tap: a dot on the signal wire and a stem down to its readout."""
        self.arrow(f'M{x},{y + 6} L{x},{y_end - 2}', kind='sec')
        self.dot(x, y, r=5.5)

    def trace(self, fn, x, y, w, amp, ghost=False, width=1.6):
        """A signal drawn as a line: blue, or grey and faint for the one before."""
        col = self.c['line'] if ghost else self.c['main']
        op = 0.5 if ghost else 1
        self.add(f'<path d="{wave_path(fn, x, y, w, amp)}" fill="none" stroke="{col}" stroke-opacity="{op}" '
                 f'stroke-width="{1.2 if ghost else width}" stroke-linejoin="round"/>')

    # ------------------------------------------------------------ glyphs
    def doc(self, x, y, w, h, fold=16):
        """A file glyph with a folded corner, neutral fill."""
        c = self.c
        self.add(f'<path d="M{x + 6},{y} L{x + w - fold},{y} L{x + w},{y + fold} L{x + w},{y + h - 6} '
                 f'Q{x + w},{y + h} {x + w - 6},{y + h} L{x + 6},{y + h} Q{x},{y + h} {x},{y + h - 6} '
                 f'L{x},{y + 6} Q{x},{y} {x + 6},{y} Z" fill="{c["neutral"]}"/>')
        self.add(f'<path d="M{x + w - fold},{y} L{x + w - fold},{y + fold - 4} Q{x + w - fold},{y + fold} '
                 f'{x + w - fold + 4},{y + fold} L{x + w},{y + fold} Z" fill="#C3CBD8"/>')

    def picture(self, x, y, w, h, fill=None):
        """A small image glyph: a frame, a sun and two hills."""
        f = fill or self.c['main']
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" fill="{f}"/>')
        self.add(f'<circle cx="{x + w * 0.72}" cy="{y + h * 0.32}" r="{h * 0.11:.1f}" fill="#FFFFFF" fill-opacity="0.85"/>')
        self.add(f'<path d="M{x + 4},{y + h - 4} L{x + w * 0.36},{y + h * 0.45} L{x + w * 0.58},{y + h * 0.72} '
                 f'L{x + w * 0.72},{y + h * 0.58} L{x + w - 4},{y + h - 4} Z" fill="#FFFFFF" fill-opacity="0.55"/>')

    def transport(self, cx, cy, s=1.0, col='#1F2328', gap=14):
        """Media controls glyphs: previous, play, next, as small ink shapes."""
        def tri(x, y, d):
            h = 4.2 * s
            return f'M{x - d * h:.1f},{y - h:.1f} L{x + d * h:.1f},{y:.1f} L{x - d * h:.1f},{y + h:.1f} z'
        g = gap * s
        p = [f'M{cx - g - 4.6 * s:.1f},{cy - 3.8 * s:.1f} h{1.6 * s:.1f} v{7.6 * s:.1f} h{-1.6 * s:.1f} z',
             tri(cx - g + 0.8 * s, cy, -0.75), tri(cx + 0.6 * s, cy, 1.05), tri(cx + g - 0.8 * s, cy, 0.75),
             f'M{cx + g + 3.0 * s:.1f},{cy - 3.8 * s:.1f} h{1.6 * s:.1f} v{7.6 * s:.1f} h{-1.6 * s:.1f} z']
        self.add(f'<path d="{" ".join(p)}" fill="{col}"/>')

    def now_playing(self, x, y, w, h, art='left', prog=True, s=1.0):
        """A stylized now-playing card on a neutral fill: artwork, title and
        artist lines, progress, transport. Every piece is something the
        session publishes."""
        c = self.c
        self.rect(x, y, w, h, c['neutral'], r=6 * s)
        a = min(h - 16 * s, 20 * s) if art else 0
        ax = x + 6 * s if art == 'left' else x + w - 6 * s - a
        if art:
            self.rect(ax, y + 6 * s, a, a, c['line'], r=3 * s)
        tx = ax + a + 6 * s if art == 'left' else x + 6 * s
        tw = (w - a - 18 * s) if art else w - 12 * s
        self.rect(tx, y + 7 * s, tw * 0.72, 4.5 * s, c['ink'], r=2 * s, op=0.75)
        self.rect(tx, y + 15 * s, tw * 0.5, 4 * s, INK2, r=2 * s, op=0.55)
        py = y + 6 * s + a + 6 * s
        if prog:
            self.rect(x + 6 * s, py, w - 12 * s, 3 * s, c['line'], r=1.5 * s, op=0.45)
            self.rect(x + 6 * s, py, (w - 12 * s) * 0.38, 3 * s, c['main'], r=1.5 * s)
            py += 3 * s
        self.transport(x + w / 2, (py + y + h) / 2, s=s)
