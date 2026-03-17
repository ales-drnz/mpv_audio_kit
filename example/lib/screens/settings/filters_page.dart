import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/property_cards.dart';
import '../../widgets/eq_widget.dart';

class FiltersPage extends StatelessWidget {
  final Player player;
  const FiltersPage({super.key, required this.player});

  bool _isActive(List<AudioFilter> filters, String name) =>
      filters.any((f) => f.value.contains(name));

  void _toggle(List<AudioFilter> current, String name, bool enable,
      {AudioFilter? specific}) {
    final list = List<AudioFilter>.from(current);
    if (enable) {
      if (!_isActive(list, name)) list.add(specific ?? AudioFilter.custom(name));
    } else {
      list.removeWhere((f) => f.value.contains(name));
    }
    player.setAudioFilters(list);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AudioFilter>>(
      stream: player.stream.activeFilters,
      initialData: player.state.activeFilters,
      builder: (context, snap) {
        final active = snap.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const PropertySectionHeader(title: 'Equalizer'),
            StreamBuilder<List<double>>(
              stream: player.stream.equalizerGains,
              initialData: player.state.equalizerGains,
              builder: (context, eqSnap) {
                final gains = eqSnap.data ?? List.filled(10, 0.0);
                final eqEnabled = _isActive(active, 'equalizer');
                return PropertyBaseCard(
                  title: '10-Band Equalizer',
                  subtitle: 'af=equalizer',
                  icon: Icons.equalizer_rounded,
                  isActive: eqEnabled,
                  trailing: Switch(
                    value: eqEnabled,
                    onChanged: (v) => _toggle(active, 'equalizer', v,
                        specific: AudioFilter.equalizer(gains)),
                  ),
                  body: EQWidget(
                    gains: gains,
                    enabled: eqEnabled,
                    onChanged: (i, v) {
                      final newGains = List<double>.from(gains)..[i] = v;
                      player.setEqualizerGains(newGains);
                      if (eqEnabled) {
                        _toggle(active, 'equalizer', true,
                            specific: AudioFilter.equalizer(newGains));
                      }
                    },
                  ),
                );
              },
            ),

            const PropertySectionHeader(title: 'Dynamics'),
            TogglePropertyCard(
              title: 'Compressor',
              subtitle: 'af=acompressor',
              icon: Icons.vignette_rounded,
              value: _isActive(active, 'acompressor'),
              onChanged: (v) => _toggle(active, 'acompressor', v,
                  specific: AudioFilter.compressor()),
            ),
            TogglePropertyCard(
              title: 'Loudnorm',
              subtitle: 'af=loudnorm',
              icon: Icons.graphic_eq_rounded,
              value: _isActive(active, 'loudnorm'),
              onChanged: (v) => _toggle(active, 'loudnorm', v,
                  specific: AudioFilter.loudnorm()),
            ),

            const PropertySectionHeader(title: 'Stereo & Effects'),
            TogglePropertyCard(
              title: 'Extra Stereo',
              subtitle: 'af=extrastereo',
              icon: Icons.surround_sound_rounded,
              value: _isActive(active, 'extrastereo'),
              onChanged: (v) => _toggle(active, 'extrastereo', v,
                  specific: AudioFilter.extraStereo()),
            ),
            TogglePropertyCard(
              title: 'Crystalizer',
              subtitle: 'af=crystalizer',
              icon: Icons.auto_fix_high_rounded,
              value: _isActive(active, 'crystalizer'),
              onChanged: (v) => _toggle(active, 'crystalizer', v,
                  specific: AudioFilter.crystalizer()),
            ),
            TogglePropertyCard(
              title: 'Echo',
              subtitle: 'af=aecho',
              icon: Icons.settings_input_antenna_rounded,
              value: _isActive(active, 'aecho'),
              onChanged: (v) =>
                  _toggle(active, 'aecho', v, specific: AudioFilter.echo()),
            ),
            TogglePropertyCard(
              title: 'Crossfeed',
              subtitle: 'af=crossfeed',
              icon: Icons.headphones_rounded,
              value: _isActive(active, 'crossfeed'),
              onChanged: (v) => _toggle(active, 'crossfeed', v,
                  specific: AudioFilter.crossfeed()),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
