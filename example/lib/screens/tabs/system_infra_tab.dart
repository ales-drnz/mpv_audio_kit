import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/shared/property_cards.dart';

class SystemInfraTab extends StatefulWidget {
  final Player player;
  const SystemInfraTab({super.key, required this.player});

  @override
  State<SystemInfraTab> createState() => _SystemInfraTabState();
}

class _SystemInfraTabState extends State<SystemInfraTab> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Engine Performance'),
        StreamBuilder<double>(
          stream: widget.player.stream.audioBuffer,
          initialData: widget.player.state.audioBuffer,
          builder: (context, snap) {
            final val = snap.data ?? 0.2;
            return SliderPropertyCard(
              title: 'Audio Buffer',
              subtitle: 'audio-buffer=${val.toStringAsFixed(3)}',
              icon: Icons.storage_rounded,
              value: val,
              min: 0.0,
              max: 2.0,
              label: '${val.toStringAsFixed(1)}s',
              onChanged: (v) => widget.player.setRawProperty(
                'audio-buffer',
                v.toStringAsFixed(3),
              ),
            );
          },
        ),
        StreamBuilder<bool>(
          stream: widget.player.stream.audioExclusive,
          initialData: widget.player.state.audioExclusive,
          builder: (context, snap) {
            final val = snap.data ?? false;
            return TogglePropertyCard(
              title: 'Exclusive Mode',
              subtitle: 'audio-exclusive=${val ? 'yes' : 'no'}',
              icon: Icons.priority_high_rounded,
              value: val,
              onChanged: widget.player.setAudioExclusive,
            );
          },
        ),
        StreamBuilder<bool>(
          stream: widget.player.stream.streamSilence,
          initialData: widget.player.state.streamSilence,
          builder: (context, snap) {
            final val = snap.data ?? false;
            return TogglePropertyCard(
              title: 'Stream Silence',
              subtitle: 'stream-silence=${val ? 'yes' : 'no'}',
              icon: Icons.shutter_speed_rounded,
              value: val,
              onChanged: (v) => widget.player.setRawProperty(
                'stream-silence',
                v ? 'yes' : 'no',
              ),
            );
          },
        ),
        StreamBuilder<bool>(
          stream: widget.player.stream.aoNullUntimed,
          initialData: widget.player.state.aoNullUntimed,
          builder: (context, snap) {
            final val = snap.data ?? false;
            return TogglePropertyCard(
              title: 'Fallback to Null',
              subtitle: 'ao-null-untimed=${val ? 'yes' : 'no'}',
              icon: Icons.layers_clear_rounded,
              value: val,
              onChanged: (v) => widget.player.setRawProperty(
                'ao-null-untimed',
                v ? 'yes' : 'no',
              ),
            );
          },
        ),
      ],
    );
  }
}
