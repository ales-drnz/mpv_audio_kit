import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../shared/property_cards.dart';

class VolumePage extends StatelessWidget {
  final Player player;
  const VolumePage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Gain'),
        StreamBuilder<double>(
          stream: player.stream.volumeGain,
          initialData: player.state.volumeGain,
          builder: (context, snap) {
            final val = snap.data ?? 0.0;
            return SliderPropertyCard(
              title: 'Volume Gain',
              subtitle: 'volume-gain=${val.toStringAsFixed(1)}dB',
              icon: Icons.volume_up_rounded,
              value: val,
              min: -96.0,
              max: 12.0,
              defaultValue: 0.0,
              labelBuilder: (v) => '${v.toStringAsFixed(1)}dB',
              onChanged: player.setVolumeGain,
            );
          },
        ),

        const PropertySectionHeader(title: 'Limits'),
        StreamBuilder<double>(
          stream: player.stream.volumeMax,
          initialData: player.state.volumeMax,
          builder: (context, snap) {
            final val = snap.data ?? 130.0;
            final options = [100.0, 130.0, 150.0, 200.0, 300.0, 500.0, 1000.0];
            if (!options.contains(val)) options.add(val);
            options.sort();
            return DropdownPropertyCard<double>(
              title: 'Max Volume Limit',
              subtitle: 'volume-max=${val.toInt()}%',
              icon: Icons.do_not_disturb_on_rounded,
              value: val,
              items: options
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text('${v.toInt()}%'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => v != null ? player.setVolumeMax(v) : null,
            );
          },
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
