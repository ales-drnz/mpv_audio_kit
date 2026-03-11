import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/ui_helpers.dart';

class SystemTab extends StatefulWidget {
  final Player player;
  const SystemTab({super.key, required this.player});

  @override
  State<SystemTab> createState() => _SystemTabState();
}

class _SystemTabState extends State<SystemTab> {
  bool _audioExclusive = false;
  bool _fallbackToNull = false;
  double _audioBuffer = 0.2;
  bool _streamSilence = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildSectionCard(context, 'Advanced Buffer & System', [
          buildSliderRow('Buffer (s)', _audioBuffer, 0.0, 2.0, (v) {
            setState(() => _audioBuffer = v);
            widget.player.setRawProperty('audio-buffer', v.toStringAsFixed(3));
          }),
          Wrap(
            spacing: 16,
            children: [
              buildToggle('Exclusive Mode', _audioExclusive, (v) {
                setState(() => _audioExclusive = v);
                widget.player.setAudioExclusive(v);
              }),
              buildToggle('Fallback to Null', _fallbackToNull, (v) {
                setState(() => _fallbackToNull = v);
                widget.player.setRawProperty('ao-null-untimed', v ? 'yes' : 'no');
              }),
              buildToggle('Stream Silence', _streamSilence, (v) {
                setState(() => _streamSilence = v);
                widget.player.setRawProperty('stream-silence', v ? 'yes' : 'no');
              }),
            ],
          ),
        ]),
      ],
    );
  }
}
