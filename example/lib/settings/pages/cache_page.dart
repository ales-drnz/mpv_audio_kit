import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../shared/property_cards.dart';

class CachePage extends StatelessWidget {
  final Player player;
  const CachePage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Cache Configuration'),
        StreamBuilder<CacheConfig>(
          stream: player.stream.cache,
          initialData: player.state.cache,
          builder: (context, snap) {
            final cfg = snap.data ?? const CacheConfig();
            final secs = cfg.secs.inMicroseconds / 1e6;
            final waitSecs = cfg.pauseWait.inMicroseconds / 1e6;
            return Column(
              children: [
                SegmentedPropertyCard<CacheMode>(
                  title: 'Cache Mode',
                  subtitle: 'cache=${cfg.mode.mpvValue}',
                  icon: Icons.cached_rounded,
                  value: cfg.mode,
                  segments: const [
                    (CacheMode.auto, 'AUTO'),
                    (CacheMode.yes, 'YES'),
                    (CacheMode.no, 'NO'),
                  ],
                  onChanged: (m) => player.setCache(cfg.copyWith(mode: m)),
                ),
                SliderPropertyCard(
                  title: 'Cache Time',
                  subtitle: 'cache-secs=${secs.toInt()}',
                  icon: Icons.timer_outlined,
                  value: secs,
                  min: 1.0,
                  max: 3600.0,
                  divisions: 360,
                  defaultValue: 1.0,
                  labelBuilder: (v) => '${v.toInt()}s',
                  onChanged: (v) => player.setCache(cfg.copyWith(
                      secs: Duration(microseconds: (v * 1e6).round()))),
                ),
                TogglePropertyCard(
                  title: 'Cache on Disk',
                  subtitle: 'cache-on-disk=${cfg.onDisk ? 'yes' : 'no'}',
                  icon: Icons.save_alt_rounded,
                  value: cfg.onDisk,
                  onChanged: (v) =>
                      player.setCache(cfg.copyWith(onDisk: v)),
                ),
                TogglePropertyCard(
                  title: 'Pause on Buffer',
                  subtitle: 'cache-pause=${cfg.pause ? 'yes' : 'no'}',
                  icon: Icons.pause_circle_outline_rounded,
                  value: cfg.pause,
                  onChanged: (v) =>
                      player.setCache(cfg.copyWith(pause: v)),
                ),
                SliderPropertyCard(
                  title: 'Buffer Wait',
                  subtitle:
                      'cache-pause-wait=${waitSecs.toStringAsFixed(1)}',
                  icon: Icons.hourglass_bottom_rounded,
                  value: waitSecs,
                  min: 0.1,
                  max: 60.0,
                  divisions: 600,
                  defaultValue: 1.0,
                  labelBuilder: (v) => '${v.toStringAsFixed(1)}s',
                  onChanged: (v) => player.setCache(cfg.copyWith(
                      pauseWait: Duration(microseconds: (v * 1e6).round()))),
                ),
              ],
            );
          },
        ),

        const PropertySectionHeader(title: 'Cache Status'),
        StreamBuilder<double>(
          stream: player.stream.cacheSpeed,
          initialData: player.state.cacheSpeed,
          builder: (_, snap) {
            final bps = snap.data ?? 0.0;
            return ReadOnlyPropertyCard(
              title: 'Cache Speed',
              subtitle: 'cache-speed=${bps.toInt()}',
              icon: Icons.speed_rounded,
              value: '${(bps / 1024).toStringAsFixed(1)} KiB/s',
            );
          },
        ),
        StreamBuilder<int>(
          stream: player.stream.cacheBufferingState,
          initialData: player.state.cacheBufferingState,
          builder: (_, snap) => ReadOnlyPropertyCard(
            title: 'Cache Buffering',
            subtitle: 'cache-buffering-state=${snap.data ?? 0}',
            icon: Icons.battery_charging_full_rounded,
            value: '${snap.data ?? 0}%',
          ),
        ),
        StreamBuilder<double>(
          stream: player.stream.bufferingPercentage,
          builder: (_, snap) => ReadOnlyPropertyCard(
            title: 'Buffer Fill',
            subtitle: 'demuxer-cache-state',
            icon: Icons.show_chart_rounded,
            value: '${(snap.data ?? 0.0).toStringAsFixed(1)}%',
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

