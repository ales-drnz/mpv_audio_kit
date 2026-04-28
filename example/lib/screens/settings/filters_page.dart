import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/property_cards.dart';
import '../../widgets/eq_widget.dart';

class FiltersPage extends StatefulWidget {
  final Player player;
  const FiltersPage({super.key, required this.player});

  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage> {
  // Compressor
  double _cmpThreshold = -20;
  double _cmpRatio = 4;
  double _cmpAttack = 20;
  double _cmpRelease = 250;

  // Loudnorm
  double _lnIL = -16;
  double _lnTP = -1.5;
  double _lnLRA = 11;

  // Extra Stereo
  double _esM = 2.0;

  // Crystalizer
  double _cryIntensity = 2.0;

  // Echo
  double _echoDelay = 200;
  double _echoFalloff = 0.4;

  bool _isActive(List<AudioFilter> filters, String name) =>
      filters.any((f) => f.value.contains(name));

  void _toggle(
    List<AudioFilter> current,
    String name,
    bool enable, {
    AudioFilter? specific,
  }) {
    final list = List<AudioFilter>.from(current)
      ..removeWhere((f) => f.value.contains(name));
    if (enable) list.add(specific ?? AudioFilter.custom(name));
    widget.player.setActiveFilters(list);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AudioFilter>>(
      stream: widget.player.stream.activeFilters,
      initialData: widget.player.state.activeFilters,
      builder: (context, snap) {
        final active = snap.data ?? [];

        final cmpActive = _isActive(active, 'acompressor');
        final lnActive = _isActive(active, 'loudnorm');
        final esActive = _isActive(active, 'extrastereo');
        final cryActive = _isActive(active, 'crystalizer');
        final echoActive = _isActive(active, 'aecho');
        final cfActive = _isActive(active, 'crossfeed');

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Equalizer ──────────────────────────────────────────────────
            const PropertySectionHeader(title: 'Equalizer'),
            StreamBuilder<List<double>>(
              stream: widget.player.stream.equalizerGains,
              initialData: widget.player.state.equalizerGains,
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
                    onChanged: (v) => _toggle(
                      active,
                      'equalizer',
                      v,
                      specific: AudioFilter.equalizer(gains),
                    ),
                  ),
                  body: EQWidget(
                    gains: gains,
                    enabled: eqEnabled,
                    onChanged: (i, v) {
                      final newGains = List<double>.from(gains)..[i] = v;
                      widget.player.setEqualizerGains(newGains);
                      if (eqEnabled) {
                        _toggle(
                          active,
                          'equalizer',
                          true,
                          specific: AudioFilter.equalizer(newGains),
                        );
                      }
                    },
                  ),
                );
              },
            ),

            // ── Dynamics ───────────────────────────────────────────────────
            const PropertySectionHeader(title: 'Dynamics'),
            ExpandableFilterCard(
              title: 'Compressor',
              subtitle:
                  'af=acompressor threshold=${_cmpThreshold.toStringAsFixed(0)}dB ratio=${_cmpRatio.toStringAsFixed(1)}:1 attack=${_cmpAttack.toStringAsFixed(0)}ms release=${_cmpRelease.toStringAsFixed(0)}ms',
              icon: Icons.vignette_rounded,
              enabled: cmpActive,
              onToggle: (v) => _toggle(
                active,
                'acompressor',
                v,
                specific: AudioFilter.compressor(
                  threshold: _cmpThreshold,
                  ratio: _cmpRatio,
                  attack: _cmpAttack,
                  release: _cmpRelease,
                ),
              ),
              params: [
                FilterParamSlider(
                  label: 'Threshold',
                  value: _cmpThreshold,
                  min: -60,
                  max: 0,
                  divisions: 60,
                  defaultValue: -20,
                  labelBuilder: (v) => '${v.toStringAsFixed(0)} dB',
                  onChanged: (v) {
                    setState(() => _cmpThreshold = v);
                    if (cmpActive) {
                      _toggle(
                        active,
                        'acompressor',
                        true,
                        specific: AudioFilter.compressor(
                          threshold: v,
                          ratio: _cmpRatio,
                          attack: _cmpAttack,
                          release: _cmpRelease,
                        ),
                      );
                    }
                  },
                ),
                FilterParamSlider(
                  label: 'Ratio',
                  value: _cmpRatio,
                  min: 1,
                  max: 20,
                  divisions: 38,
                  defaultValue: 4,
                  labelBuilder: (v) => '${v.toStringAsFixed(1)}:1',
                  onChanged: (v) {
                    setState(() => _cmpRatio = v);
                    if (cmpActive) {
                      _toggle(
                        active,
                        'acompressor',
                        true,
                        specific: AudioFilter.compressor(
                          threshold: _cmpThreshold,
                          ratio: v,
                          attack: _cmpAttack,
                          release: _cmpRelease,
                        ),
                      );
                    }
                  },
                ),
                FilterParamSlider(
                  label: 'Attack',
                  value: _cmpAttack,
                  min: 1,
                  max: 2000,
                  divisions: 200,
                  defaultValue: 20,
                  labelBuilder: (v) => '${v.toStringAsFixed(0)} ms',
                  onChanged: (v) {
                    setState(() => _cmpAttack = v);
                    if (cmpActive) {
                      _toggle(
                        active,
                        'acompressor',
                        true,
                        specific: AudioFilter.compressor(
                          threshold: _cmpThreshold,
                          ratio: _cmpRatio,
                          attack: v,
                          release: _cmpRelease,
                        ),
                      );
                    }
                  },
                ),
                FilterParamSlider(
                  label: 'Release',
                  value: _cmpRelease,
                  min: 1,
                  max: 9000,
                  divisions: 200,
                  defaultValue: 250,
                  labelBuilder: (v) => '${v.toStringAsFixed(0)} ms',
                  onChanged: (v) {
                    setState(() => _cmpRelease = v);
                    if (cmpActive) {
                      _toggle(
                        active,
                        'acompressor',
                        true,
                        specific: AudioFilter.compressor(
                          threshold: _cmpThreshold,
                          ratio: _cmpRatio,
                          attack: _cmpAttack,
                          release: v,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            ExpandableFilterCard(
              title: 'Loudnorm',
              subtitle:
                  'af=loudnorm I=${_lnIL.toStringAsFixed(0)}LUFS TP=${_lnTP.toStringAsFixed(1)}dBTP LRA=${_lnLRA.toStringAsFixed(0)}LU',
              icon: Icons.graphic_eq_rounded,
              enabled: lnActive,
              onToggle: (v) => _toggle(
                active,
                'loudnorm',
                v,
                specific: AudioFilter.loudnorm(
                  integratedLoudness: _lnIL,
                  truePeak: _lnTP,
                  lra: _lnLRA,
                ),
              ),
              params: [
                FilterParamSlider(
                  label: 'Integrated Loudness',
                  value: _lnIL,
                  min: -70,
                  max: -5,
                  divisions: 65,
                  defaultValue: -16,
                  labelBuilder: (v) => '${v.toStringAsFixed(0)} LUFS',
                  onChanged: (v) {
                    setState(() => _lnIL = v);
                    if (lnActive) {
                      _toggle(
                        active,
                        'loudnorm',
                        true,
                        specific: AudioFilter.loudnorm(
                          integratedLoudness: v,
                          truePeak: _lnTP,
                          lra: _lnLRA,
                        ),
                      );
                    }
                  },
                ),
                FilterParamSlider(
                  label: 'True Peak',
                  value: _lnTP,
                  min: -9,
                  max: 0,
                  divisions: 90,
                  defaultValue: -1.5,
                  labelBuilder: (v) => '${v.toStringAsFixed(1)} dBTP',
                  onChanged: (v) {
                    setState(() => _lnTP = v);
                    if (lnActive) {
                      _toggle(
                        active,
                        'loudnorm',
                        true,
                        specific: AudioFilter.loudnorm(
                          integratedLoudness: _lnIL,
                          truePeak: v,
                          lra: _lnLRA,
                        ),
                      );
                    }
                  },
                ),
                FilterParamSlider(
                  label: 'Loudness Range',
                  value: _lnLRA,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  defaultValue: 11,
                  labelBuilder: (v) => '${v.toStringAsFixed(0)} LU',
                  onChanged: (v) {
                    setState(() => _lnLRA = v);
                    if (lnActive) {
                      _toggle(
                        active,
                        'loudnorm',
                        true,
                        specific: AudioFilter.loudnorm(
                          integratedLoudness: _lnIL,
                          truePeak: _lnTP,
                          lra: v,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),

            // ── Stereo & Effects ───────────────────────────────────────────
            const PropertySectionHeader(title: 'Stereo & Effects'),
            ExpandableFilterCard(
              title: 'Extra Stereo',
              subtitle: 'af=extrastereo m=${_esM.toStringAsFixed(1)}',
              icon: Icons.surround_sound_rounded,
              enabled: esActive,
              onToggle: (v) => _toggle(
                active,
                'extrastereo',
                v,
                specific: AudioFilter.extraStereo(m: _esM),
              ),
              params: [
                FilterParamSlider(
                  label: 'Width',
                  value: _esM,
                  min: 0.0,
                  max: 5.0,
                  divisions: 50,
                  defaultValue: 2.0,
                  labelBuilder: (v) => v.toStringAsFixed(1),
                  onChanged: (v) {
                    setState(() => _esM = v);
                    if (esActive) {
                      _toggle(
                        active,
                        'extrastereo',
                        true,
                        specific: AudioFilter.extraStereo(m: v),
                      );
                    }
                  },
                ),
              ],
            ),
            ExpandableFilterCard(
              title: 'Crystalizer',
              subtitle: 'af=crystalizer i=${_cryIntensity.toStringAsFixed(1)}',
              icon: Icons.auto_fix_high_rounded,
              enabled: cryActive,
              onToggle: (v) => _toggle(
                active,
                'crystalizer',
                v,
                specific: AudioFilter.crystalizer(intensity: _cryIntensity),
              ),
              params: [
                FilterParamSlider(
                  label: 'Intensity',
                  value: _cryIntensity,
                  min: 0.0,
                  max: 10.0,
                  divisions: 100,
                  defaultValue: 2.0,
                  labelBuilder: (v) => v.toStringAsFixed(1),
                  onChanged: (v) {
                    setState(() => _cryIntensity = v);
                    if (cryActive) {
                      _toggle(
                        active,
                        'crystalizer',
                        true,
                        specific: AudioFilter.crystalizer(intensity: v),
                      );
                    }
                  },
                ),
              ],
            ),
            ExpandableFilterCard(
              title: 'Echo',
              subtitle:
                  'af=aecho delay=${_echoDelay.toStringAsFixed(0)}ms falloff=${_echoFalloff.toStringAsFixed(2)}',
              icon: Icons.settings_input_antenna_rounded,
              enabled: echoActive,
              onToggle: (v) => _toggle(
                active,
                'aecho',
                v,
                specific: AudioFilter.echo(
                  delay: _echoDelay.toInt(),
                  falloff: _echoFalloff,
                ),
              ),
              params: [
                FilterParamSlider(
                  label: 'Delay',
                  value: _echoDelay,
                  min: 0,
                  max: 1000,
                  divisions: 100,
                  defaultValue: 200,
                  labelBuilder: (v) => '${v.toStringAsFixed(0)} ms',
                  onChanged: (v) {
                    setState(() => _echoDelay = v);
                    if (echoActive) {
                      _toggle(
                        active,
                        'aecho',
                        true,
                        specific: AudioFilter.echo(
                          delay: v.toInt(),
                          falloff: _echoFalloff,
                        ),
                      );
                    }
                  },
                ),
                FilterParamSlider(
                  label: 'Falloff',
                  value: _echoFalloff,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  defaultValue: 0.4,
                  labelBuilder: (v) => v.toStringAsFixed(2),
                  onChanged: (v) {
                    setState(() => _echoFalloff = v);
                    if (echoActive) {
                      _toggle(
                        active,
                        'aecho',
                        true,
                        specific: AudioFilter.echo(
                          delay: _echoDelay.toInt(),
                          falloff: v,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            TogglePropertyCard(
              title: 'Crossfeed',
              subtitle: 'af=crossfeed',
              icon: Icons.headphones_rounded,
              value: cfActive,
              onChanged: (v) => _toggle(
                active,
                'crossfeed',
                v,
                specific: AudioFilter.crossfeed(),
              ),
            ),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
