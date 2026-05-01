import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

/// Spotify-style transport row: [shuffle] [prev] [play] [next] [repeat].
/// Secondary controls (shuffle / repeat) sit on the sides at a smaller
/// size and a muted color when off, so the primary [play] button keeps
/// visual priority. Wrapped in a [FittedBox] so the row scales down
/// uniformly on narrow windows instead of overflowing.
class TransportControls extends StatelessWidget {
  final Player player;
  final double availableHeight;

  const TransportControls({
    super.key,
    required this.player,
    required this.availableHeight,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StreamBuilder<bool>(
            stream: player.stream.shuffle,
            initialData: player.state.shuffle,
            builder: (context, snap) {
              final isShuffled = snap.data ?? false;
              return IconButton(
                iconSize: (availableHeight * 0.045).clamp(22.0, 28.0),
                icon: const Icon(Icons.shuffle_rounded),
                onPressed: () => player.setShuffle(!isShuffled),
                color: isShuffled
                    ? cs.primary
                    : cs.onSurfaceVariant.withValues(alpha: 0.7),
                tooltip: isShuffled ? 'Shuffle on' : 'Shuffle off',
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            iconSize: (availableHeight * 0.06).clamp(32.0, 40.0),
            icon: const Icon(Icons.skip_previous_rounded),
            onPressed: () => player.previous(),
            color: cs.primary,
          ),
          const SizedBox(width: 16),
          StreamBuilder<bool>(
            stream: player.stream.playing,
            initialData: player.state.playing,
            builder: (context, snap) {
              final isPlaying = snap.data ?? false;
              final iconSize =
                  (availableHeight * 0.08).clamp(48.0, 56.0).toDouble();
              return Container(
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  iconSize: iconSize,
                  color: cs.onPrimary,
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  onPressed: () =>
                      isPlaying ? player.pause() : player.play(),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          IconButton(
            iconSize: (availableHeight * 0.06).clamp(32.0, 40.0),
            icon: const Icon(Icons.skip_next_rounded),
            onPressed: () => player.next(),
            color: cs.primary,
          ),
          const SizedBox(width: 8),
          StreamBuilder<PlaylistMode>(
            stream: player.stream.playlistMode,
            initialData: player.state.playlistMode,
            builder: (context, snap) {
              final mode = snap.data ?? PlaylistMode.none;
              final (icon, active, tooltip) = switch (mode) {
                PlaylistMode.none =>
                  (Icons.repeat_rounded, false, 'Repeat off'),
                PlaylistMode.loop =>
                  (Icons.repeat_rounded, true, 'Repeat all'),
                PlaylistMode.single =>
                  (Icons.repeat_one_rounded, true, 'Repeat one'),
              };
              // Cycle order matches every mainstream music app:
              // none → all → single → none.
              final next = switch (mode) {
                PlaylistMode.none => PlaylistMode.loop,
                PlaylistMode.loop => PlaylistMode.single,
                PlaylistMode.single => PlaylistMode.none,
              };
              return IconButton(
                iconSize: (availableHeight * 0.045).clamp(22.0, 28.0),
                icon: Icon(icon),
                onPressed: () => player.setPlaylistMode(next),
                color: active
                    ? cs.primary
                    : cs.onSurfaceVariant.withValues(alpha: 0.7),
                tooltip: tooltip,
              );
            },
          ),
        ],
      ),
    );
  }
}
