import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/property_cards.dart';

class AudioPage extends StatelessWidget {
  final Player player;
  const AudioPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final desktopOnly =
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.linux;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Physical Output'),
        StreamBuilder<List<AudioDevice>>(
          stream: player.stream.audioDevices,
          initialData: player.state.audioDevices,
          builder: (context, snapshot) {
            var devices = snapshot.data ?? [];
            if (!devices.any((d) => d.name == 'auto')) {
              devices = [
                const AudioDevice('auto', 'Default (auto)'),
                ...devices,
              ];
            }
            return StreamBuilder<AudioDevice>(
              stream: player.stream.audioDevice,
              initialData: player.state.audioDevice,
              builder: (context, deviceSnap) {
                final currentDevice =
                    deviceSnap.data ?? const AudioDevice('auto', 'Auto');
                final currentValue =
                    devices.any((d) => d.name == currentDevice.name)
                    ? currentDevice.name
                    : 'auto';
                return DropdownPropertyCard<String>(
                  title: 'Audio Device',
                  subtitle: 'audio-device=$currentValue',
                  icon: Icons.speaker_group_rounded,
                  value: currentValue,
                  items: devices
                      .map(
                        (d) => DropdownMenuItem(
                          value: d.name,
                          child: Text(
                            d.name == 'auto' ? 'Default (auto)' : d.description,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      final device = devices.firstWhere(
                        (d) => d.name == v,
                        orElse: () => AudioDevice(v, v),
                      );
                      player.setAudioDevice(device);
                    }
                  },
                );
              },
            );
          },
        ),
        StreamBuilder<String>(
          stream: player.stream.audioSpdif,
          initialData: player.state.audioSpdif,
          builder: (context, snap) {
            final val = snap.data ?? '';
            final options = ['', 'ac3', 'dts', 'ac3,dts'];
            if (!options.contains(val)) options.add(val);
            return DropdownPropertyCard<String>(
              title: 'S/PDIF Passthrough',
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
              onChanged: (v) => v != null ? player.setAudioSpdif(v) : null,
            );
          },
        ),
        const PropertySectionHeader(title: 'Signal Format'),
        StreamBuilder<int>(
          stream: player.stream.audioSampleRate,
          initialData: player.state.audioSampleRate,
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
              onChanged: (v) => v != null ? player.setAudioSampleRate(v) : null,
            );
          },
        ),
        StreamBuilder<String>(
          stream: player.stream.audioFormat,
          initialData: player.state.audioFormat,
          builder: (context, snap) {
            final val = snap.data ?? 'no';
            final options = ['no', 'u8', 'u8p', 's16', 's16p', 's32', 's32p', 'float', 'floatp', 'double', 'doublep'];
            if (!options.contains(val)) options.add(val);
            return DropdownPropertyCard<String>(
              title: 'Output Format',
              subtitle: 'audio-format=$val',
              icon: Icons.settings_applications_rounded,
              value: val,
              items: options
                  .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(v == 'no' ? 'Auto' : v),
                      ))
                  .toList(),
              onChanged: (v) => v != null ? player.setAudioFormat(v) : null,
            );
          },
        ),
        StreamBuilder<String>(
          stream: player.stream.audioChannels,
          initialData: player.state.audioChannels,
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
              onChanged: (v) => v != null ? player.setAudioChannels(v) : null,
            );
          },
        ),
        StreamBuilder<String>(
          stream: player.stream.audioClientName,
          initialData: player.state.audioClientName,
          builder: (context, snap) {
            final val = snap.data ?? 'mpv_audio_kit';
            return TextPropertyCard(
              title: 'Client Name',
              subtitle: 'audio-client-name=$val',
              icon: Icons.app_settings_alt_rounded,
              value: val,
              onSubmitted: player.setAudioClientName,
            );
          },
        ),

        const PropertySectionHeader(title: 'Sync & Delay'),
        StreamBuilder<double>(
          stream: player.stream.audioDelay,
          initialData: player.state.audioDelay,
          builder: (context, snap) {
            final val = snap.data ?? 0.0;
            return SliderPropertyCard(
              title: 'Audio Sync Delay',
              subtitle: 'audio-delay=${val.toStringAsFixed(3)}s',
              icon: Icons.timer_rounded,
              value: val,
              min: -5.0,
              max: 5.0,
              defaultValue: 0.0,
              labelBuilder: (v) => '${v.toStringAsFixed(3)}s',
              onChanged: player.setAudioDelay,
            );
          },
        ),

        const PropertySectionHeader(title: 'Hardware'),
        StreamBuilder<double>(
          stream: player.stream.audioBuffer,
          initialData: player.state.audioBuffer,
          builder: (context, snap) {
            final val = snap.data ?? 0.2;
            return SliderPropertyCard(
              title: 'Audio Buffer',
              subtitle: 'audio-buffer=${val.toStringAsFixed(3)}',
              icon: Icons.storage_rounded,
              value: val,
              min: 0.0,
              max: 2.0,
              defaultValue: 0.2,
              labelBuilder: (v) => '${v.toStringAsFixed(1)}s',
              onChanged: (v) =>
                  player.setRawProperty('audio-buffer', v.toStringAsFixed(3)),
            );
          },
        ),
        StreamBuilder<bool>(
          stream: player.stream.audioExclusive,
          initialData: player.state.audioExclusive,
          builder: (context, snap) {
            final val = snap.data ?? false;
            return IgnorePointer(
              ignoring: !desktopOnly,
              child: Opacity(
                opacity: desktopOnly ? 1.0 : 0.4,
                child: TogglePropertyCard(
                  title: 'Exclusive Mode',
                  subtitle: 'audio-exclusive=${val ? 'yes' : 'no'}',
                  icon: Icons.priority_high_rounded,
                  value: val,
                  onChanged: player.setAudioExclusive,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
