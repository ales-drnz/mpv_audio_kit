import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../shared/property_cards.dart';

/// Engine version surface — `mpv-version` and `ffmpeg-version` live
/// here because they are not tied to any other concept area; they
/// describe the engine itself.
class AboutPage extends StatelessWidget {
  final Player player;
  const AboutPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Engine'),
        StreamBuilder<String>(
          stream: player.stream.mpvVersion,
          initialData: player.state.mpvVersion,
          builder: (_, snap) {
            final v = snap.data ?? '';
            return ReadOnlyPropertyCard(
              title: 'mpv',
              subtitle: 'mpv-version=${v.isEmpty ? '' : v}',
              icon: Icons.memory_rounded,
              value: v.isEmpty ? '—' : v,
            );
          },
        ),
        StreamBuilder<String>(
          stream: player.stream.ffmpegVersion,
          initialData: player.state.ffmpegVersion,
          builder: (_, snap) {
            final v = snap.data ?? '';
            return ReadOnlyPropertyCard(
              title: 'FFmpeg',
              subtitle: 'ffmpeg-version=${v.isEmpty ? '' : v}',
              icon: Icons.code_rounded,
              value: v.isEmpty ? '—' : v,
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

