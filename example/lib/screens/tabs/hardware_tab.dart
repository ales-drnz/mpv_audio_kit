import 'package:flutter/material.dart';
import 'package:mpv_audio_pro_kit/mpv_audio_pro_kit.dart';
import '../../widgets/ui_helpers.dart';

class HardwareTab extends StatefulWidget {
  final Player player;
  const HardwareTab({super.key, required this.player});

  @override
  State<HardwareTab> createState() => _HardwareTabState();
}

class _HardwareTabState extends State<HardwareTab> {
  int _sampleRate = 0;
  String _audioFormat = 'auto';
  String _audioChannels = 'auto';
  double _volumeMax = 100.0;
  String _clientName = 'mpv_audio_kit';
  String _audioDevice = 'auto';
  String _audioTrack = 'auto';
  String _audioOutputDriver = 'auto';
  String _audioSpdif = '';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildSectionCard(context, 'Hardware & Routing', [
          buildDropdownRow<String>(
            'Audio Driver (ao)',
            _audioOutputDriver,
            [
              'auto',
              'coreaudio',
              'wasapi',
              'alsa',
              'opensles',
              'audiotrack',
              'null',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            (v) {
              if (v != null) {
                setState(() => _audioOutputDriver = v);
                widget.player.setAudioOutputDriver(v);
              }
            },
          ),
          StreamBuilder<List<AudioDevice>>(
            stream: widget.player.stream.audioDevices,
            initialData: widget.player.state.audioDevices,
            builder: (context, snapshot) {
              var devices = snapshot.data ?? [];

              // Ensure 'auto' is always present to avoid DropdownButton errors.
              if (!devices.any((d) => d.name == 'auto')) {
                devices = [
                  const AudioDevice('auto', 'Default (auto)'),
                  ...devices,
                ];
              }

              // Guard against the selected device disappearing from the list.
              final currentDeviceValue = devices.any((d) => d.name == _audioDevice)
                  ? _audioDevice
                  : 'auto';

              return buildDropdownRow<String>(
                'Audio Device',
                currentDeviceValue,
                devices.map((d) {
                  return DropdownMenuItem(
                    value: d.name,
                    child: SizedBox(
                      width: 200,
                      child: Text(
                        d.name == 'auto' ? 'Default (auto)' : d.description,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }).toList(),
                (v) {
                  if (v != null) {
                    setState(() => _audioDevice = v);
                    final device = devices.firstWhere(
                      (d) => d.name == v,
                      orElse: () => AudioDevice(v, v),
                    );
                    widget.player.setAudioDevice(device);
                  }
                },
              );
            },
          ),
          buildDropdownRow<String>(
            'Audio Track (aid)',
            _audioTrack,
            [
              'auto',
              'no',
              '1',
              '2',
              '3',
              '4',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            (v) {
              if (v != null) {
                setState(() => _audioTrack = v);
                widget.player.setAudioTrack(v);
              }
            },
          ),
          buildDropdownRow<String>(
            'S/PDIF (HDMI)',
            _audioSpdif,
            ['', 'ac3', 'dts', 'ac3,dts']
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(v == '' ? 'None/Decode' : 'Passthrough: $v'),
                  ),
                )
                .toList(),
            (v) {
              if (v != null) {
                setState(() => _audioSpdif = v);
                widget.player.setAudioSpdif(v);
              }
            },
          ),
          const SizedBox(height: 8),
          buildDropdownRow<double>(
            'Max Volume',
            _volumeMax,
            [100.0, 150.0, 200.0, 300.0, 500.0, 1000.0]
                .map(
                  (v) =>
                      DropdownMenuItem(value: v, child: Text('${v.toInt()}%')),
                )
                .toList(),
            (v) {
              if (v != null) {
                setState(() => _volumeMax = v);
                widget.player.setVolumeMax(v);
              }
            },
          ),
          buildDropdownRow<int>(
            'Sample Rate',
            _sampleRate,
            [0, 44100, 48000, 88200, 96000, 192000, 384000]
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(v == 0 ? 'Auto' : '$v Hz'),
                  ),
                )
                .toList(),
            (v) {
              if (v != null) {
                setState(() => _sampleRate = v);
                widget.player.setRawProperty('audio-samplerate', v.toString());
              }
            },
          ),
          buildDropdownRow<String>(
            'Format',
            _audioFormat,
            [
              'auto',
              'u8',
              's16',
              's32',
              'f32',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            (v) {
              if (v != null) {
                setState(() => _audioFormat = v);
                widget.player.setRawProperty('audio-format', v);
              }
            },
          ),
          buildDropdownRow<String>(
            'Channels',
            _audioChannels,
            [
              'auto',
              'mono',
              'stereo',
              '2.1',
              '5.1',
              '7.1',
              'auto-safe',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            (v) {
              if (v != null) {
                setState(() => _audioChannels = v);
                widget.player.setRawProperty('audio-channels', v);
              }
            },
          ),
          buildDropdownRow<String>(
            'Client Name',
            _clientName,
            [
              'mpv',
              'mpv_audio_kit',
              'custom_app_audio',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            (v) {
              if (v != null) {
                setState(() => _clientName = v);
                widget.player.setRawProperty('audio-client-name', v);
              }
            },
          ),
        ]),
      ],
    );
  }
}
