"""Generates the README diagrams in imgs/diagrams.

Library nodes use the icon's navy plate gradient and your code's nodes the
cyan-to-white bars gradient. Each diagram is written as SVG and exported to
PNG at 2x with rsvg-convert on a white ground, so it reads the same in
GitHub's light and dark themes and on pub.dev. PAL keeps a dark palette in
case a dark variant is wanted again.

Run from the repository root: python3 tool/diagrams/generate.py
"""
import os, subprocess

OUT = os.path.join('imgs', 'diagrams')
SANS = "Noto Sans, system-ui, -apple-system, Segoe UI, sans-serif"
MONO = "Noto Sans Mono, ui-monospace, SFMono-Regular, Menlo, monospace"

PAL = {
    'light': dict(ink='#1F2328', muted='#59636E', line='#8C95A3', main='#123A9C',
                  fail='#B42318', failSoft='#FDE3E0', neutral='#E9EEF6', band='#F4F6FA'),
    'dark': dict(ink='#E6EDF3', muted='#9AA4B2', line='#6E7887', main='#5CE1F7',
                 fail='#FF7B72', failSoft='#3A1D20', neutral='#1F2735', band='#141A23'),
}


def esc(t):
    return t.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


class D:
    def __init__(self, name, w, h, theme, label):
        self.name, self.w, self.h, self.t, self.c = name, w, h, theme, PAL[theme]
        self.label = label
        self.body = []

    def add(self, s):
        self.body.append(s)

    def svg(self):
        c = self.c
        defs = f'''<defs>
<linearGradient id="plate" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#123A9C"/><stop offset="1" stop-color="#081A4D"/></linearGradient>
<linearGradient id="bars" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#5CE1F7"/><stop offset="1" stop-color="#FFFFFF"/></linearGradient>
{''.join(f'<marker id="m{n}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{col}"/></marker>' for n, col in (('main', c['main']), ('sec', c['line']), ('fail', c['fail'])))}
</defs>'''
        return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {self.w} {self.h}" width="{self.w}" height="{self.h}" '
                f'role="img" aria-label="{esc(self.label)}">\n{defs}\n' + '\n'.join(self.body) + '\n</svg>\n')

    # role: lib (navy plate), app (cyan bars), neutral, fail, ghost (dashed outline)
    def node(self, x, y, w, h, title, sub=None, role='lib', mono=True, r=None, sub2=None, size=15):
        c = self.c
        r = h / 2 if r is None else r
        if role == 'lib':
            fill, tc, sc, op = 'url(#plate)', '#FFFFFF', '#C9DBFF', 1
        elif role == 'app':
            fill, tc, sc, op = 'url(#bars)', '#0B2A7A', '#2A4A8F', 1
        elif role == 'fail':
            fill, tc, sc, op = c['failSoft'], c['fail'], c['muted'], 1
        elif role == 'ghost':
            fill, tc, sc, op = c['neutral'], c['muted'], c['muted'], 0.6
        else:
            fill, tc, sc, op = c['neutral'], c['ink'], c['muted'], 1
        self.add(f'<rect x="{x - w / 2}" y="{y - h / 2}" width="{w}" height="{h}" rx="{r}" fill="{fill}" fill-opacity="{op}"/>')
        lines = [s for s in (sub, sub2) if s]
        ty = y + 5 - 9 * len(lines)
        self.add(f'<text x="{x}" y="{ty}" text-anchor="middle" font-family="{MONO if mono else SANS}" font-size="{size}" font-weight="600" fill="{tc}">{esc(title)}</text>')
        for i, s in enumerate(lines):
            self.add(f'<text x="{x}" y="{ty + 19 + 16 * i}" text-anchor="middle" font-family="{SANS}" font-size="12" fill="{sc}">{esc(s)}</text>')

    def arrow(self, d, kind='main', dash=False, head=True, width=None):
        c = self.c
        col = {'main': c['main'], 'sec': c['line'], 'fail': c['fail']}[kind]
        w = width or (2.2 if kind == 'main' else 1.7)
        dsh = ' stroke-dasharray="5 5"' if dash else ''
        mk = f' marker-end="url(#m{kind})"' if head else ''
        self.add(f'<path d="{d}" fill="none" stroke="{col}" stroke-width="{w}"{dsh}{mk}/>')

    def text(self, x, y, t, anchor='middle', color='muted', size=12, mono=False, weight=400):
        col = self.c.get(color, color)
        self.add(f'<text x="{x}" y="{y}" text-anchor="{anchor}" font-family="{MONO if mono else SANS}" font-size="{size}" font-weight="{weight}" fill="{col}">{esc(t)}</text>')

    def band(self, x, y, w, h, title):
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="{self.c["band"]}"/>')
        self.text(x + 16, y + 24, title, anchor='start', color='muted', size=12, weight=600)


def architecture(t):
    d = D('architecture', 900, 470, t, 'Architecture: main isolate, event isolate, libmpv and the OS')
    d.band(20, 20, 860, 150, 'Your app, main isolate')
    d.node(170, 105, 230, 64, 'Your UI', 'widgets, StreamBuilder', role='app', mono=False)
    d.node(450, 105, 230, 64, 'Player', 'state, stream, setters', role='lib')
    d.node(730, 105, 230, 64, 'Media session', 'controller in Dart', role='lib', mono=False)
    d.arrow('M285,95 L333,95'); d.arrow('M335,115 L287,115', kind='sec')
    d.text(310, 84, 'calls', size=11); d.text(310, 134, 'streams', size=11)
    d.arrow('M565,105 L613,105')
    d.band(20, 200, 560, 110, 'Background')
    d.node(170, 265, 230, 60, 'Event isolate', 'mpv_wait_event loop', role='lib', mono=False)
    d.node(450, 265, 230, 60, 'libmpv', 'mpv 0.41 and ffmpeg', role='lib')
    d.arrow('M450,137 L450,233'); d.text(458, 190, 'mpv_*_async', anchor='start', size=11, mono=True)
    d.arrow('M335,265 L287,265', kind='sec'); d.text(311, 255, 'events', size=11)
    d.arrow('M240,235 L240,185 L390,185 L390,139', kind='sec'); d.text(232, 214, 'state, replies', anchor='end', size=11)
    d.node(730, 265, 230, 60, 'Platform plugin', 'Media3, Now Playing,', sub2='MPRIS, SMTC', role='neutral', mono=False)
    d.arrow('M730,137 L730,233', kind='sec', head=True); d.arrow('M745,233 L745,139', kind='sec')
    d.text(760, 190, 'commands', anchor='start', size=11)
    d.node(450, 400, 230, 56, 'Audio driver', 'WASAPI, CoreAudio, AAudio,', sub2='PipeWire and others', role='neutral', mono=False)
    d.node(730, 400, 230, 56, 'OS media controls', 'lock screen, notification', role='neutral', mono=False)
    d.arrow('M450,297 L450,370'); d.arrow('M730,297 L730,370', kind='sec')
    return d


def lifecycle(t):
    d = D('player_lifecycle', 1000, 150, t, 'Player lifecycle')
    steps = [('ensureInitialized()', 'once, at app start', 'lib'), ('Player()', 'one per session', 'lib'),
             ('open()', 'or openAll()', 'app'), ('stream and setters', 'listen and control', 'app'),
             ('dispose()', 'releases libmpv', 'lib')]
    for i, (a, b, role) in enumerate(steps):
        x = 105 + i * 197
        d.node(x, 75, 180, 64, a, b, role=role, size=14)
        if i:
            d.arrow(f'M{x - 197 + 91},75 L{x - 93},75')
    return d


def effects(t):
    d = D('effects_chain', 920, 340, t, 'Effects chain with taps')
    d.node(80, 125, 120, 60, 'Decoder', role='neutral', mono=False)
    d.band(170, 55, 560, 120, 'setAudioEffects([...]), in list order')
    stages = [('EqualizerEffect', 'lib'), ('AcompressorEffect', 'lib'), ('RawAudioEffect', 'app')]
    xs = [270, 455, 640]
    for (n, role), x in zip(stages, xs):
        d.node(x, 125, 150, 50, n, role=role, size=13)
    d.arrow('M140,125 L193,125')
    d.arrow('M345,125 L378,125'); d.arrow('M530,125 L563,125')
    d.node(835, 125, 150, 60, 'Volume', 'then the driver', role='neutral', mono=False)
    d.arrow('M715,125 L758,125')
    # taps: pre on the way into the equalizer, post on the way out
    for x in (163, 358):
        d.add(f'<circle cx="{x}" cy="125" r="4.5" fill="{d.c["main"]}"/>')
        d.arrow(f'M{x},130 L{x},222', kind='sec')
    d.node(163, 245, 100, 40, 'pre', role='app', size=13); d.node(358, 245, 100, 40, 'post', role='app', size=13)
    d.text(163, 296, 'stream.tap(AudioFilter.equalizer, side: ...)', anchor='start', size=12, mono=True, color='ink')
    d.text(163, 316, 'instance counts repeats of the same filter', anchor='start', size=12)
    d.arrow('M835,157 L835,222', kind='sec')
    d.node(835, 245, 150, 40, 'fft and pcm', role='app', size=13)
    return d


def timeline(t):
    d = D('play_when_ready', 900, 300, t, 'playWhenReady and playing over time')
    x0, x1 = 170, 870
    marks = [(210, 'play()'), (390, 'seek()'), (560, 'network stall'), (760, 'pause()')]
    for x, m in marks:
        d.add(f'<line x1="{x}" y1="40" x2="{x}" y2="250" stroke="{d.c["line"]}" stroke-width="1" stroke-dasharray="3 4"/>')
        d.text(x, 32, m, mono=m.endswith(')'), color='ink', size=12)
    rows = [('playWhenReady', 110, [(x0, 0), (210, 1), (760, 0)]),
            ('playing', 200, [(x0, 0), (230, 1), (390, 0), (430, 1), (560, 0), (650, 1), (760, 0)])]
    for name, y, pts in rows:
        d.text(20, y - 12, name, anchor='start', mono=True, color='ink', size=14, weight=600)
        path = f'M{x0},{y}'
        lvl = 0
        for i, (x, v) in enumerate(pts):
            yy = y - 40 * v
            path += f' L{x},{y - 40 * lvl} L{x},{yy}'
            lvl = v
        path += f' L{x1},{y - 40 * lvl}'
        d.arrow(path, head=False, width=2.6)
        d.text(165, y + 4, 'false', anchor='end', size=11); d.text(165, y - 36, 'true', anchor='end', size=11)
    d.text(410, 275, 'playing flips for the seek and the stall; playWhenReady does not', size=12)
    return d


def prefetch(t):
    d = D('mpv_prefetch_state', 820, 340, t, 'Prefetch lifecycle')
    S = [('idle', 90, 80, 'nothing pending', 'ghost'), ('loading', 290, 80, 'opening next entry', 'lib'),
         ('ready', 490, 80, 'open and cached', 'lib'), ('used', 690, 80, 'track changed to it', 'lib'),
         ('failed', 290, 215, 'could not open', 'fail')]
    d.arrow('M165,80 L213,80'); d.text(189, 68, 'start', size=11)
    d.arrow('M365,80 L413,80'); d.text(389, 68, 'cached', size=11)
    d.arrow('M565,80 L613,80'); d.text(589, 68, 'switch', size=11)
    d.arrow('M290,112 L290,181', kind='fail'); d.text(298, 152, 'error', anchor='start', size=11, color='fail')
    d.arrow('M215,215 L185,215 L185,98 L213,98', kind='sec'); d.text(177, 176, 'next prefetch', anchor='end', size=11)
    d.arrow('M690,48 L690,26 L290,26 L290,46', kind='sec'); d.text(490, 18, 'next prefetch', size=11)
    d.add(f'<path d="M490,112 L490,295 M690,112 L690,295 M490,295 L690,295" fill="none" stroke="{d.c["line"]}" stroke-width="1.7" stroke-dasharray="5 5"/>')
    d.arrow('M490,295 L90,295 L90,114', kind='sec', dash=True); d.text(590, 317, 'cancel or dropped', size=11)
    d.text(290, 272, 'a cancel does not reset failed', size=11)
    for k, x, y, sub, role in S:
        d.node(x, y, 150, 64, k, sub, role=role)
    return d


def cover(t):
    d = D('cover_art_flow', 900, 290, t, 'Where cover art comes from')
    d.node(120, 80, 200, 64, 'Embedded picture', 'inside the audio file', role='neutral', mono=False)
    d.node(390, 80, 200, 64, 'stream.coverArt', 'CoverArt bytes, or null', role='lib', size=14)
    d.node(680, 80, 240, 64, 'Image(image: art.image)', 'your widget', role='app', size=13)
    d.arrow('M220,80 L288,80'); d.arrow('M490,80 L558,80')
    d.node(120, 215, 200, 64, 'Image in the folder', 'setCoverArtAuto(...)', role='neutral', mono=False)
    d.node(390, 215, 200, 64, 'state.tracks', 'albumArt, externalFilename', role='lib', size=14)
    d.node(680, 215, 240, 64, 'File(path)', 'you read the file', role='app', size=14)
    d.arrow('M220,215 L288,215', kind='sec'); d.arrow('M490,215 L558,215', kind='sec')
    d.text(450, 150, 'an external image never reaches stream.coverArt', size=12)
    return d


def errors(t):
    d = D('error_streams', 900, 340, t, 'Error, end of file, audio output and log streams')
    d.node(450, 60, 220, 60, 'Player', 'events from mpv', role='lib')
    items = [(115, 'stream.error', 'EndFileError, LogError', 'lib'), (335, 'stream.endFile', 'every file end', 'lib'),
             (565, 'audioOutputState', 'closed, initializing,', 'lib'), (785, 'log, internalLog', "mpv's and the library's", 'lib')]
    for x, a, b, role in items:
        d.node(x, 215, 200, 72, a, b, role=role, size=14, sub2='active, failed' if a == 'audioOutputState' else None)
        d.arrow(f'M450,92 L450,130 L{x},130 L{x},177')
    d.arrow('M565,253 L565,290 L115,290 L115,253', kind='fail', dash=True)
    d.text(340, 312, 'failed also emits a LogError', size=12, color='fail')
    return d


def hook(t):
    d = D('on_load_hook_sequence', 900, 400, t, 'on_load hook sequence')
    cols = [(150, 'Your code', 'app'), (450, 'Player', 'lib'), (750, 'mpv', 'lib')]
    for x, n, role in cols:
        d.node(x, 45, 170, 50, n, role=role, mono=False)
        d.add(f'<line x1="{x}" y1="72" x2="{x}" y2="385" stroke="{d.c["line"]}" stroke-width="1.2" stroke-dasharray="4 5"/>')
    steps = [(150, 450, 105, 'registerHook(Hook.load)', 'main'), (450, 750, 145, 'registers on_load', 'sec'),
             (750, 450, 195, 'on_load: waits for you', 'sec'), (450, 150, 235, 'stream.hook event', 'sec'),
             (150, 150, 275, 'setRawProperty(...)', 'main'),
             (150, 450, 320, 'continueHook(event.id)', 'main'), (450, 750, 360, 'mpv opens the stream', 'sec')]
    for a, b, y, label, kind in steps:
        if a == b:
            d.arrow(f'M{a},{y - 8} L{a + 45},{y - 8} L{a + 45},{y + 12} L{a + 6},{y + 12}', kind=kind)
            d.text(a + 70, y + 6, label, anchor='start', mono=True, color='ink', size=12)
        else:
            d.arrow(f'M{a},{y} L{b + (8 if b < a else -8)},{y}', kind=kind)
            d.text((a + b) / 2, y - 9, label, mono='(' in label or '.' in label, color='ink', size=12)
    return d


def resolver(t):
    d = D('source_resolver', 900, 330, t, 'Source resolver: on_load and one retry')
    d.node(110, 70, 170, 56, 'on_load', 'before each open', role='lib')
    d.node(360, 70, 220, 56, 'your resolver', 'request.media, extras', role='app')
    d.node(640, 70, 220, 56, 'mpv opens', 'the returned URL', role='lib', mono=False)
    d.arrow('M195,70 L248,70'); d.arrow('M470,70 L528,70'); d.text(499, 58, 'URL or null', size=11)
    d.node(640, 190, 220, 56, 'on_load_fail', 'the open failed', role='fail')
    d.arrow('M640,98 L640,160', kind='fail')
    d.node(360, 190, 220, 56, 'your resolver', 'request.isRetry is true', role='app')
    d.arrow('M530,190 L472,190', kind='sec')
    d.arrow('M360,162 L360,100', kind='main'); d.text(368, 135, 'new URL: one retry', anchor='start', size=11)
    d.node(360, 290, 220, 44, 'error', 'same URL or null', role='fail', r=22)
    d.arrow('M360,218 L360,266', kind='fail')
    d.node(110, 190, 170, 56, 'Hook.load', 'your hook, if any', role='ghost')
    d.arrow('M110,98 L110,160', kind='sec', dash=True); d.text(118, 135, 'runs after', anchor='start', size=11)
    return d


def spectrum(t):
    d = D('spectrum_pipeline', 900, 260, t, 'Spectrum pipeline')
    d.node(95, 80, 150, 64, 'Audio output', 'after the chain', role='neutral', mono=False)
    d.node(270, 80, 140, 64, 'Window', 'hann by default', role='lib', mono=False)
    d.node(430, 80, 130, 64, 'FFT', 'fftSize', role='lib', mono=False)
    d.node(595, 80, 150, 64, 'Log bands', 'bandCount', role='lib', mono=False)
    d.node(770, 80, 150, 64, 'Smoothing', 'attack, release', role='lib', mono=False)
    for a, b in ((170, 200), (340, 365), (495, 520), (670, 695)):
        d.arrow(f'M{a},80 L{b - 2},80')
    d.node(770, 200, 190, 56, 'stream.fft', 'FftFrame: bands, bins', role='app', size=14)
    d.arrow('M770,112 L770,170')
    d.node(95, 200, 170, 56, 'stream.pcm', 'PcmFrame: samples', role='app', size=14)
    d.arrow('M95,112 L95,170', kind='sec')
    d.text(430, 205, 'every emitInterval, 33 ms by default', size=12)
    return d


def media(t):
    d = D('media_session_flow', 900, 330, t, 'OS media session')
    d.node(150, 110, 220, 64, 'Player', 'setMediaSession(...)', role='lib', size=15)
    d.node(450, 110, 220, 64, 'Media session', 'metadata, state, actions', role='lib', mono=False)
    d.arrow('M260,100 L338,100'); d.arrow('M340,122 L262,122', kind='sec')
    d.text(300, 88, 'now playing', size=11); d.text(300, 142, 'commands', size=11)
    osn = [('iOS', 'Now Playing'), ('macOS', 'Control Center'), ('Android', 'notification'), ('Windows', 'SMTC'), ('Linux', 'MPRIS')]
    for i, (a, b) in enumerate(osn):
        y = 40 + i * 58
        d.node(760, y + 12, 190, 46, a, b, role='neutral', mono=False, size=14)
        d.arrow(f'M610,{y + 12} L663,{y + 12}', kind='sec')
    d.arrow('M560,110 L610,110', kind='sec', head=False)
    d.add(f'<path d="M610,52 L610,284" fill="none" stroke="{d.c["line"]}" stroke-width="1.7"/>')
    d.node(190, 255, 300, 56, 'stream.mediaSessionCommands', 'the player applies them too', role='app', size=13)
    d.arrow('M150,142 L150,225', kind='sec')
    return d


ALL = [architecture, lifecycle, effects, timeline, prefetch, cover, errors, hook, resolver, spectrum, media]
os.makedirs(OUT, exist_ok=True)
for f in ALL:
    d = f('light')
    svg = os.path.join(OUT, f'{d.name}.svg')
    with open(svg, 'w') as fh:
        fh.write(d.svg())
    subprocess.run(['rsvg-convert', '-z', '2', '-b', '#FFFFFF', svg, '-o', svg[:-4] + '.png'], check=True)
print(len(ALL), 'diagrams written to', OUT)
