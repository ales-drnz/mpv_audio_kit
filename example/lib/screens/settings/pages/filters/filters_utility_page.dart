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

/// Filters in the **Analysis, fade & utilities** category. Each card maps to a typed
/// `*Settings` field on the [AudioEffects] bundle.
class FiltersUtilityPage extends StatefulWidget {
  final Player player;
  const FiltersUtilityPage({super.key, required this.player});

  @override
  State<FiltersUtilityPage> createState() => _FiltersUtilityPageState();
}

class _FiltersUtilityPageState extends State<FiltersUtilityPage> {
  Player get player => widget.player;

  Stream<T> _watch<T>(T Function(AudioEffects) sel) =>
      player.stream.audioEffects.map(sel).distinct();

  String _f(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StreamBuilder<AfftfiltSettings>(
          stream: _watch((e) => e.afftfilt),
          initialData: player.state.audioEffects.afftfilt,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'afftfilt',
              subtitle: 'lavfi-afftfilt',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(afftfilt: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'overlap',
                  value: s.overlap,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 0.75,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afftfilt: s.copyWith(overlap: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'win_size',
                  value: s.win_size.toDouble(),
                  min: 16.0,
                  max: 131072.0,
                  defaultValue: 4096.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) =>
                        e.copyWith(afftfilt: s.copyWith(win_size: v.round())),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AiirSettings>(
          stream: _watch((e) => e.aiir),
          initialData: player.state.audioEffects.aiir,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'aiir',
              subtitle: 'lavfi-aiir',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(aiir: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'channel',
                  value: s.channel.toDouble(),
                  min: 0.0,
                  max: 1024.0,
                  defaultValue: 0.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aiir: s.copyWith(channel: v.round())),
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
                    (e) => e.copyWith(aiir: s.copyWith(dry: v)),
                  ),
                ),
                FilterParamDropdown<AiirPrecision>(
                  label: 'e',
                  value: s.e,
                  defaultValue: AiirPrecision.dbl,
                  options: const [
                    AiirPrecision.dbl,
                    AiirPrecision.flt,
                    AiirPrecision.i32,
                    AiirPrecision.i16,
                  ],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aiir: s.copyWith(e: v)),
                  ),
                ),
                FilterParamDropdown<AiirFormat>(
                  label: 'f',
                  value: s.f,
                  defaultValue: AiirFormat.zp,
                  options: const [
                    AiirFormat.ll,
                    AiirFormat.sf,
                    AiirFormat.tf,
                    AiirFormat.zp,
                    AiirFormat.pr,
                    AiirFormat.pd,
                    AiirFormat.sp,
                  ],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aiir: s.copyWith(f: v)),
                  ),
                ),
                FilterParamDropdown<AiirFormat>(
                  label: 'format',
                  value: s.format,
                  defaultValue: AiirFormat.zp,
                  options: const [
                    AiirFormat.ll,
                    AiirFormat.sf,
                    AiirFormat.tf,
                    AiirFormat.zp,
                    AiirFormat.pr,
                    AiirFormat.pd,
                    AiirFormat.sp,
                  ],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aiir: s.copyWith(format: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'mix',
                  value: s.mix,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aiir: s.copyWith(mix: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'n',
                  value: s.n,
                  defaultValue: true,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aiir: s.copyWith(n: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'normalize',
                  value: s.normalize,
                  defaultValue: true,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aiir: s.copyWith(normalize: v)),
                  ),
                ),
                FilterParamDropdown<AiirPrecision>(
                  label: 'precision',
                  value: s.precision,
                  defaultValue: AiirPrecision.dbl,
                  options: const [
                    AiirPrecision.dbl,
                    AiirPrecision.flt,
                    AiirPrecision.i32,
                    AiirPrecision.i16,
                  ],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aiir: s.copyWith(precision: v)),
                  ),
                ),
                FilterParamDropdown<AiirProcess>(
                  label: 'process',
                  value: s.process,
                  defaultValue: AiirProcess.s,
                  options: const [AiirProcess.d, AiirProcess.s, AiirProcess.p],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aiir: s.copyWith(process: v)),
                  ),
                ),
                FilterParamDropdown<AiirProcess>(
                  label: 'r',
                  value: s.r,
                  defaultValue: AiirProcess.s,
                  options: const [AiirProcess.d, AiirProcess.s, AiirProcess.p],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aiir: s.copyWith(r: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'response',
                  value: s.response,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aiir: s.copyWith(response: v)),
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
                    (e) => e.copyWith(aiir: s.copyWith(wet: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AmetadataSettings>(
          stream: _watch((e) => e.ametadata),
          initialData: player.state.audioEffects.ametadata,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'ametadata',
              subtitle: 'lavfi-ametadata',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(ametadata: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<AshowinfoSettings>(
          stream: _watch((e) => e.ashowinfo),
          initialData: player.state.audioEffects.ashowinfo,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'ashowinfo',
              subtitle: 'lavfi-ashowinfo',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(ashowinfo: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<AsidedataSettings>(
          stream: _watch((e) => e.asidedata),
          initialData: player.state.audioEffects.asidedata,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'asidedata',
              subtitle: 'lavfi-asidedata',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(asidedata: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<AspectralstatsSettings>(
          stream: _watch((e) => e.aspectralstats),
          initialData: player.state.audioEffects.aspectralstats,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'aspectralstats',
              subtitle: 'lavfi-aspectralstats',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(aspectralstats: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'overlap',
                  value: s.overlap,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 0.5,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(aspectralstats: s.copyWith(overlap: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'win_size',
                  value: s.win_size.toDouble(),
                  min: 32.0,
                  max: 65536.0,
                  defaultValue: 2048.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(
                      aspectralstats: s.copyWith(win_size: v.round()),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AstatsSettings>(
          stream: _watch((e) => e.astats),
          initialData: player.state.audioEffects.astats,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'astats',
              subtitle: 'lavfi-astats',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(astats: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'length',
                  value: s.length,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: .05,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(astats: s.copyWith(length: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'metadata',
                  value: s.metadata,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(astats: s.copyWith(metadata: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<SilencedetectSettings>(
          stream: _watch((e) => e.silencedetect),
          initialData: player.state.audioEffects.silencedetect,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'silencedetect',
              subtitle: 'lavfi-silencedetect',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(silencedetect: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSwitch(
                  label: 'm',
                  value: s.m,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(silencedetect: s.copyWith(m: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'mono',
                  value: s.mono,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(silencedetect: s.copyWith(mono: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AfadeSettings>(
          stream: _watch((e) => e.afade),
          initialData: player.state.audioEffects.afade,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'afade',
              subtitle: 'lavfi-afade',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(afade: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'silence',
                  value: s.silence,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afade: s.copyWith(silence: v)),
                  ),
                ),
                FilterParamDropdown<AfadeType>(
                  label: 't',
                  value: s.t,
                  defaultValue: AfadeType.in_,
                  options: const [AfadeType.in_, AfadeType.out],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afade: s.copyWith(t: v)),
                  ),
                ),
                FilterParamDropdown<AfadeType>(
                  label: 'type',
                  value: s.type,
                  defaultValue: AfadeType.in_,
                  options: const [AfadeType.in_, AfadeType.out],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afade: s.copyWith(type: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'unity',
                  value: s.unity,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afade: s.copyWith(unity: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<ApadSettings>(
          stream: _watch((e) => e.apad),
          initialData: player.state.audioEffects.apad,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'apad',
              subtitle: 'lavfi-apad',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(apad: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<SilenceremoveSettings>(
          stream: _watch((e) => e.silenceremove),
          initialData: player.state.audioEffects.silenceremove,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'silenceremove',
              subtitle: 'lavfi-silenceremove',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(silenceremove: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'start_periods',
                  value: s.start_periods.toDouble(),
                  min: 0.0,
                  max: 9000.0,
                  defaultValue: 0.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(
                      silenceremove: s.copyWith(start_periods: v.round()),
                    ),
                  ),
                ),
                FilterParamSlider(
                  label: 'stop_periods',
                  value: s.stop_periods.toDouble(),
                  min: -9000.0,
                  max: 9000.0,
                  defaultValue: 0.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(
                      silenceremove: s.copyWith(stop_periods: v.round()),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AbenchSettings>(
          stream: _watch((e) => e.abench),
          initialData: player.state.audioEffects.abench,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'abench',
              subtitle: 'lavfi-abench',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(abench: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<AcopySettings>(
          stream: _watch((e) => e.acopy),
          initialData: player.state.audioEffects.acopy,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'acopy',
              subtitle: 'lavfi-acopy',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(acopy: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<AcueSettings>(
          stream: _watch((e) => e.acue),
          initialData: player.state.audioEffects.acue,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'acue',
              subtitle: 'lavfi-acue',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(acue: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<AevalSettings>(
          stream: _watch((e) => e.aeval),
          initialData: player.state.audioEffects.aeval,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'aeval',
              subtitle: 'lavfi-aeval',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(aeval: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<AformatSettings>(
          stream: _watch((e) => e.aformat),
          initialData: player.state.audioEffects.aformat,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'aformat',
              subtitle: 'lavfi-aformat',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(aformat: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<AlatencySettings>(
          stream: _watch((e) => e.alatency),
          initialData: player.state.audioEffects.alatency,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'alatency',
              subtitle: 'lavfi-alatency',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(alatency: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<AloopSettings>(
          stream: _watch((e) => e.aloop),
          initialData: player.state.audioEffects.aloop,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'aloop',
              subtitle: 'lavfi-aloop',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(aloop: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<AnullSettings>(
          stream: _watch((e) => e.anull),
          initialData: player.state.audioEffects.anull,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'anull',
              subtitle: 'lavfi-anull',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(anull: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<ApermsSettings>(
          stream: _watch((e) => e.aperms),
          initialData: player.state.audioEffects.aperms,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'aperms',
              subtitle: 'lavfi-aperms',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(aperms: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<ArealtimeSettings>(
          stream: _watch((e) => e.arealtime),
          initialData: player.state.audioEffects.arealtime,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'arealtime',
              subtitle: 'lavfi-arealtime',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(arealtime: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<AselectSettings>(
          stream: _watch((e) => e.aselect),
          initialData: player.state.audioEffects.aselect,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'aselect',
              subtitle: 'lavfi-aselect',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(aselect: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<AsegmentSettings>(
          stream: _watch((e) => e.asegment),
          initialData: player.state.audioEffects.asegment,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'asegment',
              subtitle: 'lavfi-asegment',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(asegment: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<AsendcmdSettings>(
          stream: _watch((e) => e.asendcmd),
          initialData: player.state.audioEffects.asendcmd,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'asendcmd',
              subtitle: 'lavfi-asendcmd',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(asendcmd: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<AstreamselectSettings>(
          stream: _watch((e) => e.astreamselect),
          initialData: player.state.audioEffects.astreamselect,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'astreamselect',
              subtitle: 'lavfi-astreamselect',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(astreamselect: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
      ],
    );
  }
}
