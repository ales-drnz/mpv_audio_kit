import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../../shared/property_cards.dart';

/// Configures mpv's A-B loop: when playback crosses point B, mpv seeks
/// back to A and replays the segment. Useful for language-learning,
/// audiobook re-listening, or stem isolation.
class AbLoopPage extends StatelessWidget {
  final Player player;
  const AbLoopPage({super.key, required this.player});

  /// Formats a [Duration] as the raw seconds value mpv accepts on the
  /// `ab-loop-a` / `ab-loop-b` properties (`OPT_TIME`, e.g. `12.345`).
  String _toMpvSeconds(Duration d) =>
      (d.inMicroseconds / 1e6).toStringAsFixed(3);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Loop Boundaries'),

        // A point. "Set here" stamps the current playback position; the
        // close button writes null which mpv interprets as `no` (disabled).
        StreamBuilder<Duration?>(
          stream: player.stream.abLoopA,
          initialData: player.state.abLoopA,
          builder: (context, snap) {
            final a = snap.data;
            return _LoopPointCard(
              title: 'Loop Point A',
              subtitle: 'ab-loop-a=${a == null ? 'no' : _toMpvSeconds(a)}',
              icon: Icons.start_rounded,
              isActive: a != null,
              onSetHere: () => player.setAbLoopA(player.state.position),
              onClear: a == null ? null : () => player.setAbLoopA(null),
            );
          },
        ),

        // B point.
        StreamBuilder<Duration?>(
          stream: player.stream.abLoopB,
          initialData: player.state.abLoopB,
          builder: (context, snap) {
            final b = snap.data;
            return _LoopPointCard(
              title: 'Loop Point B',
              subtitle: 'ab-loop-b=${b == null ? 'no' : _toMpvSeconds(b)}',
              icon: Icons.flag_rounded,
              isActive: b != null,
              onSetHere: () => player.setAbLoopB(player.state.position),
              onClear: b == null ? null : () => player.setAbLoopB(null),
            );
          },
        ),

        const SizedBox(height: 8),
        const PropertySectionHeader(title: 'Repetition Count'),

        // ab-loop-count: null = inf, 0 = no, n = explicit count.
        StreamBuilder<int?>(
          stream: player.stream.abLoopCount,
          initialData: player.state.abLoopCount,
          builder: (context, snap) {
            final count = snap.data;
            return SegmentedPropertyCard<_CountChoice>(
              title: 'Loop Count',
              subtitle: 'ab-loop-count=${count ?? 'inf'}',
              icon: Icons.repeat_rounded,
              value: switch (count) {
                null => _CountChoice.infinite,
                0 => _CountChoice.off,
                _ => _CountChoice.finite,
              },
              segments: const [
                (_CountChoice.off, 'Off'),
                (_CountChoice.finite, '5×'),
                (_CountChoice.infinite, 'Loop'),
              ],
              onChanged: (choice) {
                switch (choice) {
                  case _CountChoice.off:
                    player.setAbLoopCount(0);
                  case _CountChoice.finite:
                    player.setAbLoopCount(5);
                  case _CountChoice.infinite:
                    player.setAbLoopCount(null);
                }
              },
            );
          },
        ),

        // Read-only `remaining-ab-loops` — visible while a finite loop is
        // active; mpv decrements on each B-crossing.
        StreamBuilder<int?>(
          stream: player.stream.remainingAbLoops,
          initialData: player.state.remainingAbLoops,
          builder: (context, snap) {
            final remaining = snap.data;
            return PropertyBaseCard(
              title: 'Remaining Loops',
              subtitle: 'remaining-ab-loops=${remaining ?? 'inf'}',
              icon: Icons.timelapse_rounded,
              isActive: remaining != null,
              trailing: Text(
                remaining == null ? '∞' : '$remaining',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: cs.primary,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

class _LoopPointCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final VoidCallback onSetHere;
  final VoidCallback? onClear;

  const _LoopPointCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isActive,
    required this.onSetHere,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyBaseCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      isActive: isActive,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_rounded),
            onPressed: onSetHere,
            tooltip: 'Set to current position',
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: onClear,
            tooltip: 'Clear point',
          ),
        ],
      ),
    );
  }
}

enum _CountChoice { off, finite, infinite }
