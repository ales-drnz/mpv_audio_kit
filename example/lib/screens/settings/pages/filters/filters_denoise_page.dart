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

/// Filters in the **Denoise & restoration** category. Each card maps to a typed
/// `*Settings` field on the [AudioEffects] bundle.
class FiltersDenoisePage extends StatefulWidget {
  final Player player;
  const FiltersDenoisePage({super.key, required this.player});

  @override
  State<FiltersDenoisePage> createState() => _FiltersDenoisePageState();
}

class _FiltersDenoisePageState extends State<FiltersDenoisePage> {
  Player get player => widget.player;

  Stream<T> _watch<T>(T Function(AudioEffects) sel) =>
      player.stream.audioEffects.map(sel).distinct();

  String _f(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StreamBuilder<AdeclickSettings>(
          stream: _watch((e) => e.adeclick),
          initialData: player.state.audioEffects.adeclick,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'adeclick',
              subtitle: 'lavfi-adeclick',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(adeclick: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'a',
                  value: s.a,
                  min: 0.0,
                  max: 25.0,
                  defaultValue: 2.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclick: s.copyWith(a: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'arorder',
                  value: s.arorder,
                  min: 0.0,
                  max: 25.0,
                  defaultValue: 2.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclick: s.copyWith(arorder: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'b',
                  value: s.b,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 2.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclick: s.copyWith(b: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'burst',
                  value: s.burst,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 2.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclick: s.copyWith(burst: v)),
                  ),
                ),
                FilterParamDropdown<AdeclickM>(
                  label: 'm',
                  value: s.m,
                  defaultValue: AdeclickM.add,
                  options: const [
                    AdeclickM.add,
                    AdeclickM.a,
                    AdeclickM.save,
                    AdeclickM.s,
                  ],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclick: s.copyWith(m: v)),
                  ),
                ),
                FilterParamDropdown<AdeclickM>(
                  label: 'method',
                  value: s.method,
                  defaultValue: AdeclickM.add,
                  options: const [
                    AdeclickM.add,
                    AdeclickM.a,
                    AdeclickM.save,
                    AdeclickM.s,
                  ],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclick: s.copyWith(method: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'o',
                  value: s.o,
                  min: 50.0,
                  max: 95.0,
                  defaultValue: 75.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclick: s.copyWith(o: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'overlap',
                  value: s.overlap,
                  min: 50.0,
                  max: 95.0,
                  defaultValue: 75.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclick: s.copyWith(overlap: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 't',
                  value: s.t,
                  min: 1.0,
                  max: 100.0,
                  defaultValue: 2.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclick: s.copyWith(t: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'threshold',
                  value: s.threshold,
                  min: 1.0,
                  max: 100.0,
                  defaultValue: 2.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclick: s.copyWith(threshold: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'w',
                  value: s.w,
                  min: 10.0,
                  max: 100.0,
                  defaultValue: 55.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclick: s.copyWith(w: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'window',
                  value: s.window,
                  min: 10.0,
                  max: 100.0,
                  defaultValue: 55.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclick: s.copyWith(window: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AdeclipSettings>(
          stream: _watch((e) => e.adeclip),
          initialData: player.state.audioEffects.adeclip,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'adeclip',
              subtitle: 'lavfi-adeclip',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(adeclip: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'a',
                  value: s.a,
                  min: 0.0,
                  max: 25.0,
                  defaultValue: 8.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclip: s.copyWith(a: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'arorder',
                  value: s.arorder,
                  min: 0.0,
                  max: 25.0,
                  defaultValue: 8.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclip: s.copyWith(arorder: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'hsize',
                  value: s.hsize.toDouble(),
                  min: 100.0,
                  max: 9999.0,
                  defaultValue: 1000.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclip: s.copyWith(hsize: v.round())),
                  ),
                ),
                FilterParamDropdown<AdeclipM>(
                  label: 'm',
                  value: s.m,
                  defaultValue: AdeclipM.add,
                  options: const [
                    AdeclipM.add,
                    AdeclipM.a,
                    AdeclipM.save,
                    AdeclipM.s,
                  ],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclip: s.copyWith(m: v)),
                  ),
                ),
                FilterParamDropdown<AdeclipM>(
                  label: 'method',
                  value: s.method,
                  defaultValue: AdeclipM.add,
                  options: const [
                    AdeclipM.add,
                    AdeclipM.a,
                    AdeclipM.save,
                    AdeclipM.s,
                  ],
                  optionLabel: (o) => o.mpvValue,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclip: s.copyWith(method: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'n',
                  value: s.n.toDouble(),
                  min: 100.0,
                  max: 9999.0,
                  defaultValue: 1000.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclip: s.copyWith(n: v.round())),
                  ),
                ),
                FilterParamSlider(
                  label: 'o',
                  value: s.o,
                  min: 50.0,
                  max: 95.0,
                  defaultValue: 75.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclip: s.copyWith(o: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'overlap',
                  value: s.overlap,
                  min: 50.0,
                  max: 95.0,
                  defaultValue: 75.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclip: s.copyWith(overlap: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 't',
                  value: s.t,
                  min: 1.0,
                  max: 100.0,
                  defaultValue: 10.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclip: s.copyWith(t: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'threshold',
                  value: s.threshold,
                  min: 1.0,
                  max: 100.0,
                  defaultValue: 10.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclip: s.copyWith(threshold: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'w',
                  value: s.w,
                  min: 10.0,
                  max: 100.0,
                  defaultValue: 55.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclip: s.copyWith(w: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'window',
                  value: s.window,
                  min: 10.0,
                  max: 100.0,
                  defaultValue: 55.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adeclip: s.copyWith(window: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AdecorrelateSettings>(
          stream: _watch((e) => e.adecorrelate),
          initialData: player.state.audioEffects.adecorrelate,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'adecorrelate',
              subtitle: 'lavfi-adecorrelate',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(adecorrelate: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<AdelaySettings>(
          stream: _watch((e) => e.adelay),
          initialData: player.state.audioEffects.adelay,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'adelay',
              subtitle: 'lavfi-adelay',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(adelay: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSwitch(
                  label: 'all',
                  value: s.all,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adelay: s.copyWith(all: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AdenormSettings>(
          stream: _watch((e) => e.adenorm),
          initialData: player.state.audioEffects.adenorm,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'adenorm',
              subtitle: 'lavfi-adenorm',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(adenorm: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'level',
                  value: s.level,
                  min: -451.0,
                  max: -90.0,
                  defaultValue: -351.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(adenorm: s.copyWith(level: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AderivativeSettings>(
          stream: _watch((e) => e.aderivative),
          initialData: player.state.audioEffects.aderivative,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'aderivative',
              subtitle: 'lavfi-aderivative',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(aderivative: s.copyWith(enabled: v)),
              ),
              params: [],
            );
          },
        ),
        StreamBuilder<AfftdnSettings>(
          stream: _watch((e) => e.afftdn),
          initialData: player.state.audioEffects.afftdn,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'afftdn',
              subtitle: 'lavfi-afftdn',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(afftdn: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'ad',
                  value: s.ad,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 0.5,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afftdn: s.copyWith(ad: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'adaptivity',
                  value: s.adaptivity,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 0.5,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afftdn: s.copyWith(adaptivity: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'band_multiplier',
                  value: s.band_multiplier,
                  min: 0.2,
                  max: 5.0,
                  defaultValue: 1.25,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afftdn: s.copyWith(band_multiplier: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'bm',
                  value: s.bm,
                  min: 0.2,
                  max: 5.0,
                  defaultValue: 1.25,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afftdn: s.copyWith(bm: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'floor_offset',
                  value: s.floor_offset,
                  min: -2.0,
                  max: 2.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afftdn: s.copyWith(floor_offset: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'fo',
                  value: s.fo,
                  min: -2.0,
                  max: 2.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afftdn: s.copyWith(fo: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'gain_smooth',
                  value: s.gain_smooth.toDouble(),
                  min: 0.0,
                  max: 50.0,
                  defaultValue: 0.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) =>
                        e.copyWith(afftdn: s.copyWith(gain_smooth: v.round())),
                  ),
                ),
                FilterParamSlider(
                  label: 'gs',
                  value: s.gs.toDouble(),
                  min: 0.0,
                  max: 50.0,
                  defaultValue: 0.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afftdn: s.copyWith(gs: v.round())),
                  ),
                ),
                FilterParamSlider(
                  label: 'nf',
                  value: s.nf,
                  min: -80.0,
                  max: -20.0,
                  defaultValue: -50.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afftdn: s.copyWith(nf: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'noise_floor',
                  value: s.noise_floor,
                  min: -80.0,
                  max: -20.0,
                  defaultValue: -50.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afftdn: s.copyWith(noise_floor: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'residual_floor',
                  value: s.residual_floor,
                  min: -80.0,
                  max: -20.0,
                  defaultValue: -38.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afftdn: s.copyWith(residual_floor: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'rf',
                  value: s.rf,
                  min: -80.0,
                  max: -20.0,
                  defaultValue: -38.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afftdn: s.copyWith(rf: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'tn',
                  value: s.tn,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afftdn: s.copyWith(tn: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'tr',
                  value: s.tr,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afftdn: s.copyWith(tr: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'track_noise',
                  value: s.track_noise,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afftdn: s.copyWith(track_noise: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'track_residual',
                  value: s.track_residual,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afftdn: s.copyWith(track_residual: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AfwtdnSettings>(
          stream: _watch((e) => e.afwtdn),
          initialData: player.state.audioEffects.afwtdn,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'afwtdn',
              subtitle: 'lavfi-afwtdn',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(afwtdn: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSwitch(
                  label: 'adaptive',
                  value: s.adaptive,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afwtdn: s.copyWith(adaptive: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'percent',
                  value: s.percent,
                  min: 0.0,
                  max: 100.0,
                  defaultValue: 85.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afwtdn: s.copyWith(percent: v)),
                  ),
                ),
                FilterParamSwitch(
                  label: 'profile',
                  value: s.profile,
                  defaultValue: false,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afwtdn: s.copyWith(profile: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'samples',
                  value: s.samples.toDouble(),
                  min: 512.0,
                  max: 65536.0,
                  defaultValue: 8192.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afwtdn: s.copyWith(samples: v.round())),
                  ),
                ),
                FilterParamSlider(
                  label: 'sigma',
                  value: s.sigma,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afwtdn: s.copyWith(sigma: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'softness',
                  value: s.softness,
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(afwtdn: s.copyWith(softness: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<AnlmdnSettings>(
          stream: _watch((e) => e.anlmdn),
          initialData: player.state.audioEffects.anlmdn,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'anlmdn',
              subtitle: 'lavfi-anlmdn',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(anlmdn: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'm',
                  value: s.m,
                  min: 1.0,
                  max: 1000.0,
                  defaultValue: 11.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(anlmdn: s.copyWith(m: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 's',
                  value: s.s,
                  min: 0.00001,
                  max: 10000.0,
                  defaultValue: 0.00001,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(anlmdn: s.copyWith(s: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'smooth',
                  value: s.smooth,
                  min: 1.0,
                  max: 1000.0,
                  defaultValue: 11.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(anlmdn: s.copyWith(smooth: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'strength',
                  value: s.strength,
                  min: 0.00001,
                  max: 10000.0,
                  defaultValue: 0.00001,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(anlmdn: s.copyWith(strength: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<ArnndnSettings>(
          stream: _watch((e) => e.arnndn),
          initialData: player.state.audioEffects.arnndn,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'arnndn',
              subtitle: 'lavfi-arnndn',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(arnndn: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'mix',
                  value: s.mix,
                  min: -1.0,
                  max: 1.0,
                  defaultValue: 1.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(arnndn: s.copyWith(mix: v)),
                  ),
                ),
              ],
            );
          },
        ),
        StreamBuilder<CompensationdelaySettings>(
          stream: _watch((e) => e.compensationdelay),
          initialData: player.state.audioEffects.compensationdelay,
          builder: (context, snap) {
            final s = snap.data!;
            return ExpandableFilterCard(
              title: 'compensationdelay',
              subtitle: 'lavfi-compensationdelay',
              icon: Icons.tune,
              enabled: s.enabled,
              onToggle: (v) => player.updateAudioEffects(
                (e) => e.copyWith(compensationdelay: s.copyWith(enabled: v)),
              ),
              params: [
                FilterParamSlider(
                  label: 'cm',
                  value: s.cm.toDouble(),
                  min: 0.0,
                  max: 100.0,
                  defaultValue: 0.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(
                      compensationdelay: s.copyWith(cm: v.round()),
                    ),
                  ),
                ),
                FilterParamSlider(
                  label: 'dry',
                  value: s.dry,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 0.0,
                  labelBuilder: _f,
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(compensationdelay: s.copyWith(dry: v)),
                  ),
                ),
                FilterParamSlider(
                  label: 'm',
                  value: s.m.toDouble(),
                  min: 0.0,
                  max: 100.0,
                  defaultValue: 0.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) =>
                        e.copyWith(compensationdelay: s.copyWith(m: v.round())),
                  ),
                ),
                FilterParamSlider(
                  label: 'mm',
                  value: s.mm.toDouble(),
                  min: 0.0,
                  max: 10.0,
                  defaultValue: 0.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(
                      compensationdelay: s.copyWith(mm: v.round()),
                    ),
                  ),
                ),
                FilterParamSlider(
                  label: 'temp',
                  value: s.temp.toDouble(),
                  min: -50.0,
                  max: 50.0,
                  defaultValue: 20.toDouble(),
                  labelBuilder: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => player.updateAudioEffects(
                    (e) => e.copyWith(
                      compensationdelay: s.copyWith(temp: v.round()),
                    ),
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
                    (e) => e.copyWith(compensationdelay: s.copyWith(wet: v)),
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
