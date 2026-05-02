import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../shared/property_cards.dart';

class CoverArtPage extends StatelessWidget {
  final Player player;
  const CoverArtPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Display'),
        StreamBuilder<Display>(
          stream: player.stream.audioDisplay,
          initialData: player.state.audioDisplay,
          builder: (context, snap) {
            final val = snap.data ?? Display.embeddedFirst;
            return DropdownPropertyCard<Display>(
              title: 'Audio Display',
              subtitle: 'audio-display=${val.mpvValue}',
              icon: Icons.image_rounded,
              value: val,
              items: const [
                DropdownMenuItem(
                  value: Display.no,
                  child: Text('Disabled'),
                ),
                DropdownMenuItem(
                  value: Display.embeddedFirst,
                  child: Text('Embedded first'),
                ),
                DropdownMenuItem(
                  value: Display.externalFirst,
                  child: Text('External first'),
                ),
              ],
              onChanged: (v) => v != null ? player.setAudioDisplay(v) : null,
            );
          },
        ),
        StreamBuilder<Cover>(
          stream: player.stream.coverArtAuto,
          initialData: player.state.coverArtAuto,
          builder: (context, snap) {
            final val = snap.data ?? Cover.no;
            return DropdownPropertyCard<Cover>(
              title: 'Auto-load Cover Art',
              subtitle: 'cover-art-auto=${val.mpvValue}',
              icon: Icons.upload_rounded,
              value: val,
              items: const [
                DropdownMenuItem(
                  value: Cover.no,
                  child: Text('Disabled'),
                ),
                DropdownMenuItem(
                  value: Cover.exact,
                  child: Text('Exact match'),
                ),
                DropdownMenuItem(
                  value: Cover.fuzzy,
                  child: Text('Fuzzy match'),
                ),
                DropdownMenuItem(
                  value: Cover.all,
                  child: Text('All images'),
                ),
              ],
              onChanged: (v) => v != null ? player.setCoverArtAuto(v) : null,
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
                  unawaited(player.setImageDisplayDuration(null));
                  return;
                }
                final secs = double.tryParse(trimmed.replaceAll('s', ''));
                if (secs == null) return;
                unawaited(
                  player.setImageDisplayDuration(
                    Duration(microseconds: (secs * 1e6).round()),
                  ),
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
