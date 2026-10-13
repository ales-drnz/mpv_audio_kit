"""Flows and sequences: player_lifecycle, mpv_prefetch_state,
cover_art_flow, error_streams, on_load_hook_sequence and source_resolver."""
from base import D, M, NAVY, ON_NAVY, INK2


def lifecycle(t):
    d = D('player_lifecycle', 192, t, 'Player lifecycle')
    steps = [('ensureInitialized()', 'once, at app start', 'lib'), ('Player()', 'one per session', 'lib'),
             ('open()', 'or openAll()', 'app'), ('stream, setters', 'listen and control', 'app'),
             ('dispose()', 'releases libmpv', 'lib')]
    ws = [180, 155, 155, 155, 155]
    gap = 30
    lefts = [M + sum(ws[:i]) + gap * i for i in range(5)]
    xs = [l + w / 2 for l, w in zip(lefts, ws)]
    y = 92
    d.bracket(lefts[0], lefts[0] + ws[0], 40, 'once per app', tick=8, size=13, weight=600)
    d.bracket(lefts[1], d.w - M, 40, 'for each player', tick=8, size=13, weight=600)
    for (a, b, role), x, w in zip(steps, xs, ws):
        d.node(x, y, w, 60, a, b, role=role)
    for i in range(4):
        d.arrow(f'M{lefts[i] + ws[i] + 3},{y} L{lefts[i + 1] - 4},{y}')
    # open again: a new queue on the same player, as often as needed
    d.arrow(f'M{xs[3]},{y + 31} L{xs[3]},{y + 58} L{xs[2]},{y + 58} L{xs[2]},{y + 35}', kind='sec')
    d.text((xs[2] + xs[3]) / 2, y + 78, 'open again, any time')
    return d


def prefetch(t):
    d = D('mpv_prefetch_state', 490, t, 'Prefetch states over time, while track A hands over to track B')
    X0, X1 = 150, d.w - M
    t1, t2, t3, t4 = 330, 480, 600, 800   # prefetch starts, B ready, A ends, prefetch of C
    # the state strip
    d.heading(M, 50, 'prefetchState', sub='when it works', mono=True)
    sy = 56
    d.seg(X0, t1 - 3, sy, 34, 'idle', role='ghost')
    d.seg(t1, t2 - 3, sy, 34, 'loading', stripes=True)
    d.seg(t2, t3 - 3, sy, 34, 'ready')
    d.seg(t3, t4 - 3, sy, 34, 'used')
    d.seg(t4, X1, sy, 34, 'loading', stripes=True)
    # the tracks
    for n, y in (('track A', 130), ('track B', 170), ('track C', 210)):
        d.text(M, y + 4, n, anchor='start', color='label', weight=600)
    for x in (t1, t2, t3, t4):
        d.guide(x, 82, 232)
    d.track(X0, t3, 130)
    d.track(t1, t3, 170, kind='bg')
    d.track(t3, X1, 170)
    d.track(t4, X1, 210, kind='bg')
    # events under the lanes
    ev = [(t1, 'prefetch of B', 'starts'), (t2, 'B open', 'and cached'), (t3, 'A ends,', 'B starts, prefetched'),
          (t4, 'prefetch of C', 'starts')]
    for x, a, b in ev:
        d.text(x, 252, a, color='label', weight=600)
        d.text(x, 268, b)
    # legend for the lanes
    d.legend(X0, 300, 'plays', kind='play')
    d.legend(X0 + 100, 300, 'opened in the background', kind='bg')

    # the failure case
    fy = 372
    d.rule(326)
    d.heading(M, fy - 6, 'prefetchState', sub='when B fails', mono=True)
    d.seg(X0, t1 - 3, fy, 34, 'idle', role='ghost')
    d.seg(t1, 420 - 3, fy, 34, 'loading', stripes=True)
    d.seg(420, t4 - 3, fy, 34, 'failed', role='fail')
    d.seg(t4, X1, fy, 34, 'loading', stripes=True)
    d.text(t3, fy + 44, 'B opens from scratch,', color='label', weight=600)
    d.text(t3, fy + 60, 'when A ends')
    d.text(t4, fy + 44, 'failed stays until', color='label', weight=600)
    d.text(t4, fy + 60, 'the next loading')
    d.text(420, fy + 44, 'open failed', color='fail', weight=600)
    d.text(420, fy + 60, 'network, codec or hook')
    d.caption('A cancel or a dropped prefetch turns loading, ready and used back into idle. failed stays.')
    return d


def cover(t):
    d = D('cover_art_flow', 376, t, 'Where cover art comes from: the picture inside the file, or an image in the folder')
    c = d.c
    # the album folder: an outline, so the files inside stand out
    fx, fy, fw, fh = M, 40, 222, 316
    d.add(f'<path d="M{fx},{fy + 10} Q{fx},{fy} {fx + 10},{fy} L{fx + 104},{fy} L{fx + 120},{fy + 16} '
          f'L{fx + fw - 10},{fy + 16} Q{fx + fw},{fy + 16} {fx + fw},{fy + 26} L{fx + fw},{fy + fh - 10} '
          f'Q{fx + fw},{fy + fh} {fx + fw - 10},{fy + fh} L{fx + 10},{fy + fh} Q{fx},{fy + fh} {fx},{fy + fh - 10} Z" '
          f'fill="{c["band"]}" fill-opacity="0.07" stroke="{c["line"]}" stroke-width="1.4"/>')
    d.text(fx + 14, fy + 13, 'album folder', anchor='start', size=13, color='label', weight=600)
    # the audio file, with its picture inside
    ax, ay, aw, ah = 46, 80, 172, 150
    d.doc(ax, ay, aw, ah)
    for i, hh in enumerate((10, 22, 14, 30, 18, 26, 12, 20, 8)):
        d.add(f'<rect x="{ax + 18 + i * 9}" y="{ay + 28 - hh / 2}" width="5" height="{hh}" rx="2.5" fill="#8E99AB"/>')
    d.picture(ax + 18, ay + 72, 64, 48)
    d.add(f'<rect x="{ax + 14}" y="{ay + 68}" width="72" height="56" rx="6" fill="none" stroke="{c["main"]}" '
          f'stroke-width="1.6" stroke-dasharray="3 3"/>')
    d.text(ax + 18, ay + 62, 'embedded picture', anchor='start', color=INK2)
    d.text(ax + 18, ay + 142, 'song.flac', anchor='start', size=13, mono=True, color=c['ink'], weight=600)
    # the image next to it
    bx, by, bw, bh = 46, 254, 172, 84
    d.doc(bx, by, bw, bh)
    d.picture(bx + 16, by + 18, 64, 48, fill='#8E99AB')
    d.text(bx + 90, by + 47, 'cover.jpg', anchor='start', size=13, mono=True, color=c['ink'], weight=600)

    w1, w2 = 190, 230
    n2 = d.w - M - w2 / 2        # node centers
    n1 = n2 - w2 / 2 - 50 - w1 / 2
    lx = (fx + fw + n1 - w1 / 2) / 2   # labels between the folder and the nodes
    # embedded path: always on
    y1 = ay + 96
    d.arrow(f'M{ax + 87},{y1} L{n1 - w1 / 2 - 4},{y1}')
    d.text(lx, y1 - 10, 'every file load')
    d.node(n1, y1, w1, 64, 'stream.coverArt', 'CoverArt bytes, or null', role='lib')
    d.arrow(f'M{n1 + w1 / 2 + 4},{y1} L{n2 - w2 / 2 - 4},{y1}')
    d.node(n2, y1, w2, 64, 'Image(image: art.image)', 'your widget', role='app', size=13)
    # external path: only with setCoverArtAuto
    y2 = by + bh / 2
    d.arrow(f'M{bx + bw + 4},{y2} L{n1 - w1 / 2 - 4},{y2}', kind='sec')
    d.text(lx, y2 - 10, 'setCoverArtAuto(Cover.exact)', mono=True, color='label')
    d.text(lx, y2 + 22, 'loaded as an extra track')
    d.node(n1, y2, w1, 72, 'state.tracks', 'external and albumArt,', sub2='with externalFilename', role='lib')
    d.arrow(f'M{n1 + w1 / 2 + 4},{y2} L{n2 - w2 / 2 - 4},{y2}', kind='sec')
    d.node(n2, y2, w2, 64, 'File(path)', 'you read the image', role='app')
    # the wall between the two: a no, not an error, so grey
    top, bot = y1 + 32, y2 - 36
    my = (top + bot) / 2
    d.arrow(f'M{n1},{bot - 2} L{n1},{top + 4}', kind='sec', dash=True)
    d.cross(n1, my, s=7)
    d.text(n1 + 18, my + 4.5, 'never reaches stream.coverArt', anchor='start', color='label', weight=600)
    return d


def errors(t):
    d = D('error_streams', 438, t, 'Which events feed stream.error, endFile, audioOutputState and the two logs')
    rows = [90, 190, 290, 390]
    sx, dx, ex = 118, 465, 840        # column centers: source, every event, errors only
    src = [('end of a file', 'mpv end-file event'), ('log message', 'mpv, any level'),
           ('audio output', 'opens, plays, fails'), ('the library', 'hook timeouts, resolver errors')]
    dst = [('stream.endFile', 'every file end'), ('stream.log', 'every message'),
           ('stream.audioOutputState', 'closed, initializing, active, failed'),
           ('stream.internalLog', 'prefix mpv_audio_kit')]
    for x, h in ((sx, 'source'), (dx, 'every event'), (ex, 'errors only')):
        d.heading(x, 34, h, anchor='middle')
    for i, y in enumerate(rows):
        d.node(sx, y, 196, 56, *src[i], role='neutral', mono=False)
        d.node(dx, y, 270, 56, *dst[i], role='lib')
        d.arrow(f'M{sx + 102},{y} L{dx - 139},{y}')
    # the error collector
    cl, cw = ex - 100, 200
    lg = (rows[1] + rows[2]) / 2 + 50         # where the one LogError sits
    top, bot = rows[0] - 28, lg + 46
    d.add(f'<rect x="{cl}" y="{top}" width="{cw}" height="{bot - top}" rx="14" fill="{NAVY}"/>')
    d.text(ex, top + 30, 'stream.error', size=14, mono=True, color='#FFFFFF', weight=600)
    d.text(ex, top + 49, 'PlayerError', mono=True, color=ON_NAVY)

    def kind(y, name):   # the type that arrives, inside the collector
        d.add(f'<rect x="{cl + 16}" y="{y - 15}" width="{cw - 32}" height="30" rx="6" fill="#FFFFFF" fill-opacity="0.12"/>')
        d.text(ex, y + 4.5, name, size=13, mono=True, color='#FFFFFF', weight=600)

    # end of a file: straight across
    fork = sx + 144
    ly = rows[0] + 50
    d.dot(fork, rows[0], kind='fail', r=4)
    d.arrow(f'M{fork},{rows[0]} L{fork},{ly} L{cl - 4},{ly}', kind='fail')
    d.text((dx + 135 + cl) / 2, ly - 9, 'when error < 0', color='fail')
    kind(ly, 'EndFileError')
    # log message and audio output: two arrows into one LogError
    turn = cl - 30
    for y, cond, k in ((rows[1], 'at error or fatal', -9), (rows[2], 'when failed', 9)):
        ly = y + 50
        d.dot(fork, y, kind='fail', r=4)
        d.arrow(f'M{fork},{y} L{fork},{ly} L{turn},{ly} L{turn},{lg + k} L{cl - 4},{lg + k}', kind='fail')
        d.text((dx + 135 + turn) / 2, ly - 9, cond, color='fail')
    kind(lg, 'LogError')
    return d


def hook(t):
    d = D('on_load_hook_sequence', 572, t, 'on_load hook sequence between your code, the player and mpv')
    c = d.c
    X = {'app': 200, 'pl': 520, 'mpv': 840}
    ys = {1: 126, 2: 176, 3: 262, 4: 312, 5: 362, 6: 412, 7: 462, 8: 504}
    wy0, wy1 = ys[3] - 14, ys[7] + 4
    gaps = {'pl': [(ys[5] - 30, ys[5] - 6)]}   # where a label crosses a lifeline
    for k, n, role in (('app', 'Your code', 'app'), ('pl', 'Player', 'lib'), ('mpv', 'mpv', 'lib')):
        x = X[k]
        d.node(x, 40, 180, 48, n, role=role, mono=False)
        y = 66
        for g0, g1 in gaps.get(k, []) + [(530, 530)]:
            d.lifeline(x, y, g0)
            y = g1
    # mpv waits from the hook to the continue
    d.add(f'<rect x="{X["mpv"] - 7}" y="{wy0}" width="14" height="{wy1 - wy0}" rx="4" fill="{c["main"]}" fill-opacity="0.22" '
          f'stroke="{c["main"]}" stroke-width="1.4"/>')
    d.text(X['mpv'] + 18, (wy0 + wy1) / 2 - 4, 'paused', anchor='start', color='main', weight=600)
    d.text(X['mpv'] + 18, (wy0 + wy1) / 2 + 12, 'on this file', anchor='start')
    d.heading(M, 92, 'once')
    d.rule(206)
    d.heading(M, 228, 'for each file')

    def msg(n, a, b, label, kind, mono=True):
        y = ys[n]
        xa, xb = X[a], X[b]
        sgn = 1 if xb > xa else -1
        inside = wy0 <= y <= wy1
        x_from = xa + (7 if a == 'mpv' and inside else 0) * sgn
        x_to = xb - (8 + (7 if b == 'mpv' and inside else 0)) * sgn
        d.arrow(f'M{x_from},{y} L{x_to},{y}', kind=kind)
        d.badge(min(xa, xb) + 22, y - 18, n, kind)
        d.text(min(xa, xb) + 40, y - 13.5, label, anchor='start', mono=mono, color='label')

    msg(1, 'app', 'pl', 'registerHook(Hook.load)', 'main')
    msg(2, 'pl', 'mpv', 'mpv_hook_add(on_load)', 'sec')
    msg(3, 'mpv', 'pl', 'on_load: the stream is about to open', 'sec', mono=False)
    msg(4, 'pl', 'app', 'stream.hook: MpvHookEvent', 'sec')
    msg(5, 'app', 'mpv', "setRawProperty('stream-open-filename', url)", 'main')
    msg(6, 'app', 'pl', 'continueHook(event.id)', 'main')
    msg(7, 'pl', 'mpv', 'mpv_hook_continue', 'sec')
    # 8: mpv goes on and opens the stream
    y8 = ys[8]
    d.arrow(f'M{X["mpv"]},{y8 - 12} L{X["mpv"] + 44},{y8 - 12} L{X["mpv"] + 44},{y8 + 12} L{X["mpv"] + 8},{y8 + 12}', kind='sec')
    d.badge(X['mpv'] - 140, y8, 8, 'sec')
    d.text(X['mpv'] - 122, y8 + 4.5, 'opens the stream', anchor='start', color='label')
    d.caption('With a timeout in registerHook, the library calls continueHook itself when your code is late.')
    return d


def resolver(t):
    d = D('source_resolver', 426, t, 'Source resolver: an expired URL is refreshed once, on on_load_fail')
    r1, r2, r3 = 96, 236, 344
    cx = [95, 300, 575, 850]
    hw = [75, 90, 118, 85]   # half widths
    d.heading(M, 30, 'every open, prefetch included')

    def row(y, hook, hook_sub, retry, url, tag, tag_col, end_sub, end_role):
        d.node(cx[0], y, 2 * hw[0], 56, hook, hook_sub, role='lib')
        d.node(cx[1], y, 2 * hw[1], 56, 'your resolver', f'isRetry: {retry}', role='app', mono=False)
        d.chip(cx[2], y, url, w=2 * hw[2], mono=True, style='neutral')
        d.text(cx[2], y - 24, tag, color=tag_col, weight=600)
        d.node(cx[3], y, 2 * hw[3], 56, 'mpv opens it', end_sub, role=end_role, mono=False)
        for i in range(3):
            d.arrow(f'M{cx[i] + hw[i] + 3},{y} L{cx[i + 1] - hw[i + 1] - 4},{y}')
        d.text((cx[1] + hw[1] + cx[2] - hw[2]) / 2, y - 10, 'returns')

    row(r1, 'on_load', 'before the open', 'false', 'cdn.example/42?token=A', 'short-lived token', 'label',
        'HTTP 403, expired', 'fail')
    # the failure sends mpv to on_load_fail
    d.arrow(f'M{cx[3]},{r1 + 30} L{cx[3]},{r1 + 70} L{cx[0]},{r1 + 70} L{cx[0]},{r2 - 32}', kind='fail')
    d.text((cx[0] + cx[3]) / 2, r1 + 61, 'the open failed', color='fail')
    row(r2, 'on_load_fail', 'after the failure', 'true', 'cdn.example/42?token=B', 'fresh token, one retry', 'main',
        'plays', 'lib')
    # dead ends
    d.node(cx[3], r3, 2 * hw[3], 56, 'stream.error', 'EndFileError', role='fail')
    d.arrow(f'M{cx[1]},{r2 + 30} L{cx[1]},{r3} L{cx[3] - hw[3] - 4},{r3}', kind='fail', dash=True)
    d.text(cx[1] + 14, r3 - 9, 'null or the same URL: no retry', anchor='start', color='fail')
    d.arrow(f'M{cx[3]},{r2 + 30} L{cx[3]},{r3 - 32}', kind='fail', dash=True)
    d.text(cx[3] + 12, (r2 + r3) / 2 + 4, 'fails again', anchor='start', color='fail')
    d.caption('At most one retry per load. With your own Hook.load, the resolver runs first.')
    return d
