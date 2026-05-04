// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// AUTO-GENERATED — do not edit by hand. Regenerate with
// `python3 scripts/lavfi_codegen/generate_example.py`.

import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../../../../shared/property_cards.dart';

import '../../widgets/superequalizer_widget.dart';

/// Filters in the **Equalization & tone** category. Each card maps to a typed
/// `*Settings` field on the [AudioEffects] bundle.
class FiltersEqualizationPage extends StatefulWidget {
  final Player player;
  const FiltersEqualizationPage({super.key, required this.player});

  @override
  State<FiltersEqualizationPage> createState() =>
      _FiltersEqualizationPageState();
}

class _FiltersEqualizationPageState extends State<FiltersEqualizationPage> {
  Player get player => widget.player;

  Stream<T> _watch<T>(T Function(AudioEffects) sel) =>
      player.stream.audioEffects.map(sel).distinct();

  String _f(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SuperequalizerWidget(player: player),
        StreamBuilder<AnequalizerSettings>(
          stream: _watch((e) => e.anequalizer),
          initialData: player.state.audioEffects.anequalizer,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'anequalizer',
              subtitle: 'lavfi-anequalizer',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(anequalizer: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSwitch(
                  label: 'curves',
                  value: s.curves,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(anequalizer: s.copyWith(curves: v)),
                  ),
                ),
                FilterParamDropdown<AnequalizerFscale>(
                  label: 'fscale',
                  value: s.fscale,
                  defaultValue: AnequalizerFscale.log,
                  options: const [AnequalizerFscale.lin, AnequalizerFscale.log],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(anequalizer: s.copyWith(fscale: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'mgain',
                  value: s.mgain,
                  min: -900.0,
                  max: 900.0,
                  defaultValue: 60.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(anequalizer: s.copyWith(mgain: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AsubboostSettings>(
          stream: _watch((e) => e.asubboost),
          initialData: player.state.audioEffects.asubboost,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'asubboost',
              subtitle: 'lavfi-asubboost',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(asubboost: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'boost',
                  value: s.boost,
                  min: 1.0,
                  max: 12.0,
                  defaultValue: 2.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asubboost: s.copyWith(boost: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'cutoff',
                  value: s.cutoff,
                  min: 50.0,
                  max: 900.0,
                  defaultValue: 100.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asubboost: s.copyWith(cutoff: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'decay',
                  value: s.decay,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asubboost: s.copyWith(decay: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'delay',
                  value: s.delay,
                  min: 1.0,
                  max: 100.0,
                  defaultValue: 20.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asubboost: s.copyWith(delay: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'dry',
                  value: s.dry,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asubboost: s.copyWith(dry: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'feedback',
                  value: s.feedback,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 0.9,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asubboost: s.copyWith(feedback: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'slope',
                  value: s.slope,
                  min: 0.0001,
                  max: 1.0,
                  defaultValue: 0.5,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asubboost: s.copyWith(slope: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'wet',
                  value: s.wet,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asubboost: s.copyWith(wet: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AtiltSettings>(
          stream: _watch((e) => e.atilt),
          initialData: player.state.audioEffects.atilt,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'atilt',
              subtitle: 'lavfi-atilt',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(atilt: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'freq',
                  value: s.freq,
                  min: 20.0,
                  max: 192000.0,
                  defaultValue: 10000.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(atilt: s.copyWith(freq: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'level',
                  value: s.level,
                  min: 0.0,
                  max: 4.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(atilt: s.copyWith(level: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'slope',
                  value: s.slope,
                  min: -1.0,
                  max: 1.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(atilt: s.copyWith(slope: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'width',
                  value: s.width,
                  min: 100.0,
                  max: 10000.0,
                  defaultValue: 1000.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(atilt: s.copyWith(width: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<BassSettings>(
          stream: _watch((e) => e.bass),
          initialData: player.state.audioEffects.bass,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'bass',
              subtitle: 'lavfi-bass',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(bass: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'f',
                  value: s.f,
                  min: 0.0,
                  max: 999999.0,
                  defaultValue: 100.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(bass: s.copyWith(f: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'frequency',
                  value: s.frequency,
                  min: 0.0,
                  max: 999999.0,
                  defaultValue: 100.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(bass: s.copyWith(frequency: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'g',
                  value: s.g,
                  min: -900.0,
                  max: 900.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(bass: s.copyWith(g: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'gain',
                  value: s.gain,
                  min: -900.0,
                  max: 900.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(bass: s.copyWith(gain: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'p',
                  value: s.p.toDouble(),
                  min: 1.0,
                  max: 2.0,
                  defaultValue: 2.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(bass: s.copyWith(p: v.round())),
                  ),
                ),
                FilterParamSlider(
                  label: 'poles',
                  value: s.poles.toDouble(),
                  min: 1.0,
                  max: 2.0,
                  defaultValue: 2.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(bass: s.copyWith(poles: v.round())),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<BiquadSettings>(
          stream: _watch((e) => e.biquad),
          initialData: player.state.audioEffects.biquad,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'biquad',
              subtitle: 'lavfi-biquad',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(biquad: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<EqualizerSettings>(
          stream: _watch((e) => e.equalizer),
          initialData: player.state.audioEffects.equalizer,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'equalizer',
              subtitle: 'lavfi-equalizer',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(equalizer: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'f',
                  value: s.f,
                  min: 0.0,
                  max: 999999.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(equalizer: s.copyWith(f: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'frequency',
                  value: s.frequency,
                  min: 0.0,
                  max: 999999.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(equalizer: s.copyWith(frequency: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'g',
                  value: s.g,
                  min: -900.0,
                  max: 900.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(equalizer: s.copyWith(g: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'gain',
                  value: s.gain,
                  min: -900.0,
                  max: 900.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(equalizer: s.copyWith(gain: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<FirequalizerSettings>(
          stream: _watch((e) => e.firequalizer),
          initialData: player.state.audioEffects.firequalizer,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'firequalizer',
              subtitle: 'lavfi-firequalizer',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(firequalizer: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'accuracy',
                  value: s.accuracy,
                  min: 0.0,
                  max: 1e10,
                  defaultValue: 5.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(firequalizer: s.copyWith(accuracy: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'delay',
                  value: s.delay,
                  min: 0.0,
                  max: 1e10,
                  defaultValue: 0.01,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(firequalizer: s.copyWith(delay: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'fft2',
                  value: s.fft2,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(firequalizer: s.copyWith(fft2: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'fixed',
                  value: s.fixed,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(firequalizer: s.copyWith(fixed: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'min_phase',
                  value: s.min_phase,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(firequalizer: s.copyWith(min_phase: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'multi',
                  value: s.multi,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(firequalizer: s.copyWith(multi: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'zero_phase',
                  value: s.zero_phase,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(firequalizer: s.copyWith(zero_phase: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<HighshelfSettings>(
          stream: _watch((e) => e.highshelf),
          initialData: player.state.audioEffects.highshelf,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'highshelf',
              subtitle: 'lavfi-highshelf',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(highshelf: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'f',
                  value: s.f,
                  min: 0.0,
                  max: 999999.0,
                  defaultValue: 3000.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(highshelf: s.copyWith(f: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'frequency',
                  value: s.frequency,
                  min: 0.0,
                  max: 999999.0,
                  defaultValue: 3000.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(highshelf: s.copyWith(frequency: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'g',
                  value: s.g,
                  min: -900.0,
                  max: 900.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(highshelf: s.copyWith(g: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'gain',
                  value: s.gain,
                  min: -900.0,
                  max: 900.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(highshelf: s.copyWith(gain: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'p',
                  value: s.p.toDouble(),
                  min: 1.0,
                  max: 2.0,
                  defaultValue: 2.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(highshelf: s.copyWith(p: v.round())),
                  ),
                ),
                FilterParamSlider(
                  label: 'poles',
                  value: s.poles.toDouble(),
                  min: 1.0,
                  max: 2.0,
                  defaultValue: 2.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(highshelf: s.copyWith(poles: v.round())),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<LowshelfSettings>(
          stream: _watch((e) => e.lowshelf),
          initialData: player.state.audioEffects.lowshelf,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'lowshelf',
              subtitle: 'lavfi-lowshelf',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(lowshelf: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'f',
                  value: s.f,
                  min: 0.0,
                  max: 999999.0,
                  defaultValue: 100.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(lowshelf: s.copyWith(f: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'frequency',
                  value: s.frequency,
                  min: 0.0,
                  max: 999999.0,
                  defaultValue: 100.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(lowshelf: s.copyWith(frequency: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'g',
                  value: s.g,
                  min: -900.0,
                  max: 900.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(lowshelf: s.copyWith(g: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'gain',
                  value: s.gain,
                  min: -900.0,
                  max: 900.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(lowshelf: s.copyWith(gain: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'p',
                  value: s.p.toDouble(),
                  min: 1.0,
                  max: 2.0,
                  defaultValue: 2.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(lowshelf: s.copyWith(p: v.round())),
                  ),
                ),
                FilterParamSlider(
                  label: 'poles',
                  value: s.poles.toDouble(),
                  min: 1.0,
                  max: 2.0,
                  defaultValue: 2.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(lowshelf: s.copyWith(poles: v.round())),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<TiltshelfSettings>(
          stream: _watch((e) => e.tiltshelf),
          initialData: player.state.audioEffects.tiltshelf,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'tiltshelf',
              subtitle: 'lavfi-tiltshelf',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(tiltshelf: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'f',
                  value: s.f,
                  min: 0.0,
                  max: 999999.0,
                  defaultValue: 3000.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(tiltshelf: s.copyWith(f: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'frequency',
                  value: s.frequency,
                  min: 0.0,
                  max: 999999.0,
                  defaultValue: 3000.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(tiltshelf: s.copyWith(frequency: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'g',
                  value: s.g,
                  min: -900.0,
                  max: 900.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(tiltshelf: s.copyWith(g: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'gain',
                  value: s.gain,
                  min: -900.0,
                  max: 900.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(tiltshelf: s.copyWith(gain: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'p',
                  value: s.p.toDouble(),
                  min: 1.0,
                  max: 2.0,
                  defaultValue: 2.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(tiltshelf: s.copyWith(p: v.round())),
                  ),
                ),
                FilterParamSlider(
                  label: 'poles',
                  value: s.poles.toDouble(),
                  min: 1.0,
                  max: 2.0,
                  defaultValue: 2.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(tiltshelf: s.copyWith(poles: v.round())),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<TrebleSettings>(
          stream: _watch((e) => e.treble),
          initialData: player.state.audioEffects.treble,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'treble',
              subtitle: 'lavfi-treble',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(treble: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'f',
                  value: s.f,
                  min: 0.0,
                  max: 999999.0,
                  defaultValue: 3000.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(treble: s.copyWith(f: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'frequency',
                  value: s.frequency,
                  min: 0.0,
                  max: 999999.0,
                  defaultValue: 3000.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(treble: s.copyWith(frequency: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'g',
                  value: s.g,
                  min: -900.0,
                  max: 900.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(treble: s.copyWith(g: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'gain',
                  value: s.gain,
                  min: -900.0,
                  max: 900.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(treble: s.copyWith(gain: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'p',
                  value: s.p.toDouble(),
                  min: 1.0,
                  max: 2.0,
                  defaultValue: 2.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(treble: s.copyWith(p: v.round())),
                  ),
                ),
                FilterParamSlider(
                  label: 'poles',
                  value: s.poles.toDouble(),
                  min: 1.0,
                  max: 2.0,
                  defaultValue: 2.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(treble: s.copyWith(poles: v.round())),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
