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
        StreamBuilder<ReplayGainMode>(
          stream: player.stream.replayGainMode,
          initialData: player.state.replayGainMode,
          builder: (context, snap) {
            final mode = snap.data ?? ReplayGainMode.no;
            return SegmentedPropertyCard<ReplayGainMode>(
              title: 'Mode',
              subtitle: 'replaygain=${mode.mpvValue}',
              icon: Icons.av_timer_rounded,
              value: mode,
              segments: const [
                (ReplayGainMode.no, 'NONE'),
                (ReplayGainMode.track, 'TRACK'),
                (ReplayGainMode.album, 'ALBUM'),
              ],
              onChanged: player.setReplayGainMode,
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
        StreamBuilder<GaplessMode>(
          stream: player.stream.gaplessMode,
          initialData: player.state.gaplessMode,
          builder: (context, snap) {
            final mode = snap.data ?? GaplessMode.weak;
            return SegmentedPropertyCard<GaplessMode>(
              title: 'Gapless Playback',
              subtitle: 'gapless-audio=${mode.mpvValue}',
              icon: Icons.leak_add_rounded,
              value: mode,
              segments: const [
                (GaplessMode.no, 'NONE'),
                (GaplessMode.yes, 'YES'),
                (GaplessMode.weak, 'WEAK'),
              ],
              onChanged: player.setGaplessMode,
            );
          },
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
