import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../../shared/property_cards.dart';

class CoverArtPage extends StatelessWidget {
  final Player player;
  const CoverArtPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Cover Art'),
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

        const SizedBox(height: 16),
      ],
    );
  }
}
