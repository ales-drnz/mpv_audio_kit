"""Signal diagrams: effects_chain, spectrum_pipeline and demuxer_cache,
drawn as the signal itself rather than as boxes."""
import math

from base import D, M, NAVY, ON_NAVY, WAVE_LOW, WAVE_HIGH, hann, hit_env, text_w, wave, wave_path


def effects(t):
    d = D('effects_chain', 436, t, 'Effects chain with taps')
    c = d.c
    wy = 106                     # the signal wire
    px = [128, 362, 596, 830]    # probe points, one per readout
    # The chain: decoder, the list, volume, driver.
    d.node(60, wy, 80, 52, 'Decoder', role='neutral', mono=False)
    d.band(151, 30, 420, 124, 'setAudioEffects([...]), in list order')
    d.node(240, wy, 150, 48, 'EqualizerEffect', role='lib', size=13)
    d.node(475, wy, 160, 48, 'AcompressorEffect', role='lib', size=13)
    d.node(696, wy, 96, 52, 'Volume', role='neutral', mono=False)
    d.node(905, wy, 70, 52, 'Driver', role='neutral', mono=False)
    for a, b in ((100, 163), (315, 393), (555, 646), (744, 868)):
        d.arrow(f'M{a},{wy} L{b},{wy}')

    # What each probe reads: the same two hits, reshaped stage by stage,
    # all on one scale so sizes compare across the readouts.
    k = 0.92
    lo, hi = 1.6, 0.5
    raw = lambda t: k * wave(t)
    eq = lambda t: k * wave(t, low=lo, high=hi) / (WAVE_LOW * lo + WAVE_HIGH * hi)  # low end lifted, top cut
    thr, ratio = 0.4, 4.0

    def comp(t):         # above the threshold the level grows 4 times slower
        e = k * hit_env(t)
        g = 1.0 if e <= thr else (thr + (e - thr) / ratio) / e
        return eq(t) * g

    out = lambda t: comp(t) * 0.6                           # the volume scales evenly

    sy, sh, sw = 192, 120, 200
    amp = 64
    shapes = [(raw, None), (eq, raw), (comp, eq), (out, comp)]
    for x, (fn, prev) in zip(px, shapes):
        x0 = x - sw / 2
        d.probe(x, wy, sy)
        d.panel(x0, sy, sw, sh, centre_line=True)
        if prev:
            d.trace(prev, x0 + 12, sy + sh / 2, sw - 24, amp, ghost=True)
        d.trace(fn, x0 + 12, sy + sh / 2, sw - 24, amp)
    # the compressor's threshold
    x0 = px[2] - sw / 2 + 10
    for yy in (sy + sh / 2 - amp * thr, sy + sh / 2 + amp * thr):
        d.add(f'<line x1="{x0}" y1="{yy:.1f}" x2="{x0 + sw - 20}" y2="{yy:.1f}" stroke="{c["line"]}" '
              f'stroke-width="1" stroke-dasharray="3 3"/>')

    caps = [('AudioFilter.equalizer', 'TapSide.pre', 'the decoded signal'),
            ('AudioFilter.equalizer', 'TapSide.post', 'low end lifted, top cut'),
            ('AudioFilter.acompressor', 'TapSide.post', 'peaks held near the threshold'),
            ('stream.pcm, stream.fft', None, 'after the volume: what you hear')]
    cy = sy + sh + 26
    for x, (a, b, s) in zip(px, caps):
        d.text(x, cy, a, mono=True, color='label', weight=600)
        if b:
            d.text(x, cy + 18, b, mono=True, color='label')
        d.text(x, cy + (38 if b else 18), s)

    # legend for the grey trace, top right, clear of the chain
    d.legend(d.w - M, 54, 'the trace at the probe before', anchor='end')
    d.caption([('stream.tap(filter, instance: 1, side: ...)', 'code'),
               ('   reads the second stage of the same filter', 'text')])
    return d


def _spec_db(f):
    """A plausible music spectrum in normalised level [0, 1] at frequency f:
    falling with frequency, a kick near 60 Hz, a bass line near 150 Hz,
    voice near 1 kHz and a hi-hat near 8 kHz."""
    lf = math.log10(max(f, 20))
    base = 0.62 - 0.12 * (lf - 1.3)
    for fc, a, wdt in ((60, 0.35, 0.12), (150, 0.22, 0.1), (1000, 0.18, 0.18), (8000, 0.2, 0.12)):
        base += a * math.exp(-((lf - math.log10(fc)) / wdt) ** 2)
    return max(0.04, min(0.98, base))


def spectrum(t):
    d = D('spectrum_pipeline', 398, t, 'Spectrum pipeline')
    c = d.c
    pw, ph, py, gap = 160, 120, 96, 30
    xs = [M + i * (pw + gap) for i in range(5)]       # panel left edges
    heads = [('Output samples', ['fftSize']), ('Window', ['window']), ('FFT', ['minDb, maxDb']),
             ('Log bands', ['bandCount']), ('Smoothing', ['attackSmoothing', 'releaseSmoothing'])]
    for i, (x, (a, subs)) in enumerate(zip(xs, heads)):
        d.panel(x, py, pw, ph)
        d.text(x + pw / 2, py - 56, a, size=14, color='label', weight=600)
        for j, s in enumerate(subs):
            d.text(x + pw / 2, py - 36 + 17 * j, s, mono=True, color='label')
        if i:
            d.arrow(f'M{x - gap + 4},{py + ph / 2} L{x - 4},{py + ph / 2}')
    mid = py + ph / 2
    ix, iw = 12, pw - 24          # inner margins of a panel
    base = py + ph - 26           # baseline of the bar panels
    bh = ph - 40                  # tallest bar

    def caption(i, *lines):
        for j, s in enumerate(lines):
            d.text(xs[i] + pw / 2, py + ph + 24 + 18 * j, s)

    def axis(x0, lo, hi, mono=False):
        d.add(f'<line x1="{x0 + ix}" y1="{base + 0.5}" x2="{x0 + pw - ix}" y2="{base + 0.5}" stroke="{c["line"]}" stroke-width="1"/>')
        d.text(x0 + ix, base + 15, lo, anchor='start', size=11, mono=mono)
        d.text(x0 + pw - ix, base + 15, hi, anchor='end', size=11, mono=mono)

    # 1. the output over time, one block of fftSize samples picked out
    x0 = xs[0]
    b0, b1 = 0.05, 0.45                       # the block, as a share of the strip
    sig = lambda t: 0.9 * wave(t)
    d.add(f'<rect x="{x0 + ix + iw * b0:.1f}" y="{py + 10}" width="{iw * (b1 - b0):.1f}" height="{ph - 20}" rx="6" '
          f'fill="{c["main"]}" fill-opacity="0.16"/>')
    d.trace(sig, x0 + ix, mid, iw, 46, width=1.3)
    caption(0, 'mixed to mono,', 'one block at a time')

    # 2. that block times the Hann window: the edges fade to zero
    x0 = xs[1]
    seg = lambda t: sig(b0 + t * (b1 - b0))
    for sgn in (1, -1):
        d.add(f'<path d="{wave_path(lambda t: sgn * hann(t), x0 + ix, mid, iw, 46)}" fill="none" '
              f'stroke="{c["line"]}" stroke-width="1.3" stroke-dasharray="4 3"/>')
    d.trace(lambda t: hann(t) * seg(t), x0 + ix, mid, iw, 46, width=1.3)
    caption(1, 'hann by default:', 'the edges fade to zero')

    # 3. FFT magnitude in dB, linear in frequency: the low end is crowded
    x0 = xs[2]
    nb = 48
    bw = iw / nb
    for i in range(nb):
        f = (i + 0.5) / nb * 24000
        h = _spec_db(f) * bh
        d.add(f'<rect x="{x0 + ix + i * bw:.1f}" y="{base - h:.1f}" width="{bw * 0.6:.1f}" height="{h:.1f}" '
              f'fill="{c["main"]}"/>')
    axis(x0, '0 Hz', 'Nyquist')
    caption(2, 'fftSize / 2 bins, linear:', 'the low end is crowded')

    # 4. log-spaced bands, each the mean of its bins
    x0 = xs[3]
    nb = 16
    edges = [20 * (1000 ** (i / nb)) for i in range(nb + 1)]
    bw = iw / nb
    cur = []
    for i in range(nb):
        lo, hi = edges[i], edges[i + 1]
        v = sum(_spec_db(lo * (hi / lo) ** (k / 7)) for k in range(8)) / 8
        cur.append(v)
        h = v * bh
        d.add(f'<rect x="{x0 + ix + i * bw + 1:.1f}" y="{base - h:.1f}" width="{bw - 2:.1f}" height="{h:.1f}" rx="1.5" '
              f'fill="{c["main"]}"/>')
    axis(x0, 'bandLowHz', 'bandHighHz', mono=True)
    caption(3, 'equal steps in pitch,', 'each the mean of its bins')

    # 5. smoothing: each bar moves part of the way to this frame's value,
    # fast when it rises, slowly when it falls. The tick is this frame.
    x0 = xs[4]
    prev = [min(0.95, v * 1.55) if i < 5 else v * 0.5 for i, v in enumerate(cur)]   # last frame: a kick
    for i, (p, v) in enumerate(zip(prev, cur)):
        a = 0.5 if v > p else 0.1
        s = p + a * (v - p)
        h = s * bh
        bx = x0 + ix + i * bw + 1
        d.add(f'<rect x="{bx:.1f}" y="{base - h:.1f}" width="{bw - 2:.1f}" height="{h:.1f}" rx="1.5" '
              f'fill="{c["main"]}"/>')
        ty = base - v * bh
        col = '#FFFFFF' if v < s else c['line']
        d.add(f'<line x1="{bx - 1:.1f}" y1="{ty:.1f}" x2="{bx + bw - 1:.1f}" y2="{ty:.1f}" '
              f'stroke="{col}" stroke-width="2"/>')
    axis(x0, '', '')  # baseline only
    caption(4, 'rises fast, falls slowly;', 'tick: this frame')

    # What reaches your code, every emitInterval.
    oy = 350
    top = py + ph + 52
    cx = [x + pw / 2 for x in xs]
    d.node(cx[0], oy, pw, 56, 'stream.pcm', 'PcmFrame: samples', role='app')
    d.node(cx[3], oy, 210, 56, 'stream.fft', 'FftFrame: bands, bins', role='app')
    d.arrow(f'M{cx[0]},{top} L{cx[0]},{oy - 31}', kind='sec')
    d.arrow(f'M{cx[2]},{top} L{cx[2]},{oy} L{cx[3] - 108},{oy}', kind='sec')
    d.text(cx[2] + 10, oy - 9, 'bins', anchor='start')
    d.arrow(f'M{cx[4]},{top} L{cx[4]},{oy} L{cx[3] + 108},{oy}')
    d.text(cx[4] - 10, oy - 9, 'bands', anchor='end')
    d.text((cx[0] + cx[2]) / 2 + 10, oy - 4, 'both emit once per')
    d.text((cx[0] + cx[2]) / 2 + 10, oy + 15, 'emitInterval, 33 ms', mono=True, color='label')
    return d


def _file_env(t):
    """Loudness along a song, for the file strip: a quiet intro, verses, two
    louder choruses with a break between them, a fading outro."""
    s = (0.42 + 0.18 * math.sin(math.pi * t)
         + 0.32 * math.exp(-((t - 0.36) / 0.08) ** 2) + 0.36 * math.exp(-((t - 0.74) / 0.09) ** 2)
         - 0.3 * math.exp(-((t - 0.56) / 0.03) ** 2))
    s *= min(1, t / 0.06) * min(1, (1 - t) / 0.1) * 0.85 + 0.15
    return max(0.1, min(1.0, s))


def _jitter(i):
    return 0.82 + 0.18 * math.sin(i * 2.71) * math.sin(i * 0.53 + 1.3)


def cache(t):
    d = D('demuxer_cache', 460, t, 'The demuxer cache around the playhead')
    c = d.c
    x0, x1 = 30, 930
    sy, sh = 76, 64           # the file strip
    mid = sy + sh / 2
    back0, play, ahead1, secs_x = 190, 420, 700, 800
    n = 180
    bw = (x1 - x0) / n
    # the whole file, and the navy span the demuxer holds in memory
    d.panel(x0, sy, x1 - x0, sh)
    d.add(f'<rect x="{back0}" y="{sy}" width="{ahead1 - back0}" height="{sh}" fill="{NAVY}"/>')
    for i in range(n):
        bx = x0 + i * bw
        cx = bx + bw / 2
        h = _file_env(i / n) * _jitter(i) * (sh / 2 - 7)
        if back0 <= cx <= ahead1:
            col, op = (ON_NAVY, 0.6) if cx < play else ('#FFFFFF', 0.95)
        else:
            col, op = c['line'], 0.5
        d.add(f'<rect x="{bx + 0.8:.1f}" y="{mid - h:.1f}" width="{bw - 1.6:.1f}" height="{2 * h:.1f}" rx="1.2" '
              f'fill="{col}" fill-opacity="{op}"/>')

    # the playhead, and where reading has got to
    d.add(f'<line x1="{play}" y1="{sy - 14}" x2="{play}" y2="{sy + sh + 14}" stroke="{c["main"]}" stroke-width="3"/>')
    d.add(f'<path d="M{play - 7},{sy - 24} L{play + 7},{sy - 24} L{play},{sy - 14} z" fill="{c["main"]}"/>')
    d.text(play, sy - 32, 'playhead', color='main', weight=600)
    d.text(x0 + 4, sy - 12, 'played, freed', anchor='start')
    d.text(ahead1, sy - 12, 'read so far')
    d.text(x1 - 4, sy - 12, 'not read yet', anchor='end')

    # the limits, under the strip
    by = sy + sh + 20
    d.bracket(back0, play - 5, by, up=True)
    d.bracket(play + 5, ahead1, by, up=True)
    d.add(f'<line x1="{secs_x}" y1="{sy}" x2="{secs_x}" y2="{by}" stroke="{c["line"]}" stroke-width="1.5" '
          f'stroke-dasharray="4 3"/>')
    ly = by + 24
    for x, a, lines in (((back0 + play) / 2, 'DemuxerSettings.maxBackBytes',
                         ('limit in bytes behind the playhead:', 'a seek back here needs no new request')),
                        ((play + ahead1) / 2, 'DemuxerSettings.maxBytes',
                         ('limit in bytes ahead,', 'reached first here: reading stops')),
                        (secs_x + 44, 'CacheSettings.secs',
                         ('limit in seconds ahead', 'when the cache is on'))):
        d.text(x, ly, a, mono=True, color='label', weight=600)
        for j, s in enumerate(lines):
            d.text(x, ly + 19 + 18 * j, s)

    # CacheSettings.pause: what happens when the part ahead runs dry
    gy0, gy1 = 326, 420        # chart top and baseline
    gx0, gx1 = 130, 930
    hy = gy0 - 46
    d.rule(hy - 24)
    d.heading(x0, hy, 'CacheSettings.pause', mono=True)
    d.text(x0 + text_w('CacheSettings.pause', 13, mono=True) + 14, hy, 'on: playback waits when the part ahead runs dry',
           anchor='start')
    t_dry, t_go = 0.34, 0.6
    wait_lvl = 0.4

    def level(u):
        if u < t_dry:
            return 0.9 * (1 - u / t_dry) ** 1.2
        if u < t_go:
            return wait_lvl * ((u - t_dry) / (t_go - t_dry)) ** 1.5
        return wait_lvl + 0.5 * (1 - math.exp(-(u - t_go) * 6))

    gh = gy1 - gy0
    xa, xb = gx0 + (gx1 - gx0) * t_dry, gx0 + (gx1 - gx0) * t_go
    d.add(f'<rect x="{xa:.1f}" y="{gy0 - 8}" width="{xb - xa:.1f}" height="{gh + 8}" rx="6" fill="{c["main"]}" '
          f'fill-opacity="0.13"/>')
    d.text((xa + xb) / 2, gy0 + 12, 'paused', color='main', weight=600)
    d.text((xa + xb) / 2, gy0 + 30, 'stream.pausedForCache', mono=True, color='main')
    d.text((gx0 + xa) / 2 + 30, gy0 + 6, 'playing, the network falls behind')
    d.text((xb + gx1) / 2, gy0 + 6, 'playing again')
    wy = gy1 - gh * wait_lvl
    d.add(f'<line x1="{gx0}" y1="{wy:.1f}" x2="{gx1}" y2="{wy:.1f}" stroke="{c["line"]}" stroke-width="1" '
          f'stroke-dasharray="4 3"/>')
    d.text(gx0 - 10, wy + 4, 'pauseWait', anchor='end', mono=True, color='label')
    d.text(gx0 - 10, gy0 + 14, 'cached ahead', anchor='end')
    d.add(f'<line x1="{gx0}" y1="{gy1}" x2="{gx1}" y2="{gy1}" stroke="{c["line"]}" stroke-width="1"/>')
    d.text(gx0 - 10, gy1 + 4, '0 s', anchor='end', size=11)
    d.text(gx1, gy1 + 20, 'time', anchor='end', size=11)
    pts = ' L'.join(f'{gx0 + (gx1 - gx0) * k / 300:.1f},{gy1 - gh * level(k / 300):.1f}' for k in range(301))
    d.add(f'<path d="M{pts}" fill="none" stroke="{c["main"]}" stroke-width="2.4" stroke-linejoin="round"/>')
    return d
