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

/// Filters in the **Modulation & creative** category. Each card maps to a typed
/// `*Settings` field on the [AudioEffects] bundle.
class FiltersModulationPage extends StatefulWidget {
  final Player player;
  const FiltersModulationPage({super.key, required this.player});

  @override
  State<FiltersModulationPage> createState() => _FiltersModulationPageState();
}

class _FiltersModulationPageState extends State<FiltersModulationPage> {
  Player get player => widget.player;

  Stream<T> _watch<T>(T Function(AudioEffects) sel) =>
      player.stream.audioEffects.map(sel).distinct();

  String _f(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StreamBuilder<AcrusherSettings>(
          stream: _watch((e) => e.acrusher),
          initialData: player.state.audioEffects.acrusher,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'acrusher',
              subtitle: 'lavfi-acrusher',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(acrusher: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'aa',
                  value: s.aa,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: .5,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(acrusher: s.copyWith(aa: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'bits',
                  value: s.bits,
                  min: 1.0,
                  max: 64.0,
                  defaultValue: 8.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(acrusher: s.copyWith(bits: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'level_in',
                  value: s.level_in,
                  min: 0.015625,
                  max: 64.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(acrusher: s.copyWith(level_in: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'level_out',
                  value: s.level_out,
                  min: 0.015625,
                  max: 64.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(acrusher: s.copyWith(level_out: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'lfo',
                  value: s.lfo,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(acrusher: s.copyWith(lfo: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'lforange',
                  value: s.lforange,
                  min: 1.0,
                  max: 250.0,
                  defaultValue: 20.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(acrusher: s.copyWith(lforange: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'mix',
                  value: s.mix,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: .5,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(acrusher: s.copyWith(mix: v)),
                  ),
                ),
                FilterParamDropdown<AcrusherMode>(
                  label: 'mode',
                  value: s.mode,
                  defaultValue: AcrusherMode.lin,
                  options: const [AcrusherMode.lin, AcrusherMode.log],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(acrusher: s.copyWith(mode: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'samples',
                  value: s.samples,
                  min: 1.0,
                  max: 250.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(acrusher: s.copyWith(samples: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AechoSettings>(
          stream: _watch((e) => e.aecho),
          initialData: player.state.audioEffects.aecho,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'aecho',
              subtitle: 'lavfi-aecho',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(aecho: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'in_gain',
                  value: s.in_gain,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 0.6,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aecho: s.copyWith(in_gain: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'out_gain',
                  value: s.out_gain,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 0.3,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aecho: s.copyWith(out_gain: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AemphasisSettings>(
          stream: _watch((e) => e.aemphasis),
          initialData: player.state.audioEffects.aemphasis,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'aemphasis',
              subtitle: 'lavfi-aemphasis',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(aemphasis: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'level_in',
                  value: s.level_in,
                  min: 0.0,
                  max: 64.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aemphasis: s.copyWith(level_in: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'level_out',
                  value: s.level_out,
                  min: 0.0,
                  max: 64.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aemphasis: s.copyWith(level_out: v)),
                  ),
                ),
                FilterParamDropdown<AemphasisMode>(
                  label: 'mode',
                  value: s.mode,
                  defaultValue: AemphasisMode.reproduction,
                  options: const [
                    AemphasisMode.reproduction,
                    AemphasisMode.production,
                  ],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aemphasis: s.copyWith(mode: v)),
                  ),
                ),
                FilterParamDropdown<AemphasisType>(
                  label: 'type',
                  value: s.type,
                  defaultValue: AemphasisType.cd,
                  options: const [
                    AemphasisType.col,
                    AemphasisType.emi,
                    AemphasisType.bsi,
                    AemphasisType.riaa,
                    AemphasisType.cd,
                    AemphasisType.n50fm,
                    AemphasisType.n75fm,
                    AemphasisType.n50kf,
                    AemphasisType.n75kf,
                  ],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aemphasis: s.copyWith(type: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AexciterSettings>(
          stream: _watch((e) => e.aexciter),
          initialData: player.state.audioEffects.aexciter,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'aexciter',
              subtitle: 'lavfi-aexciter',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(aexciter: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'amount',
                  value: s.amount,
                  min: 0.0,
                  max: 64.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aexciter: s.copyWith(amount: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'blend',
                  value: s.blend,
                  min: -10.0,
                  max: 10.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aexciter: s.copyWith(blend: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'ceil',
                  value: s.ceil,
                  min: 9999.0,
                  max: 20000.0,
                  defaultValue: 9999.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aexciter: s.copyWith(ceil: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'drive',
                  value: s.drive,
                  min: 0.1,
                  max: 10.0,
                  defaultValue: 8.5,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aexciter: s.copyWith(drive: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'freq',
                  value: s.freq,
                  min: 2000.0,
                  max: 12000.0,
                  defaultValue: 7500.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aexciter: s.copyWith(freq: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'level_in',
                  value: s.level_in,
                  min: 0.0,
                  max: 64.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aexciter: s.copyWith(level_in: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'level_out',
                  value: s.level_out,
                  min: 0.0,
                  max: 64.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aexciter: s.copyWith(level_out: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'listen',
                  value: s.listen,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aexciter: s.copyWith(listen: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AphaserSettings>(
          stream: _watch((e) => e.aphaser),
          initialData: player.state.audioEffects.aphaser,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'aphaser',
              subtitle: 'lavfi-aphaser',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(aphaser: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'delay',
                  value: s.delay,
                  min: 0.0,
                  max: 5.0,
                  defaultValue: 3.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aphaser: s.copyWith(delay: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'in_gain',
                  value: s.in_gain,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: .4,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aphaser: s.copyWith(in_gain: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'out_gain',
                  value: s.out_gain,
                  min: 0.0,
                  max: 1e9,
                  defaultValue: .74,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aphaser: s.copyWith(out_gain: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<ApulsatorSettings>(
          stream: _watch((e) => e.apulsator),
          initialData: player.state.audioEffects.apulsator,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'apulsator',
              subtitle: 'lavfi-apulsator',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(apulsator: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'amount',
                  value: s.amount,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(apulsator: s.copyWith(amount: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'bpm',
                  value: s.bpm,
                  min: 30.0,
                  max: 300.0,
                  defaultValue: 120.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(apulsator: s.copyWith(bpm: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'hz',
                  value: s.hz,
                  min: 0.01,
                  max: 100.0,
                  defaultValue: 2.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(apulsator: s.copyWith(hz: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'level_in',
                  value: s.level_in,
                  min: 0.015625,
                  max: 64.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(apulsator: s.copyWith(level_in: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'level_out',
                  value: s.level_out,
                  min: 0.015625,
                  max: 64.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(apulsator: s.copyWith(level_out: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'ms',
                  value: s.ms.toDouble(),
                  min: 10.0,
                  max: 2000.0,
                  defaultValue: 500.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(apulsator: s.copyWith(ms: v.round())),
                  ),
                ),
                FilterParamSlider(
                  label: 'offset_l',
                  value: s.offset_l,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(apulsator: s.copyWith(offset_l: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'offset_r',
                  value: s.offset_r,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: .5,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(apulsator: s.copyWith(offset_r: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'width',
                  value: s.width,
                  min: 0.0,
                  max: 2.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(apulsator: s.copyWith(width: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<ChorusSettings>(
          stream: _watch((e) => e.chorus),
          initialData: player.state.audioEffects.chorus,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'chorus',
              subtitle: 'lavfi-chorus',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(chorus: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'in_gain',
                  value: s.in_gain,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: .4,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(chorus: s.copyWith(in_gain: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'out_gain',
                  value: s.out_gain,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: .4,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(chorus: s.copyWith(out_gain: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<CrystalizerSettings>(
          stream: _watch((e) => e.crystalizer),
          initialData: player.state.audioEffects.crystalizer,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'crystalizer',
              subtitle: 'lavfi-crystalizer',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(crystalizer: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSwitch(
                  label: 'c',
                  value: s.c,
                  defaultValue: true,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(crystalizer: s.copyWith(c: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'i',
                  value: s.i,
                  min: -10.0,
                  max: 10.0,
                  defaultValue: 2.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(crystalizer: s.copyWith(i: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<DcshiftSettings>(
          stream: _watch((e) => e.dcshift),
          initialData: player.state.audioEffects.dcshift,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'dcshift',
              subtitle: 'lavfi-dcshift',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(dcshift: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'limitergain',
                  value: s.limitergain,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(dcshift: s.copyWith(limitergain: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'shift',
                  value: s.shift,
                  min: -1.0,
                  max: 1.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(dcshift: s.copyWith(shift: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<FlangerSettings>(
          stream: _watch((e) => e.flanger),
          initialData: player.state.audioEffects.flanger,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'flanger',
              subtitle: 'lavfi-flanger',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(flanger: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'delay',
                  value: s.delay,
                  min: 0.0,
                  max: 30.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(flanger: s.copyWith(delay: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'depth',
                  value: s.depth,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 2.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(flanger: s.copyWith(depth: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'phase',
                  value: s.phase,
                  min: 0.0,
                  max: 100.0,
                  defaultValue: 25.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(flanger: s.copyWith(phase: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'regen',
                  value: s.regen,
                  min: -95.0,
                  max: 95.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(flanger: s.copyWith(regen: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'speed',
                  value: s.speed,
                  min: 0.1,
                  max: 10.0,
                  defaultValue: 0.5,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(flanger: s.copyWith(speed: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'width',
                  value: s.width,
                  min: 0.0,
                  max: 100.0,
                  defaultValue: 71.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(flanger: s.copyWith(width: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<HdcdSettings>(
          stream: _watch((e) => e.hdcd),
          initialData: player.state.audioEffects.hdcd,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'hdcd',
              subtitle: 'lavfi-hdcd',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(hdcd: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamDropdown<HdcdBitsPerSample>(
                  label: 'bits_per_sample',
                  value: s.bits_per_sample,
                  defaultValue: HdcdBitsPerSample.n16,
                  options: const [
                    HdcdBitsPerSample.n16,
                    HdcdBitsPerSample.n20,
                    HdcdBitsPerSample.n24,
                  ],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(hdcd: s.copyWith(bits_per_sample: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'cdt_ms',
                  value: s.cdt_ms.toDouble(),
                  min: 100.0,
                  max: 60000.0,
                  defaultValue: 2000.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(hdcd: s.copyWith(cdt_ms: v.round())),
                  ),
                ),
                FilterParamSwitch(
                  label: 'disable_autoconvert',
                  value: s.disable_autoconvert,
                  defaultValue: true,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(hdcd: s.copyWith(disable_autoconvert: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'force_pe',
                  value: s.force_pe,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(hdcd: s.copyWith(force_pe: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<TremoloSettings>(
          stream: _watch((e) => e.tremolo),
          initialData: player.state.audioEffects.tremolo,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'tremolo',
              subtitle: 'lavfi-tremolo',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(tremolo: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'd',
                  value: s.d,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 0.5,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(tremolo: s.copyWith(d: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'f',
                  value: s.f,
                  min: 0.1,
                  max: 20000.0,
                  defaultValue: 5.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(tremolo: s.copyWith(f: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<VibratoSettings>(
          stream: _watch((e) => e.vibrato),
          initialData: player.state.audioEffects.vibrato,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'vibrato',
              subtitle: 'lavfi-vibrato',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(vibrato: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'd',
                  value: s.d,
                  min: 0.00,
                  max: 1.0,
                  defaultValue: 0.5,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(vibrato: s.copyWith(d: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'f',
                  value: s.f,
                  min: 0.1,
                  max: 20000.0,
                  defaultValue: 5.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(vibrato: s.copyWith(f: v)),
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
