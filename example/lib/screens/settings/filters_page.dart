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
  // Niche custom filter parameters. The four mainstream stages
  // (equalizer / compressor / loudness / pitch-tempo) live entirely in
  // PlayerState and need no local mirror.
  double _esM = 2.0;
  double _cryIntensity = 2.0;
  double _echoDelay = 200;
  double _echoFalloff = 0.4;

  static const _kExtraStereoPrefix = 'lavfi-extrastereo';
  static const _kCrystalizerPrefix = 'lavfi-crystalizer';
  static const _kEchoPrefix = 'lavfi-aecho';
  static const _kCrossfeedPrefix = 'lavfi-crossfeed';

  bool _customActive(List<String> customs, String prefix) =>
      customs.any((f) => f.startsWith(prefix));

  Future<void> _upsertCustom(
    List<String> customs,
    String prefix,
    bool enable, {
    String? newValue,
  }) {
    final next = customs.where((f) => !f.startsWith(prefix)).toList();
    if (enable) next.add(newValue ?? prefix);
    return widget.player.setCustomAudioFilters(next);
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Equalizer ──────────────────────────────────────────────────
        const PropertySectionHeader(title: 'Equalizer'),
        StreamBuilder<EqualizerConfig>(
          stream: player.stream.equalizer,
          initialData: player.state.equalizer,
          builder: (context, snap) {
            final eq = snap.data!;
            return PropertyBaseCard(
              title: '10-Band Equalizer',
              subtitle: 'EqualizerConfig',
              icon: Icons.equalizer_rounded,
              isActive: eq.enabled,
              trailing: Switch(
                value: eq.enabled,
                onChanged: (v) =>
                    player.setEqualizer(eq.copyWith(enabled: v)),
              ),
              body: EQWidget(
                gains: eq.gains,
                enabled: eq.enabled,
                onChanged: (i, v) {
                  final newGains = List<double>.from(eq.gains)..[i] = v;
                  player.setEqualizer(eq.copyWith(gains: newGains));
                },
              ),
            );
          },
        ),

        // ── Dynamics ───────────────────────────────────────────────────
        const PropertySectionHeader(title: 'Dynamics'),
        StreamBuilder<CompressorConfig>(
          stream: player.stream.compressor,
          initialData: player.state.compressor,
          builder: (context, snap) {
            final c = snap.data!;
            return ExpandableFilterCard(
              title: 'Compressor',
              subtitle:
                  'threshold=${c.threshold.toStringAsFixed(0)}dB ratio=${c.ratio.toStringAsFixed(1)}:1 '
                  'attack=${c.attack.inMilliseconds}ms release=${c.release.inMilliseconds}ms',
              icon: Icons.vignette_rounded,
              enabled: c.enabled,
              onToggle: (v) =>
                  player.setCompressor(c.copyWith(enabled: v)),
              params: [
                FilterParamSlider(
                  label: 'Threshold',
                  value: c.threshold,
                  min: -60,
                  max: 0,
                  divisions: 60,
                  defaultValue: -20,
                  labelBuilder: (v) => '${v.toStringAsFixed(0)} dB',
                  onChanged: (v) =>
                      player.setCompressor(c.copyWith(threshold: v)),
                ),
                FilterParamSlider(
                  label: 'Ratio',
                  value: c.ratio,
                  min: 1,
                  max: 20,
                  divisions: 38,
                  defaultValue: 4,
                  labelBuilder: (v) => '${v.toStringAsFixed(1)}:1',
                  onChanged: (v) =>
                      player.setCompressor(c.copyWith(ratio: v)),
                ),
                FilterParamSlider(
                  label: 'Attack',
                  value: c.attack.inMilliseconds.toDouble(),
                  min: 1,
                  max: 2000,
                  divisions: 200,
                  defaultValue: 20,
                  labelBuilder: (v) => '${v.toStringAsFixed(0)} ms',
                  onChanged: (v) => player.setCompressor(
                    c.copyWith(attack: Duration(milliseconds: v.toInt())),
                  ),
                ),
                FilterParamSlider(
                  label: 'Release',
                  value: c.release.inMilliseconds.toDouble(),
                  min: 1,
                  max: 9000,
                  divisions: 200,
                  defaultValue: 250,
                  labelBuilder: (v) => '${v.toStringAsFixed(0)} ms',
                  onChanged: (v) => player.setCompressor(
                    c.copyWith(release: Duration(milliseconds: v.toInt())),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<LoudnessConfig>(
          stream: player.stream.loudness,
          initialData: player.state.loudness,
          builder: (context, snap) {
            final l = snap.data!;
            return ExpandableFilterCard(
              title: 'Loudness (EBU R128)',
              subtitle:
                  'I=${l.integratedLoudness.toStringAsFixed(0)}LUFS '
                  'TP=${l.truePeak.toStringAsFixed(1)}dBTP '
                  'LRA=${l.lra.toStringAsFixed(0)}LU',
              icon: Icons.graphic_eq_rounded,
              enabled: l.enabled,
              onToggle: (v) => player.setLoudness(l.copyWith(enabled: v)),
              params: [
                FilterParamSlider(
                  label: 'Integrated Loudness',
                  value: l.integratedLoudness,
                  min: -70,
                  max: -5,
                  divisions: 65,
                  defaultValue: -16,
                  labelBuilder: (v) => '${v.toStringAsFixed(0)} LUFS',
                  onChanged: (v) =>
                      player.setLoudness(l.copyWith(integratedLoudness: v)),
                ),
                FilterParamSlider(
                  label: 'True Peak',
                  value: l.truePeak,
                  min: -9,
                  max: 0,
                  divisions: 90,
                  defaultValue: -1.5,
                  labelBuilder: (v) => '${v.toStringAsFixed(1)} dBTP',
                  onChanged: (v) =>
                      player.setLoudness(l.copyWith(truePeak: v)),
                ),
                FilterParamSlider(
                  label: 'Loudness Range',
                  value: l.lra,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  defaultValue: 11,
                  labelBuilder: (v) => '${v.toStringAsFixed(0)} LU',
                  onChanged: (v) =>
                      player.setLoudness(l.copyWith(lra: v)),
                ),
              ],
            );
          },
        ),

        // ── Pitch / Tempo ──────────────────────────────────────────────
        const PropertySectionHeader(title: 'Pitch / Tempo'),
        StreamBuilder<PitchTempoConfig>(
          stream: player.stream.pitchTempo,
          initialData: player.state.pitchTempo,
          builder: (context, snap) {
            final p = snap.data!;
            return ExpandableFilterCard(
              title: 'Rubberband',
              subtitle:
                  'pitch=${p.pitch.toStringAsFixed(2)} tempo=${p.tempo.toStringAsFixed(2)}',
              icon: Icons.tune_rounded,
              enabled: p.enabled,
              onToggle: (v) =>
                  player.setPitchTempo(p.copyWith(enabled: v)),
              params: [
                FilterParamSlider(
                  label: 'Pitch',
                  value: p.pitch,
                  min: 0.25,
                  max: 4.0,
                  divisions: 75,
                  defaultValue: 1.0,
                  labelBuilder: (v) => v.toStringAsFixed(2),
                  onChanged: (v) =>
                      player.setPitchTempo(p.copyWith(pitch: v)),
                ),
                FilterParamSlider(
                  label: 'Tempo',
                  value: p.tempo,
                  min: 0.25,
                  max: 4.0,
                  divisions: 75,
                  defaultValue: 1.0,
                  labelBuilder: (v) => v.toStringAsFixed(2),
                  onChanged: (v) =>
                      player.setPitchTempo(p.copyWith(tempo: v)),
                ),
              ],
            );
          },
        ),

        // ── Stereo & Effects (custom mpv filters) ──────────────────────
        const PropertySectionHeader(title: 'Stereo & Effects'),
        StreamBuilder<List<String>>(
          stream: player.stream.customAudioFilters,
          initialData: player.state.customAudioFilters,
          builder: (context, snap) {
            final customs = snap.data ?? const <String>[];
            final esActive = _customActive(customs, _kExtraStereoPrefix);
            final cryActive = _customActive(customs, _kCrystalizerPrefix);
            final echoActive = _customActive(customs, _kEchoPrefix);
            final cfActive = _customActive(customs, _kCrossfeedPrefix);

            return Column(
              children: [
                ExpandableFilterCard(
                  title: 'Extra Stereo',
                  subtitle: '$_kExtraStereoPrefix m=${_esM.toStringAsFixed(1)}',
                  icon: Icons.surround_sound_rounded,
                  enabled: esActive,
                  onToggle: (v) => _upsertCustom(
                    customs,
                    _kExtraStereoPrefix,
                    v,
                    newValue: '$_kExtraStereoPrefix=m=$_esM',
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
                          _upsertCustom(
                            customs,
                            _kExtraStereoPrefix,
                            true,
                            newValue: '$_kExtraStereoPrefix=m=$v',
                          );
                        }
                      },
                    ),
                  ],
                ),
                ExpandableFilterCard(
                  title: 'Crystalizer',
                  subtitle:
                      '$_kCrystalizerPrefix i=${_cryIntensity.toStringAsFixed(1)}',
                  icon: Icons.auto_fix_high_rounded,
                  enabled: cryActive,
                  onToggle: (v) => _upsertCustom(
                    customs,
                    _kCrystalizerPrefix,
                    v,
                    newValue: '$_kCrystalizerPrefix=i=$_cryIntensity',
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
                          _upsertCustom(
                            customs,
                            _kCrystalizerPrefix,
                            true,
                            newValue: '$_kCrystalizerPrefix=i=$v',
                          );
                        }
                      },
                    ),
                  ],
                ),
                ExpandableFilterCard(
                  title: 'Echo',
                  subtitle:
                      '$_kEchoPrefix delay=${_echoDelay.toStringAsFixed(0)}ms '
                      'falloff=${_echoFalloff.toStringAsFixed(2)}',
                  icon: Icons.settings_input_antenna_rounded,
                  enabled: echoActive,
                  onToggle: (v) => _upsertCustom(
                    customs,
                    _kEchoPrefix,
                    v,
                    newValue:
                        '$_kEchoPrefix=0.8:0.8:${_echoDelay.toInt()}:$_echoFalloff',
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
                          _upsertCustom(
                            customs,
                            _kEchoPrefix,
                            true,
                            newValue:
                                '$_kEchoPrefix=0.8:0.8:${v.toInt()}:$_echoFalloff',
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
                          _upsertCustom(
                            customs,
                            _kEchoPrefix,
                            true,
                            newValue:
                                '$_kEchoPrefix=0.8:0.8:${_echoDelay.toInt()}:$v',
                          );
                        }
                      },
                    ),
                  ],
                ),
                TogglePropertyCard(
                  title: 'Crossfeed',
                  subtitle: _kCrossfeedPrefix,
                  icon: Icons.headphones_rounded,
                  value: cfActive,
                  onChanged: (v) =>
                      _upsertCustom(customs, _kCrossfeedPrefix, v),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
