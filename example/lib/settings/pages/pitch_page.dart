import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../shared/property_cards.dart';

class PitchPage extends StatelessWidget {
  final Player player;
  const PitchPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Pitch'),
        StreamBuilder<double>(
          stream: player.stream.pitch,
          initialData: player.state.pitch,
          builder: (_, snap) {
            final val = snap.data ?? 1.0;
            return SliderPropertyCard(
              title: 'Pitch',
              subtitle: 'pitch=${val.toStringAsFixed(2)}',
              icon: Icons.music_note_rounded,
              value: val,
              min: 0.5,
              max: 2.0,
              defaultValue: 1.0,
              labelBuilder: (v) => v.toStringAsFixed(2),
              onChanged: player.setPitch,
            );
          },
        ),

        const PropertySectionHeader(title: 'Correction'),
        StreamBuilder<bool>(
          stream: player.stream.pitchCorrection,
          initialData: player.state.pitchCorrection,
          builder: (context, snap) {
            final pc = snap.data ?? true;
            return TogglePropertyCard(
              title: 'Pitch Correction',
              subtitle: 'audio-pitch-correction=${pc ? 'yes' : 'no'}',
              icon: Icons.high_quality_rounded,
              value: pc,
              onChanged: player.setPitchCorrection,
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
