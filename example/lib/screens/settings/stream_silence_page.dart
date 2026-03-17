import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/property_cards.dart';

class StreamSilencePage extends StatelessWidget {
  final Player player;
  const StreamSilencePage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Stream'),
        StreamBuilder<bool>(
          stream: player.stream.streamSilence,
          initialData: player.state.streamSilence,
          builder: (context, snap) {
            final val = snap.data ?? false;
            return TogglePropertyCard(
              title: 'Stream Silence',
              subtitle: 'stream-silence=${val ? 'yes' : 'no'}',
              icon: Icons.shutter_speed_rounded,
              value: val,
              onChanged: (v) =>
                  player.setRawProperty('stream-silence', v ? 'yes' : 'no'),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
