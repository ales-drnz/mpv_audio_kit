import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../../shared/property_cards.dart';

class TlsPage extends StatelessWidget {
  final Player player;
  const TlsPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'TLS / SSL'),
        StreamBuilder<bool>(
          stream: player.stream.tlsVerify,
          initialData: player.state.tlsVerify,
          builder: (context, snap) {
            final val = snap.data ?? true;
            return TogglePropertyCard(
              title: 'Verify TLS/SSL',
              subtitle: 'tls-verify=${val ? 'yes' : 'no'}',
              icon: Icons.enhanced_encryption_rounded,
              value: val,
              onChanged: player.setTlsVerify,
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
