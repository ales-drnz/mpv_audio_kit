import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/shared/property_cards.dart';

class DemuxCacheTab extends StatefulWidget {
  final Player player;
  const DemuxCacheTab({super.key, required this.player});

  @override
  State<DemuxCacheTab> createState() => _DemuxCacheTabState();
}

class _DemuxCacheTabState extends State<DemuxCacheTab> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Cache Configuration'),
        StreamBuilder<String>(
          stream: widget.player.stream.cacheMode,
          initialData: widget.player.state.cacheMode,
          builder: (context, snap) {
            final val = snap.data ?? 'auto';
            final options = ['auto', 'yes', 'no'];
            if (!options.contains(val)) options.add(val);

            return DropdownPropertyCard<String>(
              title: 'Cache Mode',
              subtitle: 'cache=$val',
              icon: Icons.cached_rounded,
              value: val,
              items: options
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) => v != null ? widget.player.setCache(v) : null,
            );
          },
        ),
        StreamBuilder<double>(
          stream: widget.player.stream.cacheSecs,
          initialData: widget.player.state.cacheSecs,
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
              label: '${val.toInt()}s',
              onChanged: widget.player.setCacheSecs,
            );
          },
        ),
        StreamBuilder<bool>(
          stream: widget.player.stream.cacheOnDisk,
          initialData: widget.player.state.cacheOnDisk,
          builder: (context, snap) {
            final val = snap.data ?? false;
            return TogglePropertyCard(
              title: 'Cache on Disk',
              subtitle: 'cache-on-disk=${val ? 'yes' : 'no'}',
              icon: Icons.save_alt_rounded,
              value: val,
              onChanged: widget.player.setCacheOnDisk,
            );
          },
        ),
        StreamBuilder<bool>(
          stream: widget.player.stream.cachePause,
          initialData: widget.player.state.cachePause,
          builder: (context, snap) {
            final val = snap.data ?? true;
            return TogglePropertyCard(
              title: 'Pause on Buffer',
              subtitle: 'cache-pause=${val ? 'yes' : 'no'}',
              icon: Icons.pause_circle_outline_rounded,
              value: val,
              onChanged: widget.player.setCachePause,
            );
          },
        ),
        StreamBuilder<double>(
          stream: widget.player.stream.cachePauseWait,
          initialData: widget.player.state.cachePauseWait,
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
              label: '${val.toStringAsFixed(1)}s',
              onChanged: widget.player.setCachePauseWait,
            );
          },
        ),

        const PropertySectionHeader(title: 'Demuxer Performance'),
        StreamBuilder<int>(
          stream: widget.player.stream.demuxerMaxBytes,
          initialData: widget.player.state.demuxerMaxBytes,
          builder: (context, snap) {
            final bytes = snap.data ?? (150 * 1024 * 1024);
            final mib = bytes / (1024 * 1024);
            return SliderPropertyCard(
              title: 'Max Cache Size',
              subtitle: 'demuxer-max-bytes=${mib.toInt()}MiB',
              icon: Icons.memory_rounded,
              value: mib,
              min: 1.0,
              max: 2048.0,
              divisions: 2048,
              label: '${mib.toInt()}MiB',
              onChanged: (v) => widget.player.setDemuxerMaxBytes((v * 1024 * 1024).toInt()),
            );
          },
        ),
        StreamBuilder<int>(
          stream: widget.player.stream.demuxerReadaheadSecs,
          initialData: widget.player.state.demuxerReadaheadSecs,
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
              label: '${val.toInt()}s',
              onChanged: (v) => widget.player.setDemuxerReadaheadSecs(v.toInt()),
            );
          },
        ),
        StreamBuilder<int>(
          stream: widget.player.stream.demuxerMaxBackBytes,
          initialData: widget.player.state.demuxerMaxBackBytes,
          builder: (context, snap) {
            final bytes = snap.data ?? (50 * 1024 * 1024);
            final mib = bytes / (1024 * 1024);
            return SliderPropertyCard(
              title: 'Seekback Pool',
              subtitle: 'demuxer-max-back-bytes=${mib.toInt()}MiB',
              icon: Icons.history_rounded,
              value: mib,
              min: 0.0,
              max: 1024.0,
              divisions: 1024,
              label: '${mib.toInt()}MiB',
              onChanged: (v) => widget.player.setDemuxerMaxBackBytes((v * 1024 * 1024).toInt()),
            );
          },
        ),

        const PropertySectionHeader(title: 'Network Connectivity'),
        StreamBuilder<double>(
          stream: widget.player.stream.networkTimeout,
          initialData: widget.player.state.networkTimeout,
          builder: (context, snap) {
            final val = snap.data ?? 30.0;
            return SliderPropertyCard(
              title: 'Network Timeout',
              subtitle: 'network-timeout=${val.toInt()}',
              icon: Icons.cloud_off_rounded,
              value: val,
              min: 1.0,
              max: 300.0,
              divisions: 300,
              label: '${val.toInt()}s',
              onChanged: widget.player.setNetworkTimeout,
            );
          },
        ),
        StreamBuilder<bool>(
          stream: widget.player.stream.tlsVerify,
          initialData: widget.player.state.tlsVerify,
          builder: (context, snap) {
            final val = snap.data ?? true;
            return TogglePropertyCard(
              title: 'Verify TLS/SSL',
              subtitle: 'tls-verify=${val ? 'yes' : 'no'}',
              icon: Icons.enhanced_encryption_rounded,
              value: val,
              onChanged: widget.player.setTlsVerify,
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
