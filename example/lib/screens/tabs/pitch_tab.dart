import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/ui_helpers.dart';

class PitchTab extends StatefulWidget {
  final MpvPlayer player;
  const PitchTab({super.key, required this.player});

  @override
  State<PitchTab> createState() => _PitchTabState();
}

class _PitchTabState extends State<PitchTab> {
  bool _pitchCorrection = true;
  double _speed = 1.0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildSectionCard(context, 'Playback & Pitch', [
          StreamBuilder<double>(
            stream: widget.player.audioDelayStream,
            initialData: widget.player.audioDelay,
            builder: (_, snap) => buildSliderRow(
              'Delay (s)',
              snap.data ?? 0.0,
              -5.0,
              5.0,
              widget.player.setAudioDelay,
            ),
          ),
          StreamBuilder<double>(
            stream: widget.player.pitchStream,
            initialData: widget.player.pitch,
            builder: (_, snap) => buildSliderRow(
              'Pitch',
              snap.data ?? 1.0,
              0.5,
              2.0,
              widget.player.setPitch,
            ),
          ),
          buildSliderRow('Speed', _speed, 0.5, 2.0, (v) {
            setState(() => _speed = v);
            widget.player.setSpeed(v);
          }),
          Wrap(
            spacing: 16,
            children: [
              buildToggle('Pitch Correction', _pitchCorrection, (v) {
                setState(() => _pitchCorrection = v);
                widget.player.setPitchCorrection(v);
              }),
            ],
          ),
        ]),
      ],
    );
  }
}
