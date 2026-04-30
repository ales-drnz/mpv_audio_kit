import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/property_cards.dart';

class CoverArtPage extends StatelessWidget {
  final Player player;
  const CoverArtPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Display'),
        StreamBuilder<AudioDisplayMode>(
          stream: player.stream.audioDisplayMode,
          initialData: player.state.audioDisplayMode,
          builder: (context, snap) {
            final val = snap.data ?? AudioDisplayMode.embeddedFirst;
            return DropdownPropertyCard<AudioDisplayMode>(
              title: 'Audio Display',
              subtitle: 'audio-display=${val.mpvValue}',
              icon: Icons.image_rounded,
              value: val,
              items: const [
                DropdownMenuItem(
                    value: AudioDisplayMode.no, child: Text('Disabled')),
                DropdownMenuItem(
                  value: AudioDisplayMode.embeddedFirst,
                  child: Text('Embedded first'),
                ),
                DropdownMenuItem(
                  value: AudioDisplayMode.externalFirst,
                  child: Text('External first'),
                ),
              ],
              onChanged: (v) => v != null ? player.setAudioDisplayMode(v) : null,
            );
          },
        ),
        StreamBuilder<CoverArtAutoMode>(
          stream: player.stream.coverArtAutoMode,
          initialData: player.state.coverArtAutoMode,
          builder: (context, snap) {
            final val = snap.data ?? CoverArtAutoMode.no;
            return DropdownPropertyCard<CoverArtAutoMode>(
              title: 'Auto-load Cover Art',
              subtitle: 'cover-art-auto=${val.mpvValue}',
              icon: Icons.upload_rounded,
              value: val,
              items: const [
                DropdownMenuItem(
                    value: CoverArtAutoMode.no, child: Text('Disabled')),
                DropdownMenuItem(
                    value: CoverArtAutoMode.exact, child: Text('Exact match')),
                DropdownMenuItem(
                    value: CoverArtAutoMode.fuzzy, child: Text('Fuzzy match')),
                DropdownMenuItem(
                    value: CoverArtAutoMode.all, child: Text('All images')),
              ],
              onChanged: (v) => v != null ? player.setCoverArtAutoMode(v) : null,
            );
          },
        ),

        const PropertySectionHeader(title: 'Frame Retention'),
        StreamBuilder<Duration?>(
          stream: player.stream.imageDisplayDuration,
          initialData: player.state.imageDisplayDuration,
          builder: (context, snap) {
            final val = snap.data;
            final display = val == null
                ? 'inf'
                : '${(val.inMilliseconds / 1000).toStringAsFixed(2)}s';
            return TextPropertyCard(
              title: 'Image Display Duration',
              subtitle: 'image-display-duration=$display',
              icon: Icons.timer_outlined,
              value: display,
              onSubmitted: (raw) {
                final trimmed = raw.trim().toLowerCase();
                if (trimmed.isEmpty || trimmed == 'inf') {
                  player.setImageDisplayDuration(null);
                  return;
                }
                final secs = double.tryParse(trimmed.replaceAll('s', ''));
                if (secs == null) return;
                player.setImageDisplayDuration(
                  Duration(microseconds: (secs * 1e6).round()),
                );
              },
            );
          },
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
