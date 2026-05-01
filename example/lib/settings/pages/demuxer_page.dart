import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../shared/property_cards.dart';

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
              onChanged: (v) =>
                  player.setDemuxerMaxBytes((v * 1024 * 1024).toInt()),
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
              onChanged: (v) =>
                  player.setDemuxerMaxBackBytes((v * 1024 * 1024).toInt()),
            );
          },
        ),

        const PropertySectionHeader(title: 'Demuxer Status'),
        StreamBuilder<String>(
          stream: player.stream.currentDemuxer,
          initialData: player.state.currentDemuxer,
          builder: (_, snap) => ReadOnlyPropertyCard(
            title: 'Current Demuxer',
            subtitle: 'current-demuxer=${snap.data ?? ''}',
            icon: Icons.dns_rounded,
            value: (snap.data?.isEmpty ?? true) ? '—' : snap.data!,
          ),
        ),
        StreamBuilder<Duration>(
          stream: player.stream.bufferDuration,
          builder: (_, snap) {
            final secs = (snap.data ?? Duration.zero).inMicroseconds / 1e6;
            return ReadOnlyPropertyCard(
              title: 'Cache Ahead',
              subtitle: 'demuxer-cache-duration=${secs.toStringAsFixed(2)}',
              icon: Icons.queue_rounded,
              value: '${secs.toStringAsFixed(2)}s',
            );
          },
        ),
        StreamBuilder<bool>(
          stream: player.stream.demuxerIdle,
          builder: (_, snap) => ReadOnlyPropertyCard(
            title: 'Demuxer Idle',
            subtitle: 'demuxer-cache-idle=${(snap.data ?? true) ? 'yes' : 'no'}',
            icon: Icons.bedtime_rounded,
            value: (snap.data ?? true) ? 'yes' : 'no',
          ),
        ),
        StreamBuilder<bool>(
          stream: player.stream.demuxerViaNetwork,
          initialData: player.state.demuxerViaNetwork,
          builder: (_, snap) => ReadOnlyPropertyCard(
            title: 'Via Network',
            subtitle:
                'demuxer-via-network=${(snap.data ?? false) ? 'yes' : 'no'}',
            icon: Icons.wifi_rounded,
            value: (snap.data ?? false) ? 'yes' : 'no',
          ),
        ),
        StreamBuilder<Duration>(
          stream: player.stream.demuxerStartTime,
          initialData: player.state.demuxerStartTime,
          builder: (_, snap) {
            final secs = (snap.data ?? Duration.zero).inMicroseconds / 1e6;
            return ReadOnlyPropertyCard(
              title: 'Demuxer Start Time',
              subtitle: 'demuxer-start-time=${secs.toStringAsFixed(3)}',
              icon: Icons.start_rounded,
              value: '${secs.toStringAsFixed(3)}s',
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

