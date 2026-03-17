import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/property_cards.dart';

class DemuxerPage extends StatelessWidget {
  final Player player;
  const DemuxerPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Demuxer Performance'),
        StreamBuilder<int>(
          stream: player.stream.demuxerMaxBytes,
          initialData: player.state.demuxerMaxBytes,
          builder: (context, snap) {
            final mib = (snap.data ?? (150 * 1024 * 1024)) / (1024 * 1024);
            return SliderPropertyCard(
              title: 'Max Cache Size',
              subtitle: 'demuxer-max-bytes=${mib.toInt()}MiB',
              icon: Icons.memory_rounded,
              value: mib,
              min: 1.0,
              max: 2048.0,
              divisions: 2048,
              defaultValue: 150.0,
              labelBuilder: (v) => '${v.toInt()}MiB',
              onChanged: (v) => player.setDemuxerMaxBytes((v * 1024 * 1024).toInt()),
            );
          },
        ),
        StreamBuilder<int>(
          stream: player.stream.demuxerReadaheadSecs,
          initialData: player.state.demuxerReadaheadSecs,
          builder: (context, snap) {
            final val = snap.data ?? 1;
            return SliderPropertyCard(
              title: 'Readahead Time',
              subtitle: 'demuxer-readahead-secs=$val',
              icon: Icons.fast_forward_rounded,
              value: val.toDouble(),
              min: 0.0,
              max: 3600.0,
              divisions: 3600,
              defaultValue: 1.0,
              labelBuilder: (v) => '${v.toInt()}s',
              onChanged: (v) => player.setDemuxerReadaheadSecs(v.toInt()),
            );
          },
        ),
        StreamBuilder<int>(
          stream: player.stream.demuxerMaxBackBytes,
          initialData: player.state.demuxerMaxBackBytes,
          builder: (context, snap) {
            final mib = (snap.data ?? (50 * 1024 * 1024)) / (1024 * 1024);
            return SliderPropertyCard(
              title: 'Seekback Pool',
              subtitle: 'demuxer-max-back-bytes=${mib.toInt()}MiB',
              icon: Icons.history_rounded,
              value: mib,
              min: 0.0,
              max: 1024.0,
              divisions: 1024,
              defaultValue: 50.0,
              labelBuilder: (v) => '${v.toInt()}MiB',
              onChanged: (v) => player.setDemuxerMaxBackBytes((v * 1024 * 1024).toInt()),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
