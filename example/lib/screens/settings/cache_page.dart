import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/property_cards.dart';

class CachePage extends StatelessWidget {
  final Player player;
  const CachePage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Cache Configuration'),
        StreamBuilder<String>(
          stream: player.stream.cacheMode,
          initialData: player.state.cacheMode,
          builder: (context, snap) {
            final val = snap.data ?? 'auto';
            return SegmentedPropertyCard<String>(
              title: 'Cache Mode',
              subtitle: 'cache=$val',
              icon: Icons.cached_rounded,
              value: val,
              segments: const [('auto', 'AUTO'), ('yes', 'YES'), ('no', 'NO')],
              onChanged: player.setCache,
            );
          },
        ),
        StreamBuilder<double>(
          stream: player.stream.cacheSecs,
          initialData: player.state.cacheSecs,
          builder: (context, snap) {
            final val = snap.data ?? 1.0;
            return SliderPropertyCard(
              title: 'Cache Time',
              subtitle: 'cache-secs=${val.toInt()}',
              icon: Icons.timer_outlined,
              value: val,
              min: 1.0,
              max: 3600.0,
              divisions: 360,
              defaultValue: 1.0,
              labelBuilder: (v) => '${v.toInt()}s',
              onChanged: player.setCacheSecs,
            );
          },
        ),
        StreamBuilder<bool>(
          stream: player.stream.cacheOnDisk,
          initialData: player.state.cacheOnDisk,
          builder: (context, snap) {
            final val = snap.data ?? false;
            return TogglePropertyCard(
              title: 'Cache on Disk',
              subtitle: 'cache-on-disk=${val ? 'yes' : 'no'}',
              icon: Icons.save_alt_rounded,
              value: val,
              onChanged: player.setCacheOnDisk,
            );
          },
        ),
        StreamBuilder<bool>(
          stream: player.stream.cachePause,
          initialData: player.state.cachePause,
          builder: (context, snap) {
            final val = snap.data ?? true;
            return TogglePropertyCard(
              title: 'Pause on Buffer',
              subtitle: 'cache-pause=${val ? 'yes' : 'no'}',
              icon: Icons.pause_circle_outline_rounded,
              value: val,
              onChanged: player.setCachePause,
            );
          },
        ),
        StreamBuilder<double>(
          stream: player.stream.cachePauseWait,
          initialData: player.state.cachePauseWait,
          builder: (context, snap) {
            final val = snap.data ?? 1.0;
            return SliderPropertyCard(
              title: 'Buffer Wait',
              subtitle: 'cache-pause-wait=${val.toStringAsFixed(1)}',
              icon: Icons.hourglass_bottom_rounded,
              value: val,
              min: 0.1,
              max: 60.0,
              divisions: 600,
              defaultValue: 1.0,
              labelBuilder: (v) => '${v.toStringAsFixed(1)}s',
              onChanged: player.setCachePauseWait,
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
