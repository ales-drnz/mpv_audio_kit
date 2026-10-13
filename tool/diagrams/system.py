"""System and time diagrams: architecture, analysis_cache_feed,
media_session_flow and play_when_ready."""
import math

from base import D, M, NAVY, ON_NAVY, INK2


# ── architecture: four lanes, the messages that cross them ─────────────────
def architecture(t):
    d = D('architecture', 536, t, 'Architecture: main isolate, event isolate, native threads and the OS')
    X0, W = M, d.w - 2 * M
    L = [(20, 120, 'Main isolate', 'Dart, the UI thread'),
         (156, 112, 'Event isolate', 'Dart, background'),
         (284, 120, 'Native threads', 'libmpv and the plugin'),
         (420, 96, 'Operating system', 'drivers and system UI')]
    for y, h, a, b in L:
        d.lane(X0, y, W, h, a, b)
    yc = [y + h / 2 for y, h, _, _ in L]
    UI, PL, MS = 270, 525, 815
    # main isolate
    d.node(UI, yc[0], 170, 60, 'Your UI', 'widgets, StreamBuilder', role='app', mono=False)
    d.node(PL, yc[0], 200, 60, 'Player', 'state, stream, setters', role='lib')
    d.node(MS, yc[0], 180, 60, 'Media session', 'controller in Dart', role='lib', mono=False)
    d.arrow(f'M{UI + 87},{yc[0] - 9} L{PL - 102},{yc[0] - 9}')
    d.arrow(f'M{PL - 102},{yc[0] + 9} L{UI + 87},{yc[0] + 9}', kind='sec')
    d.text((UI + PL) / 2 - 7, yc[0] - 18, 'calls'); d.text((UI + PL) / 2 - 7, yc[0] + 27, 'streams')
    d.arrow(f'M{PL + 102},{yc[0]} L{MS - 92},{yc[0]}', kind='sec')
    d.text((PL + MS) / 2, yc[0] - 9, 'state')
    # event isolate
    EV = 350
    d.node(EV, yc[1], 230, 64, 'mpv_wait_event', 'blocks here, off the UI thread', sub2='clock values every 33 ms at most')
    # native
    d.node(PL, yc[2], 250, 64, 'libmpv', 'mpv 0.41 and ffmpeg: demuxer,', sub2='playback and analysis threads')
    d.node(MS, yc[2], 180, 64, 'Platform plugin', 'Kotlin, Swift, C++', role='neutral', mono=False)
    d.outline(MS, yc[2], 180, 64)
    # OS
    d.node(PL, yc[3], 250, 60, 'Audio driver', 'WASAPI, CoreAudio, AAudio,', sub2='PipeWire and others', role='neutral', mono=False)
    d.node(MS, yc[3], 180, 60, 'Media controls', 'lock screen, notification,', sub2='flyout, MPRIS applet', role='neutral', mono=False)
    d.outline(PL, yc[3], 250, 60); d.outline(MS, yc[3], 180, 60)

    # calls: Player straight to libmpv, past the event isolate
    cx = 510
    d.arrow(f'M{cx},{yc[0] + 30} L{cx},{yc[2] - 34}')
    d.text(cx + 10, yc[1] - 6, 'mpv_command_async', anchor='start', mono=True, color='label')
    d.text(cx + 10, yc[1] + 11, 'mpv_set_property_async', anchor='start', mono=True, color='label')
    d.text(cx + 10, yc[1] + 28, 'direct FFI, never waits', anchor='start')
    # events: libmpv to the loop, the loop to the Player
    d.arrow(f'M{420},{yc[2] - 34} L{420},{yc[1] + 34}', kind='sec')
    d.text(410, (yc[1] + 32 + yc[2] - 32) / 2 + 4, 'events', anchor='end')
    d.arrow(f'M{450},{yc[1] - 34} L{450},{yc[0] + 32}', kind='sec')
    d.text(441, (yc[0] + 30 + yc[1] - 32) / 2 + 4, 'SendPort: state, replies', anchor='end')
    # audio
    d.arrow(f'M{PL},{yc[2] + 34} L{PL},{yc[3] - 32}')
    d.text(PL + 10, (yc[2] + 32 + yc[3] - 30) / 2 + 4, 'PCM', anchor='start')
    # media session channels
    d.arrow(f'M{MS - 18},{yc[0] + 30} L{MS - 18},{yc[2] - 34}', kind='sec')
    d.arrow(f'M{MS + 18},{yc[2] - 34} L{MS + 18},{yc[0] + 30}', kind='sec')
    d.text(MS - 28, yc[1] - 5, 'MethodChannel', anchor='end', mono=True, color='label')
    d.text(MS - 28, yc[1] + 12, 'now playing', anchor='end')
    d.text(MS + 28, yc[1] - 5, 'EventChannel', anchor='start', mono=True, color='label')
    d.text(MS + 28, yc[1] + 12, 'OS commands', anchor='start')
    d.arrow(f'M{MS - 18},{yc[2] + 34} L{MS - 18},{yc[3] - 32}', kind='sec')
    d.arrow(f'M{MS + 18},{yc[3] - 32} L{MS + 18},{yc[2] + 34}', kind='sec')
    return d


# ── analysis_cache_feed: one download, two readers, the second open ────────
def _envelope(n, seed=0.0):
    """A deterministic music-like envelope: (peak, rms) per bin, 0..1. A soft
    intro, a verse, a louder chorus, a break: enough shape to read as a song."""
    sections = [(0.0, 0.25), (0.10, 0.55), (0.32, 0.9), (0.50, 0.45), (0.62, 0.95), (0.85, 0.35), (1.0, 0.2)]
    out = []
    for i in range(n):
        u = i / n
        for (a, va), (b, vb) in zip(sections, sections[1:]):
            if a <= u <= b:
                k = (u - a) / (b - a)
                k = k * k * (3 - 2 * k)
                lvl = va + (vb - va) * k
                break
        beat = 0.78 + 0.22 * abs(math.sin(i * 1.31 + seed)) * (0.6 + 0.4 * math.sin(i * 0.37))
        pk = max(0.06, min(1.0, lvl * beat))
        out.append((pk, pk * (0.5 + 0.1 * math.sin(i * 0.9))))
    return out


def _file_bar(d, x0, x1, y, h, fills):
    """A file as a bar: neutral track, navy cached spans."""
    d.add(f'<clipPath id="cb{y}"><rect x="{x0}" y="{y - h / 2}" width="{x1 - x0}" height="{h}" rx="6"/></clipPath>')
    d.rect(x0, y - h / 2, x1 - x0, h, d.c['neutral'], r=6)
    d.add(f'<g clip-path="url(#cb{y})">')
    for a, b in fills:
        d.rect(a, y - h / 2, b - a, h, NAVY)
    d.add('</g>')


def _head(d, x, y, half):
    """A reader's position on a file bar."""
    d.add(f'<line x1="{x}" y1="{y - half}" x2="{x}" y2="{y + half}" stroke="{d.c["main"]}" stroke-width="3" stroke-linecap="round"/>')


def cache_feed(t):
    d = D('analysis_cache_feed', 712, t, 'Waveform and loudness of a network file from one download')
    c = d.c
    X0, X1 = 230, 930
    # section 1
    d.heading(M, 30, 'One pass from the start to the end: the file is downloaded once')
    y = 122
    d.node(95, y, 130, 56, 'Server', 'HTTP file', role='neutral', mono=False)
    d.arrow(f'M160,{y} L{X0 - 4},{y}'); d.text(193, y - 9, 'one GET')
    EDGE, PB, AN = 680, 400, 672
    _file_bar(d, X0, X1, y, 30, [(X0, EDGE)])
    d.text(AN - 16, y + 4.5, 'mpv cache, downloaded so far', anchor='end', color=ON_NAVY)
    d.text((EDGE + X1) / 2, y + 4.5, 'not downloaded yet', color=INK2)
    # the two readers
    for x, name, sub, anchor, dx in ((PB, 'playback', 'reads in real time', 'middle', 0),
                                      (AN, 'analysis', 'decodes faster, up to the download', 'end', 4)):
        _head(d, x, y, 24)
        d.text(x + dx, y - 50, name, anchor=anchor, color='main', weight=600)
        d.text(x + dx, y - 33, sub, anchor=anchor)
    # waveform filling at the analysis head
    wy, amp = 212, 30
    step, bw = 6, 4
    n = int((X1 - X0) / step)
    peaks, rms = [], []
    for i, (pk, r) in enumerate(_envelope(n)):
        x = X0 + i * step
        if x + bw > AN:
            break
        peaks.append(f'M{x},{wy - amp * pk:.1f} h{bw} v{2 * amp * pk:.1f} h{-bw} z')
        rms.append(f'M{x},{wy - amp * r:.1f} h{bw} v{2 * amp * r:.1f} h{-bw} z')
    d.add(f'<path d="{" ".join(peaks)}" fill="{c["main"]}" fill-opacity="0.38"/>')
    d.add(f'<path d="{" ".join(rms)}" fill="{c["main"]}"/>')
    d.add(f'<line x1="{AN + 4}" y1="{wy}" x2="{X1}" y2="{wy}" stroke="{c["line"]}" stroke-width="1.5" stroke-dasharray="4 4"/>')
    d.add(f'<line x1="{AN}" y1="{y + 24}" x2="{AN}" y2="{wy + amp + 4}" stroke="{c["main"]}" stroke-width="1" stroke-dasharray="2 3"/>')
    d.text(X0 - 16, wy - 2, 'stream.waveform', anchor='end', mono=True, color='label', weight=600)
    d.text(X0 - 16, wy + 15, 'partial while decoding', anchor='end')
    d.bracket(X0, AN - 4, wy + amp + 14, 'bins filled from the cache', up=True)
    d.bracket(AN + 4, X1, wy + amp + 14, 'filled is 0: draw a flat baseline', up=True)
    d.text(d.w / 2, 310, 'stream.loudnessScan reads the same decode, so it adds no download either.')

    # section 2
    d.rule(338)
    d.heading(M, 372, 'When one pass is not possible: the analysis opens the source a second time')
    ya, yb = 432, 504
    ym = (ya + yb) / 2
    d.node(95, ym, 130, 56, 'Server', 'HTTP file', role='neutral', mono=False)
    d.arrow(f'M160,{ym - 10} L184,{ym - 10} L184,{ya} L{X0 - 4},{ya}')
    d.arrow(f'M160,{ym + 10} L184,{ym + 10} L184,{yb} L{X0 - 4},{yb}')
    d.text(207, ya - 9, 'GET'); d.text(207, yb - 9, 'GET')
    PS, PE, PH = 560, 760, 600
    d.rich(X0, ya - 20, [('playback', 'strong'), ('  caches from where it started', 'text')])
    _file_bar(d, X0, X1, ya, 22, [(PS, PE)])
    _head(d, PH, ya, 17)
    AE = 470
    d.rich(X0, yb - 20, [('analysis', 'strong'), ('  downloads the file again, from the start', 'text')])
    d.rich(X0, yb + 34, [('with the same ', 'text'), ('tls-verify', 'code'), (', ', 'text'), ('tls-ca-file', 'code'),
                         (', headers, user agent and cookies as playback', 'text')])
    _file_bar(d, X0, X1, yb, 22, [(X0, AE)])
    _head(d, AE - 6, yb, 17)
    d.text(d.w / 2, 580, 'Any one of these rules out the single pass:', color='label', weight=600)
    d.chips(d.w / 2, 610, ['playback starts further in', 'a seek past the cache', 'a track switch'])
    d.chips(d.w / 2, 646, ['a cut download', 'the cache off or on disk', 'a file larger than the cache'])
    d.caption('Either way the waveform and the loudness scan come out the same.')
    return d


# ── media_session_flow: the session, the channels, five OS surfaces ────────
def _phone(d, cx, y, w=86, h=158, island=True):
    c = d.c
    x = cx - w / 2
    d.rect(x, y, w, h, c['line'], r=15, op=0.10, stroke=c['line'], sw=2)
    if island:
        d.rect(cx - 13, y + 7, 26, 7, c['line'], r=3.5, op=0.85)
    else:
        d.add(f'<circle cx="{cx}" cy="{y + 10}" r="3.2" fill="{c["line"]}" fill-opacity="0.85"/>')
    return x


def _ios(d, cx, y):
    c = d.c
    x = _phone(d, cx, y)
    d.text(cx, y + 42, '12:30', size=18, weight=600, color='label')
    d.now_playing(x + 8, y + 72, 70, 58, prog=True, s=0.82)
    d.rect(cx - 17, y + 148, 34, 3.5, c['line'], r=1.75, op=0.85)


def _android(d, cx, y):
    c = d.c
    x = _phone(d, cx, y, island=False)
    # shade: quick tiles, then the media notification
    for i in range(4):
        d.add(f'<circle cx="{x + 18 + i * 17}" cy="{y + 30}" r="5.5" fill="{c["line"]}" fill-opacity="0.45"/>')
    d.now_playing(x + 6, y + 44, 74, 62, art='right', s=0.84)
    d.rect(x + 6, y + 112, 74, 14, c['line'], r=5, op=0.30)
    d.rect(x + 6, y + 130, 74, 14, c['line'], r=5, op=0.30)


def _macos(d, cx, y):
    c = d.c
    w, h = 156, 116
    x = cx - w / 2
    y0 = y + 21
    d.rect(x, y0, w, h, c['line'], r=8, op=0.10, stroke=c['line'], sw=2)
    d.rect(x + 1, y0 + 1, w - 2, 12, c['line'], r=7, op=0.30)
    for i in range(3):
        d.rect(x + w - 16 - i * 12, y0 + 4, 7, 5, c['line'], r=1.5, op=0.9)
    px, pw = x + w - 104, 96
    d.rect(px, y0 + 18, pw, 96, c['line'], r=9, op=0.22)
    d.rect(px + 6, y0 + 24, 41, 24, c['neutral'], r=5, op=0.75)
    d.rect(px + 49, y0 + 24, 41, 24, c['neutral'], r=5, op=0.75)
    d.now_playing(px + 6, y0 + 52, 84, 56, prog=False, s=0.9)


def _windows(d, cx, y):
    c = d.c
    w, h = 156, 116
    x = cx - w / 2
    y0 = y + 21
    d.rect(x, y0, w, h, c['line'], r=6, op=0.10, stroke=c['line'], sw=2)
    d.rect(x + 1, y0 + h - 15, w - 2, 14, c['line'], r=4, op=0.30)
    for i in range(5):
        d.rect(cx - 30 + i * 12, y0 + h - 12, 8, 8, c['line'], r=1.5, op=0.9)
    fw = 110
    d.now_playing(x + w - fw - 8, y0 + 34, fw, 60, s=0.95)


def _linux(d, cx, y):
    c = d.c
    w, h = 156, 116
    x = cx - w / 2
    y0 = y + 21
    d.rect(x, y0, w, h, c['line'], r=6, op=0.10, stroke=c['line'], sw=2)
    d.rect(x + 1, y0 + 1, w - 2, 12, c['line'], r=5, op=0.30)
    d.rect(cx - 14, y0 + 4, 28, 5, c['line'], r=2, op=0.9)
    d.add(f'<path d="M{cx - 6},{y0 + 22} L{cx},{y0 + 16} L{cx + 6},{y0 + 22} z" fill="{c["line"]}" fill-opacity="0.3"/>')
    d.rect(cx - 56, y0 + 22, 112, 88, c['line'], r=9, op=0.3)
    d.now_playing(cx - 50, y0 + 28, 100, 56, prog=True, s=0.9)
    d.rect(cx - 50, y0 + 89, 100, 14, c['neutral'], r=5, op=0.6)


def media(t):
    d = D('media_session_flow', 470, t, 'OS media session')
    c = d.c
    yt = 66
    AP, PL, MS = 150, 465, 800
    d.node(AP, yt, 260, 64, 'stream.mediaSessionCommands', 'each command, for your code', role='app', size=13)
    d.node(PL, yt, 210, 64, 'Player', 'setMediaSession(...)', sub2='applies play, pause, seek')
    d.node(MS, yt, 220, 64, 'Media session', 'metadata, state, actions', role='lib', mono=False)
    d.arrow(f'M{PL + 107},{yt - 10} L{MS - 112},{yt - 10}', kind='sec')
    d.arrow(f'M{MS - 112},{yt + 10} L{PL + 107},{yt + 10}', kind='sec')
    d.text((PL + MS) / 2 - 3, yt - 19, 'now playing'); d.text((PL + MS) / 2 - 3, yt + 30, 'commands')
    d.arrow(f'M{PL - 107},{yt} L{AP + 132},{yt}', kind='sec'); d.text((PL + AP) / 2 + 9, yt - 9, 'emits')
    # channels down to the bus
    yb = 176
    d.arrow(f'M{MS - 16},{yt + 34} L{MS - 16},{yb - 4}', kind='sec', head=False)
    d.arrow(f'M{MS + 16},{yb - 4} L{MS + 16},{yt + 34}', kind='sec')
    d.add(f'<path d="M{MS - 16},{yb - 22} l-5,-9 h10 z" fill="{c["line"]}"/>')
    d.text(MS - 26, yb - 33, 'MethodChannel', anchor='end', mono=True, color='label')
    d.text(MS - 26, yb - 17, 'updates', anchor='end')
    d.text(MS + 26, yb - 33, 'EventChannel', anchor='start', mono=True, color='label')
    d.text(MS + 26, yb - 17, 'OS commands', anchor='start')
    xs = [100 + i * 190 for i in range(5)]
    d.add(f'<path d="M{xs[0]},{yb} H{xs[-1]}" fill="none" stroke="{c["line"]}" stroke-width="1.7"/>')
    for x in (MS - 16, MS + 16):
        d.add(f'<circle cx="{x}" cy="{yb}" r="2.6" fill="{c["line"]}"/>')
    gy = 206
    for x, top in zip(xs, (0, 21, 0, 21, 21)):
        d.arrow(f'M{x},{yb} L{x},{gy + top - 6}', kind='sec', both=True)
    surfaces = [(_ios, 'iOS', 'lock screen'), (_macos, 'macOS', 'Control Center'),
                (_android, 'Android', 'media notification'), (_windows, 'Windows', 'SMTC media flyout'),
                (_linux, 'Linux', 'MPRIS, panel applet')]
    for x, (fn, os_, sub) in zip(xs, surfaces):
        fn(d, x, gy)
        d.heading(x, gy + 186, os_, sub=sub, anchor='middle')
    d.caption('Each surface draws only some of the actions in MediaSession.actions.')
    return d


# ── play_when_ready: the timeline, states as filled areas ──────────────────
def timeline(t):
    d = D('play_when_ready', 418, t, 'playWhenReady, playing and completed over time')
    c = d.c
    x0, x1 = 170, d.w - M

    def X(x):  # the moments were placed on a 170..970 axis
        return round(x0 + (x - 170) * (x1 - x0) / 800, 1)

    marks = [(210, 'play()'), (370, 'seek()'), (520, 'network stall'), (680, 'pause()'), (760, 'play()'),
             (900, 'end of content')]
    rows = [('playWhenReady', 110, [(170, 0), (210, 1), (680, 0), (760, 1), (900, 0)]),
            ('playing', 210, [(170, 0), (230, 1), (370, 0), (410, 1), (520, 0), (600, 1), (680, 0), (780, 1),
                              (900, 0)]),
            ('completed', 310, [(170, 0), (900, 1)])]
    H = 44
    # waits: playWhenReady true, playing false
    waits = [(210, 230, None), (370, 410, 'seeking'), (520, 600, 'buffering'), (760, 780, None)]
    for a, b, lab in waits:
        d.rect(X(a), 56, X(b) - X(a), 236 - 56, c['band'], op=0.16)
        if lab:
            d.text((X(a) + X(b)) / 2, 230, lab, color='label')
    for x, m in marks:
        d.guide(X(x), 40, 340)
        d.text(X(x), 28, m, mono=m.endswith(')'), color='label')
    for name, y, pts in rows:
        d.heading(20, y - 17, name, mono=True)
        path, area = f'M{x0},{y}', ''
        lvl, start = 0, None
        for x, v in pts:
            x = X(x)
            if v and not lvl:
                start = x
            if lvl and not v:
                area += f'M{start},{y} V{y - H} H{x} V{y} z '
            path += f' L{x},{y - H * lvl} L{x},{y - H * v}'
            lvl = v
        if lvl:
            area += f'M{start},{y} V{y - H} H{x1} V{y} z '
        path += f' L{x1},{y - H * lvl}'
        if area:
            d.add(f'<path d="{area}" fill="{c["main"]}" fill-opacity="0.16"/>')
        d.arrow(path, head=False, width=2.6)
        d.text(161, y + 4, 'false', anchor='end', size=11); d.text(161, y - H + 4, 'true', anchor='end', size=11)
    d.legend(d.w / 2, 372, 'playWhenReady is true, playing waits: the load, a seek, a network stall', kind='area',
             anchor='middle')
    d.caption('At the end of content playWhenReady drops and completed rises, until a new track or a seek back.')
    return d
