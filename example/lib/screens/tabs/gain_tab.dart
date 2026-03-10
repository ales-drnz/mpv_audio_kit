import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/ui_helpers.dart';

class GainTab extends StatefulWidget {
  final MpvPlayer player;
  const GainTab({super.key, required this.player});

  @override
  State<GainTab> createState() => _GainTabState();
}

class _GainTabState extends State<GainTab> {
  String _gaplessAudio = 'weak';
  String _replayGain = 'no';
  double _replayGainPreamp = 0.0;
  bool _replayGainClip = false;
  double _replayGainFallback = 0.0;
  double _volumeGain = 0.0;
  double _volumeGainMin = -96.0;
  double _volumeGainMax = 12.0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildSectionCard(context, 'ReplayGain & Gapless', [
          buildDropdownRow<String>(
            'Gapless',
            _gaplessAudio,
            [
              'no',
              'yes',
              'weak',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            (v) {
              if (v != null) {
                setState(() => _gaplessAudio = v);
                widget.player.setGaplessAudio(v);
              }
            },
          ),
          buildDropdownRow<String>(
            'ReplayGain',
            _replayGain,
            [
              'no',
              'track',
              'album',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            (v) {
              if (v != null) {
                setState(() => _replayGain = v);
                widget.player.setReplayGain(v);
              }
            },
          ),
          buildSliderRow('Preamp (dB)', _replayGainPreamp, -15.0, 15.0, (v) {
            setState(() => _replayGainPreamp = v);
            widget.player.setReplayGainPreamp(v);
          }),
          buildSliderRow('Fallback (dB)', _replayGainFallback, -15.0, 15.0, (
            v,
          ) {
            setState(() => _replayGainFallback = v);
            widget.player.setReplayGainFallback(v);
          }),
          Wrap(
            spacing: 16,
            children: [
              buildToggle('Allow Clipping', _replayGainClip, (v) {
                setState(() => _replayGainClip = v);
                widget.player.setReplayGainClip(v);
              }),
            ],
          ),
        ]),
        const SizedBox(height: 16),
        buildSectionCard(context, 'Global Volume Gain', [
          buildSliderRow(
            'Volume Gain (dB)',
            _volumeGain,
            _volumeGainMin,
            _volumeGainMax,
            (v) {
              setState(() => _volumeGain = v);
              widget.player.setVolumeGain(v);
            },
          ),
          buildSliderRow('Min Gain (dB limit)', _volumeGainMin, -150.0, 0.0, (
            v,
          ) {
            setState(() {
              _volumeGainMin = v;
              if (_volumeGain < _volumeGainMin) _volumeGain = _volumeGainMin;
            });
            widget.player.setVolumeGainMin(v);
            widget.player.setVolumeGain(_volumeGain);
          }),
          buildSliderRow('Max Gain (dB limit)', _volumeGainMax, 0.0, 150.0, (
            v,
          ) {
            setState(() {
              _volumeGainMax = v;
              if (_volumeGain > _volumeGainMax) _volumeGain = _volumeGainMax;
            });
            widget.player.setVolumeGainMax(v);
            widget.player.setVolumeGain(_volumeGain);
          }),
        ]),
      ],
    );
  }
}
