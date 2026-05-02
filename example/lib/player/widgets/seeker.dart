import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../../theme/app_metrics.dart';
import '../../utils/duration_format.dart';
import 'info_chip.dart';

/// Two source flavors the seek slider has to render: a regular file
/// (VOD) and a network live stream (HLS DVR or ICY radio). Both live
/// flavors support rewind into the demuxer back buffer even when the
/// source itself reports `seekable=false` — mpv accepts the seek
/// command as long as the target falls within `--demuxer-max-back-bytes`
/// (50 MiB default).
enum _StreamMode { vod, live }

/// Seek slider with VOD / live awareness, sticky buffer indicator,
/// LIVE / BUFFER / PREFETCH chips below the track, and tap-to-jump-
/// to-live for rewound live streams. See class doc on [_buildSlider]
/// for the live-edge anchoring rationale.
class Seeker extends StatefulWidget {
  final Player player;
  const Seeker({super.key, required this.player});

  @override
  State<Seeker> createState() => _SeekerState();
}

class _SeekerState extends State<Seeker> {
  double? _dragValue;
  bool get _isDragging => _dragValue != null;

  // Target position of the in-flight seek (microseconds). Set on
  // drag release, cleared by the position listener once `time-pos`
  // catches up — that's when the drag value is released. Releasing
  // on PLAYBACK_RESTART alone would briefly show the stale pre-seek
  // pos because mpv fires that event before the time-pos observer
  // emits the new value.
  int? _seekTargetMicros;
  StreamSubscription<void>? _seekCompletedSub;

  // Capability flags — change only on file boundaries, so we track them
  // as plain state rather than wrapping the whole build in extra
  // StreamBuilders.
  bool _seekable = false;
  bool _demuxerViaNetwork = false;
  StreamSubscription<bool>? _seekableSub;
  StreamSubscription<bool>? _networkSub;

  // Tracked live edge — the maximum playhead value observed since the
  // current file was loaded. Used as the slider's right anchor for
  // every live source so the thumb stays pinned at "now" instead of
  // chasing a growing duration. Reset on file boundaries via the
  // `path` subscription below.
  Duration _liveEdge = Duration.zero;
  String _trackedPath = '';
  StreamSubscription<Duration>? _liveEdgeSub;
  StreamSubscription<String>? _pathSub;

  // Maximum buffer-end timestamp ever observed for this file. Used as
  // the buffer indicator anchor instead of the live `pos + fwdBuffer`,
  // which would visibly "reload" after a seek even into a region mpv
  // has already demuxed (mpv's default `exact` seek mode flushes the
  // forward cache and refills from the new playhead). Reset on file
  // boundaries via [_pathSub].
  Duration _maxBufferEnd = Duration.zero;
  StreamSubscription<Duration>? _bufferSub;

  @override
  void initState() {
    super.initState();
    _seekable = widget.player.state.seekable;
    _demuxerViaNetwork = widget.player.state.demuxerViaNetwork;
    _trackedPath = widget.player.state.path;
    // Fallback: if position never emits near the target (e.g. seek
    // into a paused + imprecise format), release the drag anyway after
    // a short grace period so the UI doesn't get stuck. Normal path
    // releases via the position listener below.
    _seekCompletedSub = widget.player.stream.seekCompleted.listen((_) async {
      if (!mounted || _dragValue == null) return;
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted || _dragValue == null) return;
      setState(() {
        _dragValue = null;
        _seekTargetMicros = null;
      });
    });
    _seekableSub = widget.player.stream.seekable.listen((v) {
      if (mounted) setState(() => _seekable = v);
    });
    _networkSub = widget.player.stream.demuxerViaNetwork.listen((v) {
      if (mounted) setState(() => _demuxerViaNetwork = v);
    });
    // Track the maximum observed position. Combined with `duration` in
    // the build (for HLS DVR style streams), this gives the slider's
    // right anchor — i.e. the live edge. Also bumps the buffer-end
    // anchor when playback advances, since the playhead itself is the
    // floor of "what mpv has already demuxed". Finally, releases the
    // pending drag value once pos has caught up with the seek target
    // (avoids the one-frame thumb retreat described above).
    _liveEdgeSub = widget.player.stream.position.listen((p) {
      if (!mounted) return;
      var changed = false;
      if (p > _liveEdge) {
        _liveEdge = p;
        changed = true;
      }
      if (p > _maxBufferEnd) {
        _maxBufferEnd = p;
        changed = true;
      }
      if (_dragValue != null &&
          _seekTargetMicros != null &&
          (p.inMicroseconds - _seekTargetMicros!).abs() < 500000) {
        _dragValue = null;
        _seekTargetMicros = null;
        changed = true;
      }
      if (changed) setState(() {});
    });
    // Forward demuxer cache: bump the buffer-end anchor when the
    // demuxer extends ahead of the current playhead. This anchor is
    // sticky — it never goes backward, so a seek into the back buffer
    // doesn't "reload" the band visually.
    _bufferSub = widget.player.stream.bufferDuration.listen((b) {
      if (!mounted) return;
      final candidate = widget.player.state.position + b;
      if (candidate > _maxBufferEnd) {
        setState(() => _maxBufferEnd = candidate);
      }
    });
    // Reset tracked anchors when a new file is loaded.
    _pathSub = widget.player.stream.path.listen((p) {
      if (!mounted || p == _trackedPath) return;
      setState(() {
        _trackedPath = p;
        _liveEdge = Duration.zero;
        _maxBufferEnd = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _seekCompletedSub?.cancel();
    _seekableSub?.cancel();
    _networkSub?.cancel();
    _liveEdgeSub?.cancel();
    _bufferSub?.cancel();
    _pathSub?.cancel();
    super.dispose();
  }

  _StreamMode get _mode =>
      _demuxerViaNetwork ? _StreamMode.live : _StreamMode.vod;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.player.stream.position,
      initialData: widget.player.state.position,
      builder: (context, posSnap) {
        return StreamBuilder<Duration>(
          stream: widget.player.stream.duration,
          initialData: widget.player.state.duration,
          builder: (context, durSnap) {
            return StreamBuilder<Duration>(
              stream: widget.player.stream.bufferDuration,
              builder: (context, bufSnap) {
                final pos = posSnap.data ?? Duration.zero;
                final dur = durSnap.data ?? Duration.zero;
                return _buildSlider(
                  context,
                  pos: pos,
                  dur: dur,
                  isLive: _mode == _StreamMode.live,
                );
              },
            );
          },
        );
      },
    );
  }

  /// Unified slider for VOD and live streams. For VOD the range is the
  /// classic `[0, duration]`. For live streams (any source over the
  /// network), the range is anchored at a tracked live edge:
  /// `[liveEdge - rewindWindow, liveEdge]`. This pins the thumb at the
  /// right edge by default — matching the YouTube-Live / Twitch UX —
  /// and lets the user drag back into the demuxer buffer regardless of
  /// the source's `seekable` flag (mpv accepts seeks into the back
  /// buffer even when the stream itself is not seekable; if the target
  /// falls outside the buffer, mpv silently rejects it, which surfaces
  /// to the user as the slider snapping back to live).
  Widget _buildSlider(
    BuildContext context, {
    required Duration pos,
    required Duration dur,
    required bool isLive,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isValidDur = dur > Duration.zero;

    final Duration rangeStart;
    final Duration rangeEnd;
    if (isLive) {
      // Live edge = the maximum playhead value we've observed, which
      // tracks the actual playback frontier. We deliberately do NOT use
      // `duration` here: for HLS DVR it represents the manifest sliding
      // window (which includes the forward pre-fetch buffer), so it
      // sits ahead of `pos` by the buffer length. Using duration as the
      // anchor would put the thumb permanently at progress < 1.0 — the
      // exact "thumb chasing the end" symptom we are fixing.
      //
      // The position-stream subscription guarantees `_liveEdge >= pos`
      // most of the time, but during the inter-tick window between
      // mpv's emit and our setState we can see `pos > _liveEdge` for
      // a frame. The local max() below makes that transient consistent.
      final liveEdge = pos > _liveEdge ? pos : _liveEdge;
      rangeEnd = liveEdge;
      rangeStart = liveEdge - AppMetrics.liveRewindWindow > Duration.zero
          ? liveEdge - AppMetrics.liveRewindWindow
          : Duration.zero;
    } else {
      rangeStart = Duration.zero;
      rangeEnd = dur;
    }
    final rangeMicros = (rangeEnd.inMicroseconds - rangeStart.inMicroseconds)
        .clamp(1, 1 << 62);

    // Live streams always allow drag — mpv accepts seeks into the
    // demuxer back buffer regardless of source seekability. VOD gates
    // on the regular `seekable` flag.
    final canSeek = isLive || (_seekable && isValidDur);

    // Distance from the live edge in milliseconds. Treat sub-second lag
    // as "at live" so the badge doesn't flicker during normal playback
    // (mpv pre-buffers ~0–500 ms ahead of the playhead).
    final liveLagMs = isLive
        ? (rangeEnd.inMilliseconds - pos.inMilliseconds).abs()
        : 0;
    final atLiveEdge = isLive && liveLagMs < 1000;

    double progress;
    if (_isDragging) {
      progress = _dragValue!;
    } else {
      progress =
          ((pos.inMicroseconds - rangeStart.inMicroseconds) / rangeMicros)
              .clamp(0.0, 1.0);
    }

    // Buffer indicator: anchored at [_maxBufferEnd], the furthest-ahead
    // timestamp mpv has ever demuxed in this session. Using the live
    // `pos + fwdBuffer` would make the band collapse and refill on
    // every seek (mpv's default `exact` seek mode flushes the forward
    // cache and refills from the new playhead, so even rewinds into
    // already-demuxed regions look like a "reload"). The sticky anchor
    // avoids that visual jitter while still advancing forward whenever
    // real playback / pre-buffering genuinely extends past it.
    final bufferProgress =
        ((_maxBufferEnd.inMicroseconds - rangeStart.inMicroseconds) /
                rangeMicros)
            .clamp(progress, 1.0);

    final displayPos = _isDragging
        ? Duration(
            microseconds:
                rangeStart.inMicroseconds + (progress * rangeMicros).round(),
          )
        : pos;

    // Symmetric vertical padding around the slider so the audio-info
    // chips above and the pos / buffer / prefetch / dur row below sit
    // at the same visual distance from the track.
    return Column(
      children: [
        const SizedBox(height: 12),
        // TweenAnimationBuilder interpolates the secondary track between
        // the previous and the new buffer-end value, so the band glides
        // smoothly instead of jumping every time mpv emits a new
        // `demuxer-cache-duration` (which fires at coarse intervals
        // with chunky deltas).
        //
        // Linear curve + a duration *longer* than the typical mpv emit
        // cadence (~250–500 ms): each new target update arrives before
        // the previous animation finishes, so the visible motion is one
        // continuous slide instead of an "ease-out → pause → ease-out"
        // staircase. We re-clamp inside the builder so the interpolated
        // value always satisfies `secondary >= value`.
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: bufferProgress),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.linear,
          builder: (context, animatedBuffer, _) {
            return Slider(
              value: progress,
              secondaryTrackValue: animatedBuffer.clamp(progress, 1.0),
              activeColor: cs.primary,
              inactiveColor: cs.primary.withValues(alpha: 0.15),
              secondaryActiveColor: cs.primary.withValues(alpha: 0.45),
              onChangeStart: canSeek
                  ? (v) => setState(() => _dragValue = v)
                  : null,
              onChanged: canSeek ? (v) => setState(() => _dragValue = v) : null,
              onChangeEnd: canSeek
                  ? (v) {
                      final targetMicros =
                          rangeStart.inMicroseconds + (v * rangeMicros).round();
                      _seekTargetMicros = targetMicros;
                      widget.player.seek(Duration(microseconds: targetMicros));
                    }
                  : null,
            );
          },
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(displayPos),
                style: const TextStyle(fontSize: 12),
              ),
              // LIVE / BUFFER / PREFETCH chips shown side by side in
              // the center, mirroring the audio-info chips above the
              // slider. Each chip is conditionally rendered: live
              // hidden for VOD, buffer hidden at 0 s, prefetch hidden
              // when disabled. Expanded constrains the wrap width so
              // it can run multiple lines on narrow windows instead
              // of overflowing the pos / dur bookends.
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (isLive)
                      _LiveChip(
                        atLiveEdge: atLiveEdge,
                        liveLag: Duration(milliseconds: liveLagMs),
                        onJumpToLive: atLiveEdge
                            ? null
                            : () {
                                _seekTargetMicros = rangeEnd.inMicroseconds;
                                widget.player.seek(rangeEnd);
                              },
                      ),
                    StreamBuilder<Duration>(
                      stream: widget.player.stream.buffer,
                      builder: (context, snap) {
                        final bufferSecs =
                            (snap.data?.inMilliseconds ?? 0) / 1000.0;
                        if (bufferSecs <= 0) return const SizedBox.shrink();
                        return InfoChip(
                          label: 'BUFFER ${bufferSecs.toStringAsFixed(1)}s',
                          muted: true,
                        );
                      },
                    ),
                    // Show prefetch state only when the prefetch-playlist
                    // toggle is enabled — otherwise mpv never updates
                    // `prefetch-state` and a constant "IDLE" chip would
                    // be noise. `prefetch-state` is stream-only by
                    // design (no `state.prefetchState`), so we seed the
                    // inner builder with `idle` to avoid a blank chip
                    // until mpv first emits.
                    StreamBuilder<bool>(
                      stream: widget.player.stream.prefetchPlaylist,
                      initialData: widget.player.state.prefetchPlaylist,
                      builder: (context, enabledSnap) {
                        if (!(enabledSnap.data ?? false)) {
                          return const SizedBox.shrink();
                        }
                        return StreamBuilder<MpvPrefetchState>(
                          stream: widget.player.stream.prefetchState,
                          initialData: MpvPrefetchState.idle,
                          builder: (context, snap) {
                            final state = snap.data ?? MpvPrefetchState.idle;
                            return InfoChip(
                              label: 'PREFETCH ${state.name.toUpperCase()}',
                              muted: state == MpvPrefetchState.idle,
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              Text(
                formatDuration(isLive ? rangeEnd : dur),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// LIVE chip for the slider's center info row. Mirrors [InfoChip]'s
/// shape but switches background color to red when the playhead is at
/// the live edge, and to muted grey + appended `-30s` lag when the
/// user is rewound. Tapping the chip while rewound jumps back to live.
class _LiveChip extends StatelessWidget {
  final bool atLiveEdge;
  final Duration liveLag;
  final VoidCallback? onJumpToLive;

  const _LiveChip({
    required this.atLiveEdge,
    required this.liveLag,
    required this.onJumpToLive,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = atLiveEdge ? Colors.red : cs.surfaceContainerHighest;
    final fg = atLiveEdge ? Colors.white : cs.onSurfaceVariant;
    return InkWell(
      onTap: onJumpToLive,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fiber_manual_record_rounded, size: 8, color: fg),
            const SizedBox(width: 3),
            Text(
              atLiveEdge ? 'LIVE' : 'LIVE -${formatDuration(liveLag)}',
              style: TextStyle(
                fontSize: 10,
                color: fg,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
