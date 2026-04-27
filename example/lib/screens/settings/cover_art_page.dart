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
          stream: player.stream.audioDisplay,
          initialData: player.state.audioDisplay,
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
          stream: player.stream.coverArtAuto,
          initialData: player.state.coverArtAuto,
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
