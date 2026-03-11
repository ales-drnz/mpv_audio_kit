import 'package:flutter/material.dart';
import 'package:mpv_audio_pro_kit/mpv_audio_pro_kit.dart';
import '../../widgets/ui_helpers.dart';
import '../../widgets/eq_widget.dart';

class DspTab extends StatefulWidget {
  final Player player;
  const DspTab({super.key, required this.player});

  @override
  State<DspTab> createState() => _DspTabState();
}

class _DspTabState extends State<DspTab> {
  final List<double> _eqGains = List.filled(10, 0.0);
  bool _eqEnabled = false;
  bool _compressorEnabled = false;
  bool _loudnormEnabled = false;
  bool _normalizeDownmix = false;
  bool _hardwareDownmix = false;

  bool _extraStereoEnabled = false;
  bool _crystalizerEnabled = false;
  bool _echoEnabled = false;

  void _applyFilters() {
    final filters = <AudioFilter>[];
    if (_eqEnabled) filters.add(AudioFilter.equalizer(_eqGains));
    if (_compressorEnabled) filters.add(AudioFilter.compressor());
    if (_loudnormEnabled) filters.add(AudioFilter.loudnorm());

    if (_extraStereoEnabled) filters.add(AudioFilter.extraStereo());
    if (_crystalizerEnabled) filters.add(AudioFilter.crystalizer());
    if (_echoEnabled) filters.add(AudioFilter.echo());
    widget.player.setAudioFilters(filters);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildSectionCard(context, 'DSP & Filters (lavfi)', [
          Wrap(
            spacing: 16,
            children: [
              buildToggle('Normalize Downmix (lavfi)', _normalizeDownmix, (v) {
                setState(() => _normalizeDownmix = v);
                widget.player.setRawProperty('audio-normalize-downmix', v ? 'yes' : 'no');
              }),
              buildToggle('Decoder Downmix (hw)', _hardwareDownmix, (v) {
                setState(() => _hardwareDownmix = v);
                widget.player.setRawProperty('ad-lavc-downmix', v ? 'yes' : 'no');
              }),
              buildToggle('Compressor', _compressorEnabled, (v) {
                setState(() => _compressorEnabled = v);
                _applyFilters();
              }),
              buildToggle('Loudnorm', _loudnormEnabled, (v) {
                setState(() => _loudnormEnabled = v);
                _applyFilters();
              }),

              buildToggle('Extra Stereo', _extraStereoEnabled, (v) {
                setState(() => _extraStereoEnabled = v);
                _applyFilters();
              }),
              buildToggle('Crystalizer', _crystalizerEnabled, (v) {
                setState(() => _crystalizerEnabled = v);
                _applyFilters();
              }),
              buildToggle('Echo', _echoEnabled, (v) {
                setState(() => _echoEnabled = v);
                _applyFilters();
              }),
            ],
          ),
        ]),
        const SizedBox(height: 16),
        buildSectionCard(context, '10-Band Equalizer', [
          Row(
            children: [
              const Text(
                'Enable EQ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Switch(
                value: _eqEnabled,
                onChanged: (v) {
                  setState(() => _eqEnabled = v);
                  _applyFilters();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          EQWidget(
            gains: _eqGains,
            enabled: _eqEnabled,
            onChanged: (i, v) {
              setState(() => _eqGains[i] = v);
              _applyFilters();
            },
          ),
        ]),
      ],
    );
  }
}
