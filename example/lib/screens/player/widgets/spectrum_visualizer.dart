import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

/// Real-time FFT spectrum bar graph driven by [Player.stream.spectrum].
///
/// Bars grow symmetrically from the horizontal centre of the canvas
/// — half upwards, half downwards — so when this widget is stacked
/// behind a centred element (cover artwork) the bar tips emerge above
/// and below it. At amplitude 0 the painter draws nothing; the
/// container fades in only as the music has energy in that band.
///
/// Subscribes lazily — the libmpv-side PCM tap only runs while this
/// widget is mounted (per [PlayerStream.spectrum]'s lazy semantics).
/// On unmount the timer stops, the FFT memory is reclaimed.
///
/// No `AnimationController` needed: [Player.spectrumSettings]'s
/// asymmetric EMA (fast attack, slow release) makes painting the
/// values directly produce the "bouncy" visualizer feel.
class SpectrumVisualizer extends StatefulWidget {
  final Player player;

  const SpectrumVisualizer({super.key, required this.player});

  @override
  State<SpectrumVisualizer> createState() => _SpectrumVisualizerState();
}

class _SpectrumVisualizerState extends State<SpectrumVisualizer> {
  Float32List? _bands;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<FftFrame>(
      stream: widget.player.stream.spectrum,
      builder: (context, snap) {
        if (snap.hasData) _bands = snap.data!.bands;
        return CustomPaint(
          painter: _SpectrumPainter(
            bands: _bands,
            top: scheme.primary,
            bottom: scheme.tertiary,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  final Float32List? bands;
  final Color top;
  final Color bottom;

  _SpectrumPainter({
    required this.bands,
    required this.top,
    required this.bottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final b = bands;
    if (b == null || b.isEmpty) return;
    final n = b.length;
    const gap = 2.0;
    final barWidth = (size.width - gap * (n - 1)) / n;
    if (barWidth <= 0) return;

    // Bars grow from the horizontal centre outwards: each band's
    // amplitude controls the half-height extending up AND down,
    // mirroring the spectrum across the centreline.
    final centreY = size.height / 2;
    final maxHalfHeight = size.height / 2;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, bottom],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (var i = 0; i < n; i++) {
      final amp = b[i].clamp(0.0, 1.0);
      final halfH = amp * maxHalfHeight;
      if (halfH <= 0) continue;
      final x = i * (barWidth + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, centreY - halfH, barWidth, halfH * 2),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpectrumPainter old) =>
      old.bands != bands || old.top != top || old.bottom != bottom;
}
