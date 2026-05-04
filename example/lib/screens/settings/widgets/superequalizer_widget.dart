import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

/// Dedicated UI for the 18-band ISO graphic EQ (`superequalizer`).
///
/// `SuperequalizerSettings` exposes 18 band gains via a
/// `params: Map<String, double>` keyed by `'1b'..'18b'` (the ffmpeg
/// AVOption naming). Each band value is a linear gain factor in
/// `[0, 20]`, with `1.0` as neutral. The widget translates that to a
/// vertical-slider visualization with ISO-band centre-frequency
/// labels and an overlay curve.
class SuperequalizerWidget extends StatefulWidget {
  final Player player;
  const SuperequalizerWidget({super.key, required this.player});

  @override
  State<SuperequalizerWidget> createState() => _SuperequalizerWidgetState();
}

class _SuperequalizerWidgetState extends State<SuperequalizerWidget> {
  // ISO band centre frequencies for mpv's superequalizer 1b..18b.
  static const _bandKeys = [
    '1b', '2b', '3b', '4b', '5b', '6b', '7b', '8b', '9b',
    '10b', '11b', '12b', '13b', '14b', '15b', '16b', '17b', '18b',
  ];

  static const _bandLabels = [
    '65', '92', '131', '185', '262', '370', '523', '740', '1k',
    '1.5k', '2k', '3k', '4k', '6k', '8k', '12k', '17k', '20k',
  ];

  static const _min = 0.0;
  static const _max = 20.0;
  static const _neutral = 1.0;

  final Map<int, double> _drag = {};

  Player get player => widget.player;

  Stream<SuperequalizerSettings> get _stream => player.stream.audioEffects
      .map((e) => e.superequalizer)
      .distinct();

  double _bandValue(SuperequalizerSettings s, int i) =>
      s.params[_bandKeys[i]] ?? _neutral;

  void _setBand(SuperequalizerSettings s, int i, double v) {
    final next = Map<String, double>.from(s.params);
    if (v == _neutral) {
      next.remove(_bandKeys[i]);
    } else {
      next[_bandKeys[i]] = v;
    }
    player.updateAudioEffects(
      (e) => e.copyWith(superequalizer: s.copyWith(params: next)),
    );
  }

  void _resetAll(SuperequalizerSettings s) {
    player.updateAudioEffects(
      (e) => e.copyWith(
        superequalizer: s.copyWith(params: const <String, double>{}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SuperequalizerSettings>(
      stream: _stream,
      initialData: player.state.audioEffects.superequalizer,
      builder: (context, snap) {
        final s = snap.data!;
        final cs = Theme.of(context).colorScheme;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: cs.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header — same shape as ExpandableFilterCard for visual
                // continuity with the rest of the filter list.
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: s.enabled
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.equalizer_rounded,
                        size: 20,
                        color: s.enabled ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'superequalizer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '18-band ISO graphic EQ',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    if (s.params.isNotEmpty)
                      IconButton(
                        tooltip: 'Reset all bands',
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        onPressed: () => _resetAll(s),
                      ),
                    Switch(
                      value: s.enabled,
                      onChanged: (v) => player.updateAudioEffects(
                        (e) => e.copyWith(
                          superequalizer: s.copyWith(enabled: v),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                IgnorePointer(
                  ignoring: !s.enabled,
                  child: Opacity(
                    opacity: s.enabled ? 1.0 : 0.4,
                    child: _buildSliderRow(s, cs),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliderRow(SuperequalizerSettings s, ColorScheme cs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Cap band width to 48 on wide screens (so a desktop layout
        // doesn't stretch each band into a giant column) but let it
        // shrink as small as needed on narrow screens — at 18 bands a
        // 360px phone gives ~20px per band, which is still draggable
        // with a 6px thumb. No lower clamp → no horizontal overflow.
        final bandWidth = (constraints.maxWidth / 18).clamp(0.0, 48.0);
        const sliderHeight = 120.0;
        const topSpace = 22.0;
        const bottomSpace = 18.0;

        final values = List<double>.generate(
          18,
          (i) => _drag[i] ?? _bandValue(s, i),
        );

        return SizedBox(
          height: topSpace + sliderHeight + bottomSpace,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(18, (i) {
              final v = values[i];
              return SizedBox(
                width: bandWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: topSpace,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            v.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: sliderHeight,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                              elevation: 0,
                              pressedElevation: 0,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                            trackShape: const _TightTrackShape(),
                          ),
                          child: Slider(
                            min: _min,
                            max: _max,
                            value: v.clamp(_min, _max),
                            onChanged: (nv) =>
                                setState(() => _drag[i] = nv),
                            onChangeEnd: (nv) {
                              _setBand(s, i, nv);
                              setState(() => _drag.remove(i));
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: bottomSpace,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _bandLabels[i],
                            style: const TextStyle(fontSize: 9),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _TightTrackShape extends RoundedRectSliderTrackShape {
  const _TightTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight!;
    final trackLeft = offset.dx;
    final trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
