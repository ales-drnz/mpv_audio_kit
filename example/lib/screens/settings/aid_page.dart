import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/property_cards.dart';

class AidPage extends StatelessWidget {
  final Player player;
  const AidPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Audio Track'),
        StreamBuilder<String>(
          stream: player.stream.audioTrack,
          initialData: player.state.audioTrack,
          builder: (context, snap) {
            final val = snap.data ?? 'auto';
            final options = ['auto', '1', '2', '3', '4'];
            if (!options.contains(val)) options.add(val);
            return DropdownPropertyCard<String>(
              title: 'Audio Track',
              subtitle: 'aid=$val',
              icon: Icons.audiotrack_rounded,
              value: val,
              items: options
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => v != null ? player.setAudioTrack(v) : null,
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
