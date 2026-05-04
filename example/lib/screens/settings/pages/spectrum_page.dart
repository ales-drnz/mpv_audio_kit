import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../../shared/property_cards.dart';

/// Live playground for [SpectrumSettings]. Every control mutates the
/// pipeline immediately via [Player.updateSpectrum]; the visualizer in
/// the player tab reflects the new values within a single emit
/// interval.
class SpectrumPage extends StatefulWidget {
  final Player player;
  const SpectrumPage({super.key, required this.player});

  @override
  State<SpectrumPage> createState() => _SpectrumPageState();
}

class _SpectrumPageState extends State<SpectrumPage> {
  // Local cache so sliders react instantly without waiting for the
  // [Player.spectrumSettings] re-read round-trip.
  late SpectrumSettings _cfg = widget.player.spectrumSettings;

  Future<void> _apply(SpectrumSettings next) async {
    setState(() => _cfg = next);
    await widget.player.setSpectrum(next);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'FFT'),
        DropdownPropertyCard<int>(
          title: 'FFT Size',
          subtitle: 'fftSize=${_cfg.fftSize} samples',
          icon: Icons.grain_rounded,
          value: _cfg.fftSize,
          items: const [
            DropdownMenuItem(value: 256, child: Text('256')),
            DropdownMenuItem(value: 512, child: Text('512')),
            DropdownMenuItem(value: 1024, child: Text('1024')),
            DropdownMenuItem(value: 2048, child: Text('2048 (default)')),
            DropdownMenuItem(value: 4096, child: Text('4096')),
          ],
          onChanged: (v) {
            if (v != null) _apply(_cfg.copyWith(fftSize: v));
          },
        ),
        DropdownPropertyCard<WindowFunction>(
          title: 'Window',
          subtitle: 'window=${_cfg.window.name}',
          icon: Icons.waves_rounded,
          value: _cfg.window,
          items: const [
            DropdownMenuItem(
                value: WindowFunction.hann, child: Text('Hann (default)')),
            DropdownMenuItem(
                value: WindowFunction.blackmanHarris,
                child: Text('Blackman-Harris')),
            DropdownMenuItem(
                value: WindowFunction.rectangular, child: Text('Rectangular')),
          ],
          onChanged: (w) {
            if (w != null) _apply(_cfg.copyWith(window: w));
          },
        ),
        const PropertySectionHeader(title: 'Bands'),
        SliderPropertyCard(
          title: 'Band Count',
          subtitle: 'bandCount=${_cfg.bandCount}',
          icon: Icons.bar_chart_rounded,
          value: _cfg.bandCount.toDouble(),
          min: 16,
          max: 128,
          divisions: 14,
          defaultValue: 64,
          labelBuilder: (v) => v.toInt().toString(),
          onChanged: (v) => _apply(_cfg.copyWith(bandCount: v.round())),
        ),
        SliderPropertyCard(
          title: 'Low Hz',
          subtitle: 'bandLowHz=${_cfg.bandLowHz.toStringAsFixed(0)} Hz',
          icon: Icons.south_rounded,
          value: _cfg.bandLowHz,
          min: 10,
          max: 200,
          defaultValue: 20,
          labelBuilder: (v) => '${v.toStringAsFixed(0)} Hz',
          onChanged: (v) => _apply(_cfg.copyWith(bandLowHz: v)),
        ),
        SliderPropertyCard(
          title: 'High Hz',
          subtitle: 'bandHighHz=${_cfg.bandHighHz.toStringAsFixed(0)} Hz',
          icon: Icons.north_rounded,
          value: _cfg.bandHighHz,
          min: 4000,
          max: 24000,
          defaultValue: 20000,
          labelBuilder: (v) => '${(v / 1000).toStringAsFixed(1)} kHz',
          onChanged: (v) => _apply(_cfg.copyWith(bandHighHz: v)),
        ),
        const PropertySectionHeader(title: 'Timing'),
        SliderPropertyCard(
          title: 'Emit Rate',
          subtitle:
              'emitInterval=${_cfg.emitInterval.inMilliseconds}ms (~${(1000 / _cfg.emitInterval.inMilliseconds).toStringAsFixed(0)} fps)',
          icon: Icons.update_rounded,
          value: _cfg.emitInterval.inMilliseconds.toDouble(),
          min: 8,
          max: 67,
          defaultValue: 33,
          labelBuilder: (v) =>
              '${v.toInt()}ms / ${(1000 / v).toStringAsFixed(0)}fps',
          onChanged: (v) => _apply(_cfg.copyWith(
              emitInterval: Duration(milliseconds: v.round()))),
        ),
        const PropertySectionHeader(title: 'Smoothing'),
        SliderPropertyCard(
          title: 'Attack',
          subtitle: 'attackSmoothing=${_cfg.attackSmoothing.toStringAsFixed(2)}',
          icon: Icons.flash_on_rounded,
          value: _cfg.attackSmoothing,
          min: 0.1,
          max: 1.0,
          defaultValue: 0.5,
          labelBuilder: (v) => v.toStringAsFixed(2),
          onChanged: (v) => _apply(_cfg.copyWith(attackSmoothing: v)),
        ),
        SliderPropertyCard(
          title: 'Release',
          subtitle:
              'releaseSmoothing=${_cfg.releaseSmoothing.toStringAsFixed(2)}',
          icon: Icons.air_rounded,
          value: _cfg.releaseSmoothing,
          min: 0.01,
          max: 0.5,
          defaultValue: 0.1,
          labelBuilder: (v) => v.toStringAsFixed(2),
          onChanged: (v) => _apply(_cfg.copyWith(releaseSmoothing: v)),
        ),
        const PropertySectionHeader(title: 'dB Range'),
        SliderPropertyCard(
          title: 'Min dB',
          subtitle: 'minDb=${_cfg.minDb.toStringAsFixed(0)} dB',
          icon: Icons.volume_mute_rounded,
          value: _cfg.minDb,
          min: -90,
          max: -30,
          defaultValue: -70,
          labelBuilder: (v) => '${v.toStringAsFixed(0)} dB',
          onChanged: (v) => _apply(_cfg.copyWith(minDb: v)),
        ),
        SliderPropertyCard(
          title: 'Max dB',
          subtitle: 'maxDb=${_cfg.maxDb.toStringAsFixed(0)} dB',
          icon: Icons.volume_up_rounded,
          value: _cfg.maxDb,
          min: -30,
          max: 0,
          defaultValue: -10,
          labelBuilder: (v) => '${v.toStringAsFixed(0)} dB',
          onChanged: (v) => _apply(_cfg.copyWith(maxDb: v)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
