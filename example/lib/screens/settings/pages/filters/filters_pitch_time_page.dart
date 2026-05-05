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

/// Filters in the **Pitch, tempo & time** category. Each card maps to a typed
/// `*Settings` field on the [AudioEffects] bundle.
class FiltersPitchTimePage extends StatefulWidget {
  final Player player;
  const FiltersPitchTimePage({super.key, required this.player});

  @override
  State<FiltersPitchTimePage> createState() => _FiltersPitchTimePageState();
}

class _FiltersPitchTimePageState extends State<FiltersPitchTimePage> {
  Player get player => widget.player;

  Stream<T> _watch<T>(T Function(AudioEffects) sel) =>
      player.stream.audioEffects.map(sel).distinct();

  String _f(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StreamBuilder<AfreqshiftSettings>(
          stream: _watch((e) => e.afreqshift),
          initialData: player.state.audioEffects.afreqshift,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'afreqshift',
              subtitle: 'lavfi-afreqshift',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(afreqshift: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'level',
                  value: s.level,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afreqshift: s.copyWith(level: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AphaseshiftSettings>(
          stream: _watch((e) => e.aphaseshift),
          initialData: player.state.audioEffects.aphaseshift,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'aphaseshift',
              subtitle: 'lavfi-aphaseshift',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(aphaseshift: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'level',
                  value: s.level,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aphaseshift: s.copyWith(level: v)),
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
                    (e) => e.copyWith(aphaseshift: s.copyWith(shift: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AresampleSettings>(
          stream: _watch((e) => e.aresample),
          initialData: player.state.audioEffects.aresample,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'aresample',
              subtitle: 'lavfi-aresample',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(aresample: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<AtempoSettings>(
          stream: _watch((e) => e.atempo),
          initialData: player.state.audioEffects.atempo,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'atempo',
              subtitle: 'lavfi-atempo',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(atempo: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<RubberbandSettings>(
          stream: _watch((e) => e.rubberband),
          initialData: player.state.audioEffects.rubberband,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'rubberband',
              subtitle: 'lavfi-rubberband',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(rubberband: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'pitch',
                  value: s.pitch,
                  min: 0.01,
                  max: 100.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(rubberband: s.copyWith(pitch: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'tempo',
                  value: s.tempo,
                  min: 0.01,
                  max: 100.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(rubberband: s.copyWith(tempo: v)),
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
