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

/// Filters in the **Filters (cut / pass)** category. Each card maps to a typed
/// `*Settings` field on the [AudioEffects] bundle.
class FiltersCutPassPage extends StatefulWidget {
  final Player player;
  const FiltersCutPassPage({super.key, required this.player});

  @override
  State<FiltersCutPassPage> createState() => _FiltersCutPassPageState();
}

class _FiltersCutPassPageState extends State<FiltersCutPassPage> {
  Player get player => widget.player;

  Stream<T> _watch<T>(T Function(AudioEffects) sel) =>
      player.stream.audioEffects.map(sel).distinct();

  String _f(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StreamBuilder<AllpassSettings>(
          stream: _watch((e) => e.allpass),
          initialData: player.state.audioEffects.allpass,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'allpass',
              subtitle: 'lavfi-allpass',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(allpass: s.copyWith(enabled: v)),
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
                    (e) => e.copyWith(allpass: s.copyWith(f: v)),
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
                    (e) => e.copyWith(allpass: s.copyWith(frequency: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'o',
                  value: s.o.toDouble(),
                  min: 1.0,
                  max: 2.0,
                  defaultValue: 2.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(allpass: s.copyWith(o: v.round())),
                  ),
                ),
                FilterParamSlider(
                  label: 'order',
                  value: s.order.toDouble(),
                  min: 1.0,
                  max: 2.0,
                  defaultValue: 2.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(allpass: s.copyWith(order: v.round())),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AsubcutSettings>(
          stream: _watch((e) => e.asubcut),
          initialData: player.state.audioEffects.asubcut,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'asubcut',
              subtitle: 'lavfi-asubcut',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(asubcut: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'cutoff',
                  value: s.cutoff,
                  min: 2.0,
                  max: 200.0,
                  defaultValue: 20.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asubcut: s.copyWith(cutoff: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'level',
                  value: s.level,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asubcut: s.copyWith(level: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'order',
                  value: s.order.toDouble(),
                  min: 3.0,
                  max: 20.0,
                  defaultValue: 10.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asubcut: s.copyWith(order: v.round())),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AsupercutSettings>(
          stream: _watch((e) => e.asupercut),
          initialData: player.state.audioEffects.asupercut,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'asupercut',
              subtitle: 'lavfi-asupercut',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(asupercut: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'cutoff',
                  value: s.cutoff,
                  min: 20000.0,
                  max: 192000.0,
                  defaultValue: 20000.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asupercut: s.copyWith(cutoff: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'level',
                  value: s.level,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asupercut: s.copyWith(level: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'order',
                  value: s.order.toDouble(),
                  min: 3.0,
                  max: 20.0,
                  defaultValue: 10.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asupercut: s.copyWith(order: v.round())),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AsuperpassSettings>(
          stream: _watch((e) => e.asuperpass),
          initialData: player.state.audioEffects.asuperpass,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'asuperpass',
              subtitle: 'lavfi-asuperpass',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(asuperpass: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'centerf',
                  value: s.centerf,
                  min: 2.0,
                  max: 999999.0,
                  defaultValue: 1000.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asuperpass: s.copyWith(centerf: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'level',
                  value: s.level,
                  min: 0.0,
                  max: 2.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asuperpass: s.copyWith(level: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'order',
                  value: s.order.toDouble(),
                  min: 4.0,
                  max: 20.0,
                  defaultValue: 4.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asuperpass: s.copyWith(order: v.round())),
                  ),
                ),
                FilterParamSlider(
                  label: 'qfactor',
                  value: s.qfactor,
                  min: 0.01,
                  max: 100.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asuperpass: s.copyWith(qfactor: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AsuperstopSettings>(
          stream: _watch((e) => e.asuperstop),
          initialData: player.state.audioEffects.asuperstop,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'asuperstop',
              subtitle: 'lavfi-asuperstop',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(asuperstop: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'centerf',
                  value: s.centerf,
                  min: 2.0,
                  max: 999999.0,
                  defaultValue: 1000.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asuperstop: s.copyWith(centerf: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'level',
                  value: s.level,
                  min: 0.0,
                  max: 2.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asuperstop: s.copyWith(level: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'order',
                  value: s.order.toDouble(),
                  min: 4.0,
                  max: 20.0,
                  defaultValue: 4.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asuperstop: s.copyWith(order: v.round())),
                  ),
                ),
                FilterParamSlider(
                  label: 'qfactor',
                  value: s.qfactor,
                  min: 0.01,
                  max: 100.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(asuperstop: s.copyWith(qfactor: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<BandpassSettings>(
          stream: _watch((e) => e.bandpass),
          initialData: player.state.audioEffects.bandpass,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'bandpass',
              subtitle: 'lavfi-bandpass',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(bandpass: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSwitch(
                  label: 'csg',
                  value: s.csg,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(bandpass: s.copyWith(csg: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'f',
                  value: s.f,
                  min: 0.0,
                  max: 999999.0,
                  defaultValue: 3000.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(bandpass: s.copyWith(f: v)),
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
                    (e) => e.copyWith(bandpass: s.copyWith(frequency: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<BandrejectSettings>(
          stream: _watch((e) => e.bandreject),
          initialData: player.state.audioEffects.bandreject,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'bandreject',
              subtitle: 'lavfi-bandreject',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(bandreject: s.copyWith(enabled: v)),
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
                    (e) => e.copyWith(bandreject: s.copyWith(f: v)),
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
                    (e) => e.copyWith(bandreject: s.copyWith(frequency: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<HighpassSettings>(
          stream: _watch((e) => e.highpass),
          initialData: player.state.audioEffects.highpass,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'highpass',
              subtitle: 'lavfi-highpass',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(highpass: s.copyWith(enabled: v)),
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
                    (e) => e.copyWith(highpass: s.copyWith(f: v)),
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
                    (e) => e.copyWith(highpass: s.copyWith(frequency: v)),
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
                    (e) => e.copyWith(highpass: s.copyWith(p: v.round())),
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
                    (e) => e.copyWith(highpass: s.copyWith(poles: v.round())),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<LowpassSettings>(
          stream: _watch((e) => e.lowpass),
          initialData: player.state.audioEffects.lowpass,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'lowpass',
              subtitle: 'lavfi-lowpass',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(lowpass: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'f',
                  value: s.f,
                  min: 0.0,
                  max: 999999.0,
                  defaultValue: 500.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(lowpass: s.copyWith(f: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'frequency',
                  value: s.frequency,
                  min: 0.0,
                  max: 999999.0,
                  defaultValue: 500.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(lowpass: s.copyWith(frequency: v)),
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
                    (e) => e.copyWith(lowpass: s.copyWith(p: v.round())),
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
                    (e) => e.copyWith(lowpass: s.copyWith(poles: v.round())),
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
