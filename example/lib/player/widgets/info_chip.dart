import 'package:flutter/material.dart';

/// Compact, monospace info chip used to surface metadata next to the
/// player's seek slider — codec, sample rate, bitrate, buffer level,
/// prefetch state, …
///
/// `muted = true` switches the background to neutral grey + lower-
/// contrast text, so secondary metadata (e.g. cover-art dimensions)
/// doesn't compete visually with the primary audio chips.
class InfoChip extends StatelessWidget {
  final String label;
  final bool muted;

  const InfoChip({super.key, required this.label, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = muted ? cs.surfaceContainerHighest : cs.secondaryContainer;
    final fg = muted ? cs.onSurfaceVariant : cs.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: fg,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
