"""Choices and routes: tls_trust, web_pipeline, libmpv_bundling and
stop_keep_playlist."""
from base import D, M, NAVY, INK2, SANS


def _mark(d, x, y, kind):
    """A result in a grid: ok (blue tick), fail (red cross) or unchecked
    (a grey tick, it opens with nothing verified)."""
    col = {'ok': d.c['main'], 'fail': d.c['fail'], 'unchecked': d.c['neutral']}[kind]
    # the grey disc gets an edge, or it vanishes on a white page
    edge = f' stroke="{d.c["line"]}" stroke-opacity="0.6" stroke-width="1"' if kind == 'unchecked' else ''
    d.add(f'<circle cx="{x}" cy="{y}" r="13" fill="{col}"{edge}/>')
    if kind == 'fail':
        s = 4.6
        d.add(f'<path d="M{x - s},{y - s} L{x + s},{y + s} M{x + s},{y - s} L{x - s},{y + s}" '
              f'stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round"/>')
    else:
        ink = '#FFFFFF' if kind == 'ok' else INK2
        d.add(f'<path d="M{x - 5.5},{y + 0.5} L{x - 1.5},{y + 4.5} L{x + 6},{y - 4.5}" fill="none" '
              f'stroke="{ink}" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>')


# ── tls_trust: which servers open with each TLS setting ─────────────────────
def tls_trust(t):
    d = D('tls_trust', 470, t, 'Which servers open with each TLS setting: the built-in roots, an extra CA file, '
          'a CA file in place of the roots, and verification off')
    LX = M + 160                                  # center of the settings column
    cols = [(560, 'https://radio.example', 'a public CA signed it'),
            (735, 'https://nas.local', 'self-signed, in nas.pem'),
            (890, 'http://nas.local', 'no TLS')]
    for x, a, b in cols:
        d.text(x, 40, a, mono=True, size=12, color='label', weight=600)
        d.text(x, 58, b)
    rows = [("default", "tlsVerify: true", "the roots built into libmpv", ['ok', 'fail', 'unchecked']),
            ("setTlsExtraCaFile('nas.pem')", None, "the roots, plus the file", ['ok', 'ok', 'unchecked']),
            ("setTlsCaFile('nas.pem')", None, "the file, in place of the roots", ['fail', 'ok', 'unchecked']),
            ("tlsVerify: false", None, "nothing is checked", ['unchecked', 'unchecked', 'unchecked'])]
    y0, step = 116, 76
    # the row a home server wants
    d.rect(M, y0 + step - 34, d.w - 2 * M, 68, d.c['band'], r=14, op=0.12)
    for i, (title, code, sub, marks) in enumerate(rows):
        y = y0 + i * step
        d.node(LX, y, 300, 56, title, sub, role='neutral', size=13)
        d.outline(LX, y, 300, 56)
        for (x, _, _), k in zip(cols, marks):
            _mark(d, x, y, k)
    d.text(LX + 160, y0 + step + 4, 'a home server', anchor='start', color='label', weight=600)
    d.text(LX + 160, y0 + step + 21, 'and every other one', anchor='start')
    yl = y0 + 4 * step - 22
    for x, k, t in ((300, 'ok', 'opens, its certificate checked'), (560, 'fail', 'fails to open'),
                    (750, 'unchecked', 'opens, nothing checked')):
        _mark(d, x - 22, yl, k)
        d.text(x - 2, yl + 4, t, anchor='start')
    d.caption('The host name in the URL must still match the certificate. Local files and smb2:// use no TLS.')
    return d


# ── web_pipeline: where each part of the player runs in a browser ──────────
def web_pipeline(t):
    d = D('web_pipeline', 560, t, 'The player in a browser: the page, the workers of the module, the audio '
          'thread and the browser')
    X0, W = M, d.w - 2 * M
    L = [(20, 112, 'Main thread', 'the page, Dart'),
         (148, 128, 'Web workers', "libmpv's threads"),
         (292, 104, 'Audio thread', 'an AudioWorklet'),
         (412, 104, 'The browser', 'network and sound')]
    for y, h, a, b in L:
        d.lane(X0, y, W, h, a, b)
    yc = [y + h / 2 for y, h, _, _ in L]
    UI, PL, NET = 245, 520, 790
    d.node(UI, yc[0], 170, 60, 'Your UI', 'widgets, StreamBuilder', role='app', mono=False)
    d.node(PL, yc[0], 200, 60, 'Player', 'the same Dart API', role='lib')
    d.arrow(f'M{UI + 87},{yc[0] - 9} L{PL - 102},{yc[0] - 9}')
    d.arrow(f'M{PL - 102},{yc[0] + 9} L{UI + 87},{yc[0] + 9}', kind='sec')
    d.text((UI + PL) / 2, yc[0] - 18, 'calls'); d.text((UI + PL) / 2, yc[0] + 27, 'streams')
    # the module
    d.node(PL, yc[1], 250, 68, 'libmpv.wasm', 'mpv and FFmpeg as WebAssembly,', sub2='one module for every player')
    d.node(NET, yc[1], 180, 68, 'net thread', 'reads http and https', sub2='through fetch')
    d.arrow(f'M{PL - 30},{yc[0] + 30} L{PL - 30},{yc[1] - 36}')
    d.arrow(f'M{PL + 30},{yc[1] - 36} L{PL + 30},{yc[0] + 30}', kind='sec')
    d.text(PL - 40, (yc[0] + 30 + yc[1] - 34) / 2 + 4, 'mpv_* calls', anchor='end')
    d.text(PL + 40, (yc[0] + 30 + yc[1] - 34) / 2 + 4, 'events', anchor='start')
    d.arrow(f'M{PL + 127},{yc[1] - 9} L{NET - 92},{yc[1] - 9}', kind='sec', both=True)
    # audio
    d.node(PL, yc[2], 250, 56, 'mak_webaudio_processor', 'plays what the ring holds', size=13)
    d.arrow(f'M{PL},{yc[1] + 36} L{PL},{yc[2] - 30}')
    d.text(PL + 10, (yc[1] + 34 + yc[2] - 28) / 2 + 4, 'PCM, a ring in shared memory', anchor='start')
    # the browser
    d.node(PL, yc[3], 250, 56, 'AudioContext', 'starts on a tap, a click or a key', role='neutral', mono=False)
    d.outline(PL, yc[3], 250, 56)
    d.node(NET, yc[3], 180, 56, 'fetch', 'CORS, TLS and cookies', role='neutral', mono=False)
    d.outline(NET, yc[3], 180, 56)
    d.arrow(f'M{PL},{yc[2] + 30} L{PL},{yc[3] - 30}')
    d.arrow(f'M{NET},{yc[1] + 36} L{NET},{yc[3] - 30}', kind='sec', both=True)
    d.text(NET + 10, yc[2] + 4, 'requests, bytes', anchor='start')
    # what the page must allow
    d.caption('The threads share one memory, which the browser allows only with COOP and COEP on every response.')
    return d


# ── libmpv_bundling: how each toolchain gets its libmpv ─────────────────────
def libmpv_bundling(t):
    rows = [('Flutter', 'Android, iOS, macOS, Windows, Linux', 'the build hook downloads it,', 'checked against its SHA-256',
             'libmpv_<platform>', 'of the target and its arch'),
            ('Flutter web', 'a cross-origin isolated page', 'no hook: the web assets', 'of the package',
             'libmpv.mjs, libmpv.wasm', 'and the AudioWorklet module'),
            ('flutter-tvos', 'Apple TV', 'the hook bundles nothing:', 'tvos/Package.swift links it',
             'libmpv_tvos', 'an xcframework, through SwiftPM'),
            ('flutter-tizen', 'Samsung TVs', 'the hook sees linux: arm,', 'or x64 with tizen: true',
             'libmpv_tizen', 'armv7l, x86_64 for the emulator'),
            ('Flutter-OH', 'OpenHarmony, HarmonyOS', 'the hook sees linux: the SDK', 'clang, or ohos: true',
             'libmpv_ohos', 'arm64-v8a, x86_64 for the emulator'),
            ('flutter-webos', 'LG TVs', 'no hook: webos/CMakeLists.txt', 'downloads it, with its SHA-256',
             'libmpv_webos', 'armv7l')]
    step = 74
    d = D('libmpv_bundling', 90 + step * len(rows) + 30, t,
          'How each Flutter toolchain gets its libmpv: the build hook, the web assets, SwiftPM or CMake')
    TX, HX, FX = M + 115, 480, d.w - M - 125
    for x, h in ((TX, 'toolchain'), (HX, 'how it gets libmpv'), (FX, 'what the app bundles')):
        d.heading(x, 40, h, anchor='middle')
    for i, (a, b, h1, h2, f1, f2) in enumerate(rows):
        y = 100 + i * step
        d.node(TX, y, 230, 56, a, b, role='app', mono=False)
        d.node(HX, y, 270, 56, h1, h2, role='neutral', mono=False, size=12)
        d.outline(HX, y, 270, 56)
        d.node(FX, y, 250, 56, f1, f2, role='lib', size=13)
        d.arrow(f'M{TX + 117},{y} L{HX - 139},{y}', kind='sec')
        d.arrow(f'M{HX + 137},{y} L{FX - 129},{y}')
    d.caption([('The ', 'text'), ('libmpv', 'code'), (' user define, or ', 'text'), ('MPV_AUDIO_KIT_LIBMPV', 'code'),
               (' on webOS, bundles a build of your own instead.', 'text')])
    return d


# ── stop_keep_playlist: stop() against stop(keepPlaylist: true) ─────────────
def _queue(d, cx, y, current, mode, empty=False):
    """Four entries A to D, centered on cx. mode: plays (the current entry
    navy), held (outlined: the index is there, nothing loaded)."""
    s, g = 34, 8
    x0 = cx - (4 * s + 3 * g) / 2
    if empty:
        d.rect(x0, y - s / 2, 4 * s + 3 * g, s, d.c['neutral'], r=6)
        d.text(cx, y + 4, 'empty', color=INK2)
        return
    for i, n in enumerate('ABCD'):
        x = x0 + i * (s + g)
        if n == current and mode == 'plays':
            d.rect(x, y - s / 2, s, s, NAVY, r=6, stroke=d.c['line'], sw=1, sop=0.5)
            col = '#FFFFFF'
        elif n == current:
            d.rect(x, y - s / 2, s, s, d.c['main'], r=6, op=0.15, stroke=d.c['main'], sw=2)
            col = d.c['main']
        else:
            d.rect(x, y - s / 2, s, s, d.c['neutral'], r=6)
            col = INK2
        d.add(f'<text x="{x + s / 2}" y="{y + 5}" text-anchor="middle" font-family="{SANS}" '
              f'font-size="14" font-weight="600" fill="{col}">{n}</text>')


def stop_keep_playlist(t):
    d = D('stop_keep_playlist', 350, t, 'stop() clears the playlist; stop(keepPlaylist: true) keeps it, with the '
          'index on the entry that stopped')
    xs = [110, 365, 615, 850]
    # stop()
    y1 = 70
    d.heading(M, 30, 'stop(): the playlist goes', mono=True)
    _queue(d, xs[0], y1, 'B', 'plays')
    d.text(xs[0], y1 + 38, 'B plays')
    d.arrow(f'M{xs[0] + 90},{y1} L{xs[1] - 95},{y1}')
    d.text((xs[0] + xs[1]) / 2, y1 - 9, 'stop()', mono=True, color='label')
    _queue(d, xs[1], y1, None, None, empty=True)
    d.text(xs[1], y1 + 38, 'no playlist, nothing loaded')
    d.rule(140)
    # stop(keepPlaylist: true)
    y2 = 220
    d.heading(M, 180, 'stop(keepPlaylist: true): the playlist stays', mono=True)
    states = [('B', 'plays', 'B plays'), ('B', 'held', 'the index stays on B'), ('C', 'held', 'the index moves to C'),
              ('C', 'plays', 'C plays from its start')]
    for x, (cur, mode, lab) in zip(xs, states):
        _queue(d, x, y2, cur, mode)
        d.text(x, y2 + 38, lab)
    # the heading gives the whole call, longer than the gap
    for (a, b), lab in zip(zip(xs, xs[1:]), ['stop(…)', 'next()', 'play()']):
        d.arrow(f'M{a + 90},{y2} L{b - 95},{y2}')
        d.text((a + b) / 2, y2 - 9, lab, mono=True, color='label')
    d.text(xs[1], y2 + 56, 'nothing loaded')
    d.text(xs[2], y2 + 56, 'still nothing loaded')
    yl = 310
    d.rect(300, yl - 11, 14, 14, NAVY, r=3, stroke=d.c['line'], sw=1, sop=0.5)
    d.text(322, yl, 'the entry that plays', anchor='start')
    d.rect(500, yl - 11, 14, 14, d.c['main'], r=3, op=0.15, stroke=d.c['main'], sw=2)
    d.text(522, yl, 'the index, nothing loaded', anchor='start')
    return d
