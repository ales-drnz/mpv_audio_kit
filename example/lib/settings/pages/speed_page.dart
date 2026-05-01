import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../shared/property_cards.dart';

class SpeedPage extends StatelessWidget {
  final Player player;
  const SpeedPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Playback Speed'),
        StreamBuilder<double>(
          stream: player.stream.rate,
          initialData: player.state.rate,
          builder: (_, snap) {
            final val = snap.data ?? 1.0;
            return SliderPropertyCard(
              title: 'Speed',
              subtitle: 'speed=${val.toStringAsFixed(2)}',
              icon: Icons.speed_rounded,
              value: val,
              min: 0.5,
              max: 2.0,
              defaultValue: 1.0,
              labelBuilder: (v) => v.toStringAsFixed(2),
              onChanged: player.setRate,
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
