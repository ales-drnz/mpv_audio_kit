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

/// Filters in the **Stereo, channels & spatial** category. Each card maps to a typed
/// `*Settings` field on the [AudioEffects] bundle.
class FiltersStereoPage extends StatefulWidget {
  final Player player;
  const FiltersStereoPage({super.key, required this.player});

  @override
  State<FiltersStereoPage> createState() => _FiltersStereoPageState();
}

class _FiltersStereoPageState extends State<FiltersStereoPage> {
  Player get player => widget.player;

  Stream<T> _watch<T>(T Function(AudioEffects) sel) =>
      player.stream.audioEffects.map(sel).distinct();

  String _f(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StreamBuilder<ChannelmapSettings>(
          stream: _watch((e) => e.channelmap),
          initialData: player.state.audioEffects.channelmap,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'channelmap',
              subtitle: 'lavfi-channelmap',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(channelmap: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<CrossfeedSettings>(
          stream: _watch((e) => e.crossfeed),
          initialData: player.state.audioEffects.crossfeed,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'crossfeed',
              subtitle: 'lavfi-crossfeed',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(crossfeed: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'block_size',
                  value: s.block_size.toDouble(),
                  min: 0.0,
                  max: 32768.0,
                  defaultValue: 0.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(
                      crossfeed: s.copyWith(block_size: v.round()),
                    ),
                  ),
                ),
                FilterParamSlider(
                  label: 'level_in',
                  value: s.level_in,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: .9,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(crossfeed: s.copyWith(level_in: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'level_out',
                  value: s.level_out,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(crossfeed: s.copyWith(level_out: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'range',
                  value: s.range,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: .5,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(crossfeed: s.copyWith(range: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'strength',
                  value: s.strength,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: .2,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(crossfeed: s.copyWith(strength: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<DialoguenhanceSettings>(
          stream: _watch((e) => e.dialoguenhance),
          initialData: player.state.audioEffects.dialoguenhance,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'dialoguenhance',
              subtitle: 'lavfi-dialoguenhance',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(dialoguenhance: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'enhance',
                  value: s.enhance,
                  min: 0.0,
                  max: 3.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(dialoguenhance: s.copyWith(enhance: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'original',
                  value: s.original,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(dialoguenhance: s.copyWith(original: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'voice',
                  value: s.voice,
                  min: 2.0,
                  max: 32.0,
                  defaultValue: 2.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(dialoguenhance: s.copyWith(voice: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<EarwaxSettings>(
          stream: _watch((e) => e.earwax),
          initialData: player.state.audioEffects.earwax,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'earwax',
              subtitle: 'lavfi-earwax',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(earwax: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<ExtrastereoSettings>(
          stream: _watch((e) => e.extrastereo),
          initialData: player.state.audioEffects.extrastereo,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'extrastereo',
              subtitle: 'lavfi-extrastereo',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(extrastereo: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSwitch(
                  label: 'c',
                  value: s.c,
                  defaultValue: true,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(extrastereo: s.copyWith(c: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'm',
                  value: s.m,
                  min: -10.0,
                  max: 10.0,
                  defaultValue: 2.5,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(extrastereo: s.copyWith(m: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<HaasSettings>(
          stream: _watch((e) => e.haas),
          initialData: player.state.audioEffects.haas,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'haas',
              subtitle: 'lavfi-haas',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(haas: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'left_balance',
                  value: s.left_balance,
                  min: -1.0,
                  max: 1.0,
                  defaultValue: -1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(haas: s.copyWith(left_balance: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'left_gain',
                  value: s.left_gain,
                  min: 0.015625,
                  max: 64.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(haas: s.copyWith(left_gain: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'left_phase',
                  value: s.left_phase,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(haas: s.copyWith(left_phase: v)),
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
                    (e) => e.copyWith(haas: s.copyWith(level_in: v)),
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
                    (e) => e.copyWith(haas: s.copyWith(level_out: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'middle_phase',
                  value: s.middle_phase,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(haas: s.copyWith(middle_phase: v)),
                  ),
                ),
                FilterParamDropdown<HaasSource>(
                  label: 'middle_source',
                  value: s.middle_source,
                  defaultValue: HaasSource.mid,
                  options: const [
                    HaasSource.left,
                    HaasSource.right,
                    HaasSource.mid,
                    HaasSource.side,
                  ],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(haas: s.copyWith(middle_source: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'right_balance',
                  value: s.right_balance,
                  min: -1.0,
                  max: 1.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(haas: s.copyWith(right_balance: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'right_gain',
                  value: s.right_gain,
                  min: 0.015625,
                  max: 64.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(haas: s.copyWith(right_gain: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'right_phase',
                  value: s.right_phase,
                  defaultValue: true,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(haas: s.copyWith(right_phase: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'side_gain',
                  value: s.side_gain,
                  min: 0.015625,
                  max: 64.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(haas: s.copyWith(side_gain: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<HeadphoneSettings>(
          stream: _watch((e) => e.headphone),
          initialData: player.state.audioEffects.headphone,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'headphone',
              subtitle: 'lavfi-headphone',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(headphone: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'gain',
                  value: s.gain,
                  min: -20.0,
                  max: 40.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(headphone: s.copyWith(gain: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'lfe',
                  value: s.lfe,
                  min: -20.0,
                  max: 40.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(headphone: s.copyWith(lfe: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'size',
                  value: s.size.toDouble(),
                  min: 1024.0,
                  max: 96000.0,
                  defaultValue: 1024.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(headphone: s.copyWith(size: v.round())),
                  ),
                ),
                FilterParamDropdown<HeadphoneType>(
                  label: 'type',
                  value: s.type,
                  defaultValue: HeadphoneType.freq,
                  options: const [HeadphoneType.time, HeadphoneType.freq],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(headphone: s.copyWith(type: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<PanSettings>(
          stream: _watch((e) => e.pan),
          initialData: player.state.audioEffects.pan,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'pan',
              subtitle: 'lavfi-pan',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(pan: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<StereotoolsSettings>(
          stream: _watch((e) => e.stereotools),
          initialData: player.state.audioEffects.stereotools,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'stereotools',
              subtitle: 'lavfi-stereotools',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(stereotools: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'balance_in',
                  value: s.balance_in,
                  min: -1.0,
                  max: 1.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereotools: s.copyWith(balance_in: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'balance_out',
                  value: s.balance_out,
                  min: -1.0,
                  max: 1.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereotools: s.copyWith(balance_out: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'base',
                  value: s.base,
                  min: -1.0,
                  max: 1.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereotools: s.copyWith(base: v)),
                  ),
                ),
                FilterParamDropdown<StereotoolsBmode>(
                  label: 'bmode_in',
                  value: s.bmode_in,
                  defaultValue: StereotoolsBmode.balance,
                  options: const [
                    StereotoolsBmode.balance,
                    StereotoolsBmode.amplitude,
                    StereotoolsBmode.power,
                  ],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereotools: s.copyWith(bmode_in: v)),
                  ),
                ),
                FilterParamDropdown<StereotoolsBmode>(
                  label: 'bmode_out',
                  value: s.bmode_out,
                  defaultValue: StereotoolsBmode.balance,
                  options: const [
                    StereotoolsBmode.balance,
                    StereotoolsBmode.amplitude,
                    StereotoolsBmode.power,
                  ],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereotools: s.copyWith(bmode_out: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'delay',
                  value: s.delay,
                  min: -20.0,
                  max: 20.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereotools: s.copyWith(delay: v)),
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
                    (e) => e.copyWith(stereotools: s.copyWith(level_in: v)),
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
                    (e) => e.copyWith(stereotools: s.copyWith(level_out: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'mlev',
                  value: s.mlev,
                  min: 0.015625,
                  max: 64.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereotools: s.copyWith(mlev: v)),
                  ),
                ),
                FilterParamDropdown<StereotoolsMode>(
                  label: 'mode',
                  value: s.mode,
                  defaultValue: StereotoolsMode.lr_to_lr,
                  options: const [
                    StereotoolsMode.lr_to_lr,
                    StereotoolsMode.lr_to_ms,
                    StereotoolsMode.ms_to_lr,
                    StereotoolsMode.lr_to_ll,
                    StereotoolsMode.lr_to_rr,
                    StereotoolsMode.lr_to_l_plus_r,
                    StereotoolsMode.lr_to_rl,
                    StereotoolsMode.ms_to_ll,
                    StereotoolsMode.ms_to_rr,
                    StereotoolsMode.ms_to_rl,
                    StereotoolsMode.lr_to_l_minus_r,
                  ],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereotools: s.copyWith(mode: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'mpan',
                  value: s.mpan,
                  min: -1.0,
                  max: 1.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereotools: s.copyWith(mpan: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'mutel',
                  value: s.mutel,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereotools: s.copyWith(mutel: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'muter',
                  value: s.muter,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereotools: s.copyWith(muter: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'phase',
                  value: s.phase,
                  min: 0.0,
                  max: 360.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereotools: s.copyWith(phase: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'phasel',
                  value: s.phasel,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereotools: s.copyWith(phasel: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'phaser',
                  value: s.phaser,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereotools: s.copyWith(phaser: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'sbal',
                  value: s.sbal,
                  min: -1.0,
                  max: 1.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereotools: s.copyWith(sbal: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'sclevel',
                  value: s.sclevel,
                  min: 1.0,
                  max: 100.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereotools: s.copyWith(sclevel: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'slev',
                  value: s.slev,
                  min: 0.015625,
                  max: 64.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereotools: s.copyWith(slev: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'softclip',
                  value: s.softclip,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereotools: s.copyWith(softclip: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<StereowidenSettings>(
          stream: _watch((e) => e.stereowiden),
          initialData: player.state.audioEffects.stereowiden,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'stereowiden',
              subtitle: 'lavfi-stereowiden',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(stereowiden: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'crossfeed',
                  value: s.crossfeed,
                  min: 0.0,
                  max: 0.8,
                  defaultValue: .3,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereowiden: s.copyWith(crossfeed: v)),
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
                    (e) => e.copyWith(stereowiden: s.copyWith(delay: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'drymix',
                  value: s.drymix,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: .8,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereowiden: s.copyWith(drymix: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'feedback',
                  value: s.feedback,
                  min: 0.0,
                  max: 0.9,
                  defaultValue: .3,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(stereowiden: s.copyWith(feedback: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<SurroundSettings>(
          stream: _watch((e) => e.surround),
          initialData: player.state.audioEffects.surround,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'surround',
              subtitle: 'lavfi-surround',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(surround: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'allx',
                  value: s.allx,
                  min: -1.0,
                  max: 15.0,
                  defaultValue: -1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(allx: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'ally',
                  value: s.ally,
                  min: -1.0,
                  max: 15.0,
                  defaultValue: -1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(ally: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'angle',
                  value: s.angle,
                  min: 0.0,
                  max: 360.0,
                  defaultValue: 90.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(angle: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'bc_in',
                  value: s.bc_in,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(bc_in: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'bc_out',
                  value: s.bc_out,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(bc_out: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'bl_in',
                  value: s.bl_in,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(bl_in: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'bl_out',
                  value: s.bl_out,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(bl_out: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'br_in',
                  value: s.br_in,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(br_in: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'br_out',
                  value: s.br_out,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(br_out: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'fc_in',
                  value: s.fc_in,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(fc_in: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'fc_out',
                  value: s.fc_out,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(fc_out: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'fl_in',
                  value: s.fl_in,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(fl_in: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'fl_out',
                  value: s.fl_out,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(fl_out: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'focus',
                  value: s.focus,
                  min: -1.0,
                  max: 1.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(focus: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'fr_in',
                  value: s.fr_in,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(fr_in: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'fr_out',
                  value: s.fr_out,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(fr_out: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'level_in',
                  value: s.level_in,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(level_in: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'level_out',
                  value: s.level_out,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(level_out: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'lfe',
                  value: s.lfe,
                  defaultValue: true,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(lfe: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'lfe_high',
                  value: s.lfe_high.toDouble(),
                  min: 0.0,
                  max: 512.0,
                  defaultValue: 256.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) =>
                        e.copyWith(surround: s.copyWith(lfe_high: v.round())),
                  ),
                ),
                FilterParamSlider(
                  label: 'lfe_in',
                  value: s.lfe_in,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(lfe_in: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'lfe_low',
                  value: s.lfe_low.toDouble(),
                  min: 0.0,
                  max: 256.0,
                  defaultValue: 128.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(lfe_low: v.round())),
                  ),
                ),
                FilterParamDropdown<SurroundLfeMode>(
                  label: 'lfe_mode',
                  value: s.lfe_mode,
                  defaultValue: SurroundLfeMode.add,
                  options: const [SurroundLfeMode.add, SurroundLfeMode.sub],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(lfe_mode: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'lfe_out',
                  value: s.lfe_out,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(lfe_out: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'overlap',
                  value: s.overlap,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 0.5,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(overlap: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'sl_in',
                  value: s.sl_in,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(sl_in: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'sl_out',
                  value: s.sl_out,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(sl_out: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'smooth',
                  value: s.smooth,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(smooth: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'sr_in',
                  value: s.sr_in,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(sr_in: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'sr_out',
                  value: s.sr_out,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(surround: s.copyWith(sr_out: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'win_size',
                  value: s.win_size.toDouble(),
                  min: 1024.0,
                  max: 65536.0,
                  defaultValue: 4096.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) =>
                        e.copyWith(surround: s.copyWith(win_size: v.round())),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<VirtualbassSettings>(
          stream: _watch((e) => e.virtualbass),
          initialData: player.state.audioEffects.virtualbass,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'virtualbass',
              subtitle: 'lavfi-virtualbass',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(virtualbass: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'cutoff',
                  value: s.cutoff,
                  min: 100.0,
                  max: 500.0,
                  defaultValue: 250.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(virtualbass: s.copyWith(cutoff: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'strength',
                  value: s.strength,
                  min: 0.5,
                  max: 3.0,
                  defaultValue: 3.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(virtualbass: s.copyWith(strength: v)),
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
