import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/shared/property_cards.dart';
import '../../widgets/eq_widget.dart';

class AudioEngineTab extends StatefulWidget {
  final Player player;
  const AudioEngineTab({super.key, required this.player});

  @override
  State<AudioEngineTab> createState() => _AudioEngineTabState();
}

class _AudioEngineTabState extends State<AudioEngineTab> {
  // Clipping Monitor
  StreamSubscription<String>? _logSub;
  bool _clippingDetected = false;
  Timer? _clippingTimer;

  @override
  void initState() {
    super.initState();
    _logSub = widget.player.stream.log.listen((line) {
      if (line.contains('clipping')) {
        if (mounted) {
          setState(() => _clippingDetected = true);
          _clippingTimer?.cancel();
          _clippingTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) setState(() => _clippingDetected = false);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _logSub?.cancel();
    _clippingTimer?.cancel();
    super.dispose();
  }

  bool _isFilterActive(List<AudioFilter> filters, String name) {
    return filters.any((f) => f.value.contains(name));
  }

  void _toggleFilter(String name, bool enable, {AudioFilter? specificFilter}) {
    final currentFilters = List<AudioFilter>.from(widget.player.state.activeFilters);
    if (enable) {
      if (!_isFilterActive(currentFilters, name)) {
        currentFilters.add(specificFilter ?? AudioFilter.custom(name));
      }
    } else {
      currentFilters.removeWhere((f) => f.value.contains(name));
    }
    widget.player.setAudioFilters(currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AudioFilter>>(
      stream: widget.player.stream.activeFilters,
      initialData: widget.player.state.activeFilters,
      builder: (context, filtersSnap) {
        final activeFilters = filtersSnap.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_clippingDetected)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HIGH SIGNAL: CLIPPING DETECTED',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Reduce "Preamp" or "Volume Gain" to avoid distortion.',
                              style: TextStyle(
                                color: Colors.red.withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // --- Digital Signal Processing ---
            const PropertySectionHeader(title: 'Digital Signal Processing'),
            
            // Equalizer
            StreamBuilder<List<double>>(
              stream: widget.player.stream.equalizerGains,
              initialData: widget.player.state.equalizerGains,
              builder: (context, eqSnap) {
                final gains = eqSnap.data ?? List.filled(10, 0.0);
                final eqEnabled = _isFilterActive(activeFilters, 'equalizer');
                
                return PropertyBaseCard(
                  title: '10-Band Equalizer',
                  subtitle: 'af=equalizer',
                  icon: Icons.equalizer_rounded,
                  isActive: eqEnabled,
                  trailing: Switch(
                    value: eqEnabled,
                    onChanged: (v) {
                      _toggleFilter('equalizer', v, specificFilter: AudioFilter.equalizer(gains));
                    },
                  ),
                  body: EQWidget(
                    gains: gains,
                    enabled: eqEnabled,
                    onChanged: (i, v) {
                      final newGains = List<double>.from(gains);
                      newGains[i] = v;
                      widget.player.setEqualizerGains(newGains);
                      if (eqEnabled) {
                        _toggleFilter('equalizer', true, specificFilter: AudioFilter.equalizer(newGains));
                      }
                    },
                  ),
                );
              },
            ),

            TogglePropertyCard(
              title: 'Compressor',
              subtitle: 'af=acompressor',
              icon: Icons.vignette_rounded,
              value: _isFilterActive(activeFilters, 'acompressor'),
              onChanged: (v) => _toggleFilter('acompressor', v, specificFilter: AudioFilter.compressor()),
            ),
            TogglePropertyCard(
              title: 'Loudnorm',
              subtitle: 'af=loudnorm',
              icon: Icons.graphic_eq_rounded,
              value: _isFilterActive(activeFilters, 'loudnorm'),
              onChanged: (v) => _toggleFilter('loudnorm', v, specificFilter: AudioFilter.loudnorm()),
            ),
            TogglePropertyCard(
              title: 'Extra Stereo',
              subtitle: 'af=extrastereo',
              icon: Icons.surround_sound_rounded,
              value: _isFilterActive(activeFilters, 'extrastereo'),
              onChanged: (v) => _toggleFilter('extrastereo', v, specificFilter: AudioFilter.extraStereo()),
            ),
            TogglePropertyCard(
              title: 'Crystalizer',
              subtitle: 'af=crystalizer',
              icon: Icons.auto_fix_high_rounded,
              value: _isFilterActive(activeFilters, 'crystalizer'),
              onChanged: (v) => _toggleFilter('crystalizer', v, specificFilter: AudioFilter.crystalizer()),
            ),
            TogglePropertyCard(
              title: 'Echo',
              subtitle: 'af=aecho',
              icon: Icons.settings_input_antenna_rounded,
              value: _isFilterActive(activeFilters, 'aecho'),
              onChanged: (v) => _toggleFilter('aecho', v, specificFilter: AudioFilter.echo()),
            ),
            TogglePropertyCard(
              title: 'Crossfeed',
              subtitle: 'af=crossfeed',
              icon: Icons.headphones_rounded,
              value: _isFilterActive(activeFilters, 'crossfeed'),
              onChanged: (v) => _toggleFilter('crossfeed', v, specificFilter: AudioFilter.crossfeed()),
            ),

            // --- Pitch & Speed ---
            const PropertySectionHeader(title: 'Tempo & Pitch'),
            StreamBuilder<double>(
              stream: widget.player.stream.pitch,
              initialData: widget.player.state.pitch,
              builder: (_, snap) {
                final val = snap.data ?? 1.0;
                return SliderPropertyCard(
                  title: 'Playback Pitch',
                  subtitle: 'pitch=${val.toStringAsFixed(2)}',
                  icon: Icons.music_note_rounded,
                  value: val,
                  min: 0.5,
                  max: 2.0,
                  onChanged: widget.player.setPitch,
                );
              },
            ),
            StreamBuilder<double>(
              stream: widget.player.stream.rate,
              initialData: widget.player.state.rate,
              builder: (_, snap) {
                final val = snap.data ?? 1.0;
                return SliderPropertyCard(
                  title: 'Playback Speed',
                  subtitle: 'speed=${val.toStringAsFixed(2)}',
                  icon: Icons.speed_rounded,
                  value: val,
                  min: 0.5,
                  max: 2.0,
                  onChanged: widget.player.setRate,
                );
              },
            ),
            StreamBuilder<bool>(
              stream: widget.player.stream.pitchCorrection,
              initialData: widget.player.state.pitchCorrection,
              builder: (context, snap) {
                final pc = snap.data ?? true;
                return TogglePropertyCard(
                  title: 'Pitch Correction',
                  subtitle: 'audio-pitch-correction=${pc ? 'yes' : 'no'}',
                  icon: Icons.high_quality_rounded,
                  value: pc,
                  onChanged: (v) => widget.player.setPitchCorrection(v),
                );
              },
            ),

            // --- ReplayGain ---
            const PropertySectionHeader(title: 'Normalization (Gain)'),
            StreamBuilder<String>(
              stream: widget.player.stream.gaplessMode,
              initialData: widget.player.state.gaplessMode,
              builder: (context, snap) {
                final mode = snap.data ?? 'no';
                final options = {'no': 'NONE', 'yes': 'YES', 'weak': 'WEAK'};
                if (!options.containsKey(mode)) options[mode] = mode.toUpperCase();
                
                return DropdownPropertyCard<String>(
                  title: 'Gapless Playback',
                  subtitle: 'gapless-audio=$mode',
                  icon: Icons.leak_add_rounded,
                  value: mode,
                  items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) => v != null ? widget.player.setGaplessPlayback(v) : null,
                );
              },
            ),
            StreamBuilder<String>(
              stream: widget.player.stream.replayGainMode,
              initialData: widget.player.state.replayGainMode,
              builder: (context, snap) {
                final mode = snap.data ?? 'no';
                final options = {'no': 'NONE', 'track': 'TRACK', 'album': 'ALBUM'};
                if (!options.containsKey(mode)) options[mode] = mode.toUpperCase();

                return DropdownPropertyCard<String>(
                  title: 'ReplayGain Mode',
                  subtitle: 'replaygain=$mode',
                  icon: Icons.av_timer_rounded,
                  value: mode,
                  items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) => v != null ? widget.player.setReplayGain(v) : null,
                );
              },
            ),
            StreamBuilder<double>(
              stream: widget.player.stream.replayGainPreamp,
              initialData: widget.player.state.replayGainPreamp,
              builder: (context, snap) {
                final val = snap.data ?? 0.0;
                return SliderPropertyCard(
                  title: 'Preamp',
                  subtitle: 'replaygain-preamp=${val.toStringAsFixed(1)}dB',
                  icon: Icons.tune_rounded,
                  value: val,
                  min: -15.0,
                  max: 15.0,
                  label: '${val.toStringAsFixed(1)}dB',
                  onChanged: widget.player.setReplayGainPreamp,
                );
              },
            ),
            StreamBuilder<double>(
              stream: widget.player.stream.replayGainFallback,
              initialData: widget.player.state.replayGainFallback,
              builder: (context, snap) {
                final val = snap.data ?? 0.0;
                return SliderPropertyCard(
                  title: 'Fallback',
                  subtitle: 'replaygain-fallback=${val.toStringAsFixed(1)}dB',
                  icon: Icons.settings_backup_restore_rounded,
                  value: val,
                  min: -15.0,
                  max: 15.0,
                  label: '${val.toStringAsFixed(1)}dB',
                  onChanged: widget.player.setReplayGainFallback,
                );
              },
            ),
            StreamBuilder<bool>(
              stream: widget.player.stream.replayGainClip,
              initialData: widget.player.state.replayGainClip,
              builder: (context, snap) {
                final clip = snap.data ?? false;
                return TogglePropertyCard(
                  title: 'Allow Clipping',
                  subtitle: 'replaygain-clip=${clip ? 'yes' : 'no'}',
                  icon: Icons.high_quality_rounded,
                  value: clip,
                  onChanged: widget.player.setReplayGainClip,
                );
              },
            ),
            StreamBuilder<double>(
              stream: widget.player.stream.volumeGain,
              initialData: widget.player.state.volumeGain,
              builder: (context, snap) {
                final val = snap.data ?? 0.0;
                return SliderPropertyCard(
                  title: 'Volume Gain',
                  subtitle: 'volume-gain=${val.toStringAsFixed(1)}dB',
                  icon: Icons.volume_up_rounded,
                  value: val,
                  min: -96.0,
                  max: 12.0,
                  label: '${val.toStringAsFixed(1)}dB',
                  onChanged: widget.player.setVolumeGain,
                );
              },
            ),
            const PropertySectionHeader(title: 'Engine Recovery'),
            PropertyBaseCard(
              title: 'Reload Audio Engine',
              subtitle: 'Execute ao-reload command',
              icon: Icons.refresh_rounded,
              isActive: true,
              trailing: ElevatedButton.icon(
                onPressed: widget.player.reloadAudio,
                icon: const Icon(Icons.sync_rounded),
                label: const Text('RELOAD'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}
