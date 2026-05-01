import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../shared/property_cards.dart';

class ReplayGainPage extends StatelessWidget {
  final Player player;
  const ReplayGainPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'ReplayGain'),
        StreamBuilder<ReplayGainConfig>(
          stream: player.stream.replayGain,
          initialData: player.state.replayGain,
          builder: (context, snap) {
            final cfg = snap.data ?? const ReplayGainConfig();
            return Column(
              children: [
                SegmentedPropertyCard<ReplayGainMode>(
                  title: 'Mode',
                  subtitle: 'replaygain=${cfg.mode.mpvValue}',
                  icon: Icons.av_timer_rounded,
                  value: cfg.mode,
                  segments: const [
                    (ReplayGainMode.no, 'NONE'),
                    (ReplayGainMode.track, 'TRACK'),
                    (ReplayGainMode.album, 'ALBUM'),
                  ],
                  onChanged: (m) =>
                      player.setReplayGain(cfg.copyWith(mode: m)),
                ),
                SliderPropertyCard(
                  title: 'Preamp',
                  subtitle:
                      'replaygain-preamp=${cfg.preamp.toStringAsFixed(1)}dB',
                  icon: Icons.tune_rounded,
                  value: cfg.preamp,
                  min: -15.0,
                  max: 15.0,
                  defaultValue: 0.0,
                  labelBuilder: (v) => '${v.toStringAsFixed(1)}dB',
                  onChanged: (v) =>
                      player.setReplayGain(cfg.copyWith(preamp: v)),
                ),
                SliderPropertyCard(
                  title: 'Fallback',
                  subtitle:
                      'replaygain-fallback=${cfg.fallback.toStringAsFixed(1)}dB',
                  icon: Icons.settings_backup_restore_rounded,
                  value: cfg.fallback,
                  min: -15.0,
                  max: 15.0,
                  defaultValue: 0.0,
                  labelBuilder: (v) => '${v.toStringAsFixed(1)}dB',
                  onChanged: (v) =>
                      player.setReplayGain(cfg.copyWith(fallback: v)),
                ),
                TogglePropertyCard(
                  title: 'Allow Clipping',
                  subtitle: 'replaygain-clip=${cfg.clip ? 'yes' : 'no'}',
                  icon: Icons.high_quality_rounded,
                  value: cfg.clip,
                  onChanged: (v) =>
                      player.setReplayGain(cfg.copyWith(clip: v)),
                ),
              ],
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
