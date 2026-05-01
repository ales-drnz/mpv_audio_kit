import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../shared/property_cards.dart';

/// Read-only surface for playback runtime properties — timing,
/// stream-capability flags, and the synthetic playback-lifecycle enum.
class PlaybackInfoPage extends StatelessWidget {
  final Player player;
  const PlaybackInfoPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Lifecycle'),
        StreamBuilder<PlaybackLifecycle>(
          stream: player.stream.playbackLifecycle,
          builder: (_, snap) {
            final lifecycle = snap.data ?? PlaybackLifecycle.idle;
            return ReadOnlyPropertyCard(
              title: 'Playback Lifecycle',
              subtitle: 'core-idle / paused-for-cache / eof-reached',
              icon: Icons.timeline_rounded,
              value: lifecycle.name,
            );
          },
        ),

        const PropertySectionHeader(title: 'Timing'),
        StreamBuilder<Duration>(
          stream: player.stream.audioPts,
          initialData: player.state.audioPts,
          builder: (_, snap) {
            final secs = (snap.data ?? Duration.zero).inMicroseconds / 1e6;
            return ReadOnlyPropertyCard(
              title: 'Audio PTS',
              subtitle: 'audio-pts=${secs.toStringAsFixed(3)}',
              icon: Icons.timer_rounded,
              value: '${secs.toStringAsFixed(3)}s',
            );
          },
        ),
        StreamBuilder<Duration>(
          stream: player.stream.timeRemaining,
          initialData: player.state.timeRemaining,
          builder: (_, snap) {
            final secs = (snap.data ?? Duration.zero).inSeconds;
            return ReadOnlyPropertyCard(
              title: 'Time Remaining',
              subtitle: 'time-remaining=$secs',
              icon: Icons.hourglass_bottom_rounded,
              value: '${secs}s',
            );
          },
        ),
        StreamBuilder<Duration>(
          stream: player.stream.playtimeRemaining,
          builder: (_, snap) {
            final secs = (snap.data ?? Duration.zero).inSeconds;
            return ReadOnlyPropertyCard(
              title: 'Playtime Remaining',
              subtitle: 'playtime-remaining=$secs',
              icon: Icons.av_timer_rounded,
              value: '${secs}s',
            );
          },
        ),
        StreamBuilder<bool>(
          stream: player.stream.eofReached,
          initialData: player.state.eofReached,
          builder: (_, snap) => ReadOnlyPropertyCard(
            title: 'EOF Reached',
            subtitle: 'eof-reached=${(snap.data ?? false) ? 'yes' : 'no'}',
            icon: Icons.skip_next_rounded,
            value: (snap.data ?? false) ? 'yes' : 'no',
          ),
        ),

        const PropertySectionHeader(title: 'Seek Capability'),
        StreamBuilder<bool>(
          stream: player.stream.seekable,
          initialData: player.state.seekable,
          builder: (_, snap) => ReadOnlyPropertyCard(
            title: 'Seekable',
            subtitle: 'seekable=${(snap.data ?? false) ? 'yes' : 'no'}',
            icon: Icons.unfold_more_rounded,
            value: (snap.data ?? false) ? 'yes' : 'no',
          ),
        ),
        StreamBuilder<bool>(
          stream: player.stream.partiallySeekable,
          initialData: player.state.partiallySeekable,
          builder: (_, snap) => ReadOnlyPropertyCard(
            title: 'Partially Seekable',
            subtitle:
                'partially-seekable=${(snap.data ?? false) ? 'yes' : 'no'}',
            icon: Icons.swap_horiz_rounded,
            value: (snap.data ?? false) ? 'yes' : 'no',
          ),
        ),
        StreamBuilder<bool>(
          stream: player.stream.seeking,
          initialData: player.state.seeking,
          builder: (_, snap) => ReadOnlyPropertyCard(
            title: 'Seeking',
            subtitle: 'seeking=${(snap.data ?? false) ? 'yes' : 'no'}',
            icon: Icons.fast_forward_rounded,
            value: (snap.data ?? false) ? 'yes' : 'no',
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

