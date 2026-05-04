import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

/// Volume slider + mute toggle + percentage readout. Stateful because
/// of the optimistic [_dragValue] held during drag — isolating it here
/// means the rest of the playback tab does not rebuild on every drag
/// frame.
class VolumeControl extends StatefulWidget {
  final Player player;

  const VolumeControl({super.key, required this.player});

  @override
  State<VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<VolumeControl> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: widget.player.stream.volume,
      initialData: widget.player.state.volume,
      builder: (context, volSnap) {
        final vol = volSnap.data ?? 100.0;
        final displayVol = _dragValue ?? vol;

        return Row(
          children: [
            StreamBuilder<bool>(
              stream: widget.player.stream.mute,
              initialData: widget.player.state.mute,
              builder: (context, muteSnap) {
                final isMute = muteSnap.data ?? false;
                return IconButton(
                  icon: Icon(
                    isMute ? Icons.volume_off : Icons.volume_down,
                    size: 20,
                  ),
                  onPressed: () => widget.player.setMute(!isMute),
                );
              },
            ),
            Expanded(
              child: Slider(
                min: 0,
                max: 100,
                value: displayVol.clamp(0.0, 100.0),
                onChanged: (v) => setState(() => _dragValue = v),
                onChangeEnd: (v) async {
                  widget.player.setVolume(v);
                  // Wait for the volume observer to confirm the
                  // optimistic update before releasing the drag value,
                  // so the slider doesn't snap back to a stale value
                  // mid-roundtrip. Bound the wait so a stalled stream
                  // can't pin the UI.
                  try {
                    await widget.player.stream.volume
                        .firstWhere((x) => (x - v).abs() < 0.5)
                        .timeout(const Duration(milliseconds: 600));
                  } catch (_) {
                    // Timeout / stream closed: release anyway.
                  }
                  if (mounted) {
                    setState(() => _dragValue = null);
                  }
                },
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '${displayVol.round()}%',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}
