import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/shared/property_cards.dart';

class RoutingTab extends StatefulWidget {
  final Player player;
  const RoutingTab({super.key, required this.player});

  @override
  State<RoutingTab> createState() => _RoutingTabState();
}

class _RoutingTabState extends State<RoutingTab> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Physical Output'),
        StreamBuilder<List<AudioDevice>>(
          stream: widget.player.stream.audioDevices,
          initialData: widget.player.state.audioDevices,
          builder: (context, snapshot) {
            var devices = snapshot.data ?? [];
            if (!devices.any((d) => d.name == 'auto')) {
              devices = [
                const AudioDevice('auto', 'Default (auto)'),
                ...devices,
              ];
            }
            return StreamBuilder<AudioDevice>(
              stream: widget.player.stream.audioDevice,
              initialData: widget.player.state.audioDevice,
              builder: (context, deviceSnap) {
                final currentDevice =
                    deviceSnap.data ?? const AudioDevice('auto', 'Auto');
                final currentDeviceValue =
                    devices.any((d) => d.name == currentDevice.name)
                    ? currentDevice.name
                    : 'auto';

                return DropdownPropertyCard<String>(
                  title: 'Audio Device',
                  subtitle: 'audio-device=$currentDeviceValue',
                  icon: Icons.speaker_group_rounded,
                  value: currentDeviceValue,
                  items: devices.map((d) {
                    return DropdownMenuItem(
                      value: d.name,
                      child: Text(
                        d.name == 'auto' ? 'Default (auto)' : d.description,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      final device = devices.firstWhere(
                        (d) => d.name == v,
                        orElse: () => AudioDevice(v, v),
                      );
                      widget.player.setAudioDevice(device);
                    }
                  },
                );
              },
            );
          },
        ),
        StreamBuilder<String>(
          stream: widget.player.stream.audioSpdif,
          initialData: widget.player.state.audioSpdif,
          builder: (context, snap) {
            final val = snap.data ?? '';
            final options = ['', 'ac3', 'dts', 'ac3,dts'];
            if (!options.contains(val)) options.add(val);

            return DropdownPropertyCard<String>(
              title: 'S/PDIF (Passthrough)',
              subtitle: 'audio-spdif=${val.isEmpty ? 'none' : val}',
              icon: Icons.settings_input_hdmi_rounded,
              value: val,
              items: options
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v == '' ? 'None/Decode' : 'Passthrough: $v'),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  v != null ? widget.player.setAudioSpdif(v) : null,
            );
          },
        ),

        const PropertySectionHeader(title: 'Stream Selection'),
        StreamBuilder<String>(
          stream: widget.player.stream.audioTrack,
          initialData: widget.player.state.audioTrack,
          builder: (context, snap) {
            final val = snap.data ?? 'auto';
            final options = ['auto', '1', '2', '3', '4'];
            if (!options.contains(val)) options.add(val);

            return DropdownPropertyCard<String>(
              title: 'Audio Track',
              subtitle: 'aid=$val',
              icon: Icons.audiotrack_rounded,
              value: val,
              items: options
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) =>
                  v != null ? widget.player.setAudioTrack(v) : null,
            );
          },
        ),

        const PropertySectionHeader(title: 'Digital Signal Routing'),
        StreamBuilder<double>(
          stream: widget.player.stream.audioDelay,
          initialData: widget.player.state.audioDelay,
          builder: (context, snap) {
            final delay = snap.data ?? 0.0;
            return SliderPropertyCard(
              title: 'Audio Sync Delay',
              subtitle: 'audio-delay=${delay.toStringAsFixed(3)}s',
              icon: Icons.timer_rounded,
              value: delay,
              min: -5.0,
              max: 5.0,
              label: '${delay.toStringAsFixed(3)}s',
              onChanged: widget.player.setAudioDelay,
            );
          },
        ),
        StreamBuilder<double>(
          stream: widget.player.stream.volumeMax,
          initialData: widget.player.state.volumeMax,
          builder: (context, snap) {
                final val = snap.data ?? 130.0;
                final options = [100.0, 130.0, 150.0, 200.0, 300.0, 500.0, 1000.0];
                if (!options.contains(val)) options.add(val);
                options.sort();

                return DropdownPropertyCard<double>(
                  title: 'Max Volume Limit',
                  subtitle: 'volume-max=${val.toInt()}%',
                  icon: Icons.volume_up_rounded,
                  value: val,
                  items: options
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text('${v.toInt()}%'),
                        ),
                      )
                      .toList(),
              onChanged: (v) =>
                  v != null ? widget.player.setVolumeMax(v) : null,
            );
          },
        ),
        StreamBuilder<int>(
          stream: widget.player.stream.audioSampleRate,
          initialData: widget.player.state.audioSampleRate,
          builder: (context, snap) {
                final val = snap.data ?? 0;
                final options = [0, 44100, 48000, 88200, 96000, 192000, 384000];
                if (!options.contains(val)) options.add(val);
                options.sort();

                return DropdownPropertyCard<int>(
                  title: 'Sample Rate',
                  subtitle: 'audio-samplerate=${val == 0 ? 'auto' : val}',
                  icon: Icons.graphic_eq_rounded,
                  value: val,
                  items: options
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v == 0 ? 'Auto' : '$v Hz'),
                        ),
                      )
                      .toList(),
              onChanged: (v) => v != null ? widget.player.setAudioSampleRate(v) : null,
            );
          },
        ),
        StreamBuilder<String>(
          stream: widget.player.stream.audioFormat,
          initialData: widget.player.state.audioFormat,
          builder: (context, snap) {
                final val = snap.data ?? 'auto';
                final options = ['auto', 'u8', 's16', 's32', 'float', 'double'];
                if (!options.contains(val)) options.add(val);

                return DropdownPropertyCard<String>(
                  title: 'Output Format',
                  subtitle: 'audio-format=$val',
                  icon: Icons.settings_applications_rounded,
                  value: val,
                  items: options
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
              onChanged: (v) => v != null ? widget.player.setAudioFormat(v) : null,
            );
          },
        ),
        StreamBuilder<String>(
          stream: widget.player.stream.audioChannels,
          initialData: widget.player.state.audioChannels,
          builder: (context, snap) {
                final val = snap.data ?? 'auto';
                final options = [
                  'auto',
                  'mono',
                  'stereo',
                  '2.1',
                  '5.1',
                  '7.1',
                  'auto-safe',
                ];
                if (!options.contains(val)) options.add(val);

                return DropdownPropertyCard<String>(
                  title: 'Audio Channels',
                  subtitle: 'audio-channels=$val',
                  icon: Icons.settings_input_component_rounded,
                  value: val,
                  items: options
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
              onChanged: (v) => v != null ? widget.player.setAudioChannels(v) : null,
            );
          },
        ),
        StreamBuilder<String>(
          stream: widget.player.stream.audioClientName,
          initialData: widget.player.state.audioClientName,
          builder: (context, snap) {
                final val = snap.data ?? 'mpv_audio_kit';
                final options = ['mpv', 'mpv_audio_kit', 'custom_app_audio'];
                if (!options.contains(val)) options.add(val);

                return DropdownPropertyCard<String>(
                  title: 'Client Name',
                  subtitle: 'audio-client-name=$val',
                  icon: Icons.app_settings_alt_rounded,
                  value: val,
                  items: options
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
              onChanged: (v) => v != null ? widget.player.setAudioClientName(v) : null,
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
