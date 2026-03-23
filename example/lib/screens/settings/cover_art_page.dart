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
        StreamBuilder<String>(
          stream: player.stream.audioDisplay,
          initialData: player.state.audioDisplay,
          builder: (context, snap) {
            final val = snap.data ?? 'embedded-first';
            return DropdownPropertyCard<String>(
              title: 'Audio Display',
              subtitle: 'audio-display=$val',
              icon: Icons.image_rounded,
              value: val,
              items: const [
                DropdownMenuItem(value: 'no', child: Text('Disabled')),
                DropdownMenuItem(
                  value: 'embedded-first',
                  child: Text('Embedded first'),
                ),
                DropdownMenuItem(
                  value: 'external-first',
                  child: Text('External first'),
                ),
              ],
              onChanged: (v) => v != null ? player.setAudioDisplay(v) : null,
            );
          },
        ),
        StreamBuilder<String>(
          stream: player.stream.coverArtAuto,
          initialData: player.state.coverArtAuto,
          builder: (context, snap) {
            final val = snap.data ?? 'no';
            return DropdownPropertyCard<String>(
              title: 'Auto-load Cover Art',
              subtitle: 'cover-art-auto=$val',
              icon: Icons.upload_rounded,
              value: val,
              items: const [
                DropdownMenuItem(value: 'no', child: Text('Disabled')),
                DropdownMenuItem(value: 'exact', child: Text('Exact match')),
                DropdownMenuItem(value: 'fuzzy', child: Text('Fuzzy match')),
                DropdownMenuItem(value: 'all', child: Text('All images')),
              ],
              onChanged: (v) => v != null ? player.setCoverArtAuto(v) : null,
            );
          },
        ),

        const PropertySectionHeader(title: 'Frame Retention'),
        StreamBuilder<String>(
          stream: player.stream.imageDisplayDuration,
          initialData: player.state.imageDisplayDuration,
          builder: (context, snap) {
            final val = snap.data ?? 'inf';
            return TextPropertyCard(
              title: 'Image Display Duration',
              subtitle: 'image-display-duration=$val',
              icon: Icons.timer_outlined,
              value: val,
              onSubmitted: player.setImageDisplayDuration,
            );
          },
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
