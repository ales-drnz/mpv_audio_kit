import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../shared/property_cards.dart';

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
        StreamBuilder<List<Device>>(
          stream: player.stream.audioDevices,
          initialData: player.state.audioDevices,
          builder: (context, snapshot) {
            var devices = snapshot.data ?? [];
            if (!devices.any((d) => d.name == 'auto')) {
              devices = [
                const Device('auto', 'Default (auto)'),
                ...devices,
              ];
            }
            return StreamBuilder<Device>(
              stream: player.stream.audioDevice,
              initialData: player.state.audioDevice,
              builder: (context, deviceSnap) {
                final currentDevice =
                    deviceSnap.data ?? const Device('auto', 'Auto');
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
                        orElse: () => Device(v, v),
                      );
                      player.setAudioDevice(device);
                    }
                  },
                );
              },
            );
          },
        ),
        StreamBuilder<Set<Spdif>>(
          stream: player.stream.audioSpdif,
          initialData: player.state.audioSpdif,
          builder: (context, snap) {
            final selected = snap.data ?? const <Spdif>{};
            final wire = selected.isEmpty
                ? 'none'
                : Spdif.formatMpvList(selected);
            return PropertyBaseCard(
              title: 'S/PDIF Passthrough',
              subtitle: 'audio-spdif=$wire',
              icon: Icons.settings_input_hdmi_rounded,
              isActive: selected.isNotEmpty,
              body: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: Spdif.values
                    .map(
                      (codec) => FilterChip(
                        label: Text(codec.mpvValue),
                        selected: selected.contains(codec),
                        onSelected: (on) {
                          final next = {...selected};
                          on ? next.add(codec) : next.remove(codec);
                          player.setAudioSpdif(next);
                        },
                      ),
                    )
                    .toList(),
              ),
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
        StreamBuilder<Format>(
          stream: player.stream.audioFormat,
          initialData: player.state.audioFormat,
          builder: (context, snap) {
            final val = snap.data ?? Format.auto;
            return DropdownPropertyCard<Format>(
              title: 'Output Format',
              subtitle: 'audio-format=${val.mpvValue}',
              icon: Icons.settings_applications_rounded,
              value: val,
              items: Format.values
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v == Format.auto ? 'Auto' : v.mpvValue),
                    ),
                  )
                  .toList(),
              onChanged: (v) => v != null ? player.setAudioFormat(v) : null,
            );
          },
        ),
        StreamBuilder<Channels>(
          stream: player.stream.audioChannels,
          initialData: player.state.audioChannels,
          builder: (context, snap) {
            final val = snap.data ?? Channels.auto;
            final options = <Channels>[
              Channels.auto,
              Channels.mono,
              Channels.stereo,
              Channels.twoOne,
              Channels.fiveOne,
              Channels.sevenOne,
              Channels.autoSafe,
            ];
            if (!options.contains(val)) options.add(val);
            return DropdownPropertyCard<Channels>(
              title: 'Audio Channels',
              subtitle: 'audio-channels=${val.mpvValue}',
              icon: Icons.settings_input_component_rounded,
              value: val,
              items: options
                  .map(
                    (v) => DropdownMenuItem(value: v, child: Text(v.mpvValue)),
                  )
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
        StreamBuilder<Duration>(
          stream: player.stream.audioDelay,
          initialData: player.state.audioDelay,
          builder: (context, snap) {
            final secs = (snap.data ?? Duration.zero).inMicroseconds / 1e6;
            return SliderPropertyCard(
              title: 'Audio Sync Delay',
              subtitle: 'audio-delay=${secs.toStringAsFixed(3)}s',
              icon: Icons.timer_rounded,
              value: secs,
              min: -5.0,
              max: 5.0,
              defaultValue: 0.0,
              labelBuilder: (v) => '${v.toStringAsFixed(3)}s',
              onChanged: (v) => player.setAudioDelay(
                Duration(microseconds: (v * 1e6).round()),
              ),
            );
          },
        ),

        const PropertySectionHeader(title: 'Hardware'),
        StreamBuilder<Duration>(
          stream: player.stream.audioBuffer,
          initialData: player.state.audioBuffer,
          builder: (context, snap) {
            final secs =
                (snap.data ?? const Duration(milliseconds: 200))
                    .inMicroseconds /
                1e6;
            return SliderPropertyCard(
              title: 'Audio Buffer',
              subtitle: 'audio-buffer=${secs.toStringAsFixed(3)}',
              icon: Icons.storage_rounded,
              value: secs,
              min: 0.0,
              max: 2.0,
              defaultValue: 0.2,
              labelBuilder: (v) => '${v.toStringAsFixed(1)}s',
              onChanged: (v) => player.setAudioBuffer(
                Duration(microseconds: (v * 1e6).round()),
              ),
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
