import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../shared/property_cards.dart';

class NetworkPage extends StatelessWidget {
  final Player player;
  const NetworkPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Network'),
        StreamBuilder<Duration>(
          stream: player.stream.networkTimeout,
          initialData: player.state.networkTimeout,
          builder: (context, snap) {
            final secs =
                (snap.data ?? const Duration(seconds: 30)).inSeconds.toDouble();
            return SliderPropertyCard(
              title: 'Network Timeout',
              subtitle: 'network-timeout=${secs.toInt()}',
              icon: Icons.cloud_off_rounded,
              value: secs,
              min: 1.0,
              max: 300.0,
              divisions: 300,
              defaultValue: 30.0,
              labelBuilder: (v) => '${v.toInt()}s',
              onChanged: (v) =>
                  player.setNetworkTimeout(Duration(seconds: v.toInt())),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
