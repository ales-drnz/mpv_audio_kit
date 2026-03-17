import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/property_cards.dart';

class ReplayGainPage extends StatelessWidget {
  final Player player;
  const ReplayGainPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'ReplayGain'),
        StreamBuilder<String>(
          stream: player.stream.replayGainMode,
          initialData: player.state.replayGainMode,
          builder: (context, snap) {
            final mode = snap.data ?? 'no';
            return SegmentedPropertyCard<String>(
              title: 'Mode',
              subtitle: 'replaygain=$mode',
              icon: Icons.av_timer_rounded,
              value: mode,
              segments: const [
                ('no', 'NONE'),
                ('track', 'TRACK'),
                ('album', 'ALBUM'),
              ],
              onChanged: player.setReplayGain,
            );
          },
        ),
        StreamBuilder<double>(
          stream: player.stream.replayGainPreamp,
          initialData: player.state.replayGainPreamp,
          builder: (context, snap) {
            final val = snap.data ?? 0.0;
            return SliderPropertyCard(
              title: 'Preamp',
              subtitle: 'replaygain-preamp=${val.toStringAsFixed(1)}dB',
              icon: Icons.tune_rounded,
              value: val,
              min: -15.0,
              max: 15.0,
              defaultValue: 0.0,
              labelBuilder: (v) => '${v.toStringAsFixed(1)}dB',
              onChanged: player.setReplayGainPreamp,
            );
          },
        ),
        StreamBuilder<double>(
          stream: player.stream.replayGainFallback,
          initialData: player.state.replayGainFallback,
          builder: (context, snap) {
            final val = snap.data ?? 0.0;
            return SliderPropertyCard(
              title: 'Fallback',
              subtitle: 'replaygain-fallback=${val.toStringAsFixed(1)}dB',
              icon: Icons.settings_backup_restore_rounded,
              value: val,
              min: -15.0,
              max: 15.0,
              defaultValue: 0.0,
              labelBuilder: (v) => '${v.toStringAsFixed(1)}dB',
              onChanged: player.setReplayGainFallback,
            );
          },
        ),
        StreamBuilder<bool>(
          stream: player.stream.replayGainClip,
          initialData: player.state.replayGainClip,
          builder: (context, snap) {
            final clip = snap.data ?? false;
            return TogglePropertyCard(
              title: 'Allow Clipping',
              subtitle: 'replaygain-clip=${clip ? 'yes' : 'no'}',
              icon: Icons.high_quality_rounded,
              value: clip,
              onChanged: player.setReplayGainClip,
            );
          },
        ),

        const PropertySectionHeader(title: 'Gapless'),
        StreamBuilder<String>(
          stream: player.stream.gaplessMode,
          initialData: player.state.gaplessMode,
          builder: (context, snap) {
            final mode = snap.data ?? 'no';
            return SegmentedPropertyCard<String>(
              title: 'Gapless Playback',
              subtitle: 'gapless-audio=$mode',
              icon: Icons.leak_add_rounded,
              value: mode,
              segments: const [
                ('no', 'NONE'),
                ('yes', 'YES'),
                ('weak', 'WEAK'),
              ],
              onChanged: player.setGaplessPlayback,
            );
          },
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
