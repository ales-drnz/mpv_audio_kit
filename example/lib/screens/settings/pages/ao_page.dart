import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../../shared/property_cards.dart';

class AoPage extends StatefulWidget {
  final Player player;
  const AoPage({super.key, required this.player});

  @override
  State<AoPage> createState() => _AoPageState();
}

class _AoPageState extends State<AoPage> {
  List<String> _availableDrivers = ['auto'];

  @override
  void initState() {
    super.initState();
    _loadAvailableDrivers();
  }

  Future<void> _loadAvailableDrivers() async {
    final collected = <String>[];
    bool collecting = false;

    final sub = widget.player.stream.log.listen((entry) {
      final text = entry.text.trim();
      if (text.contains('Available audio outputs')) {
        collecting = true;
        return;
      }
      if (collecting && text.isNotEmpty) {
        final driverName = text.split(RegExp(r'\s+')).first;
        if (driverName.isNotEmpty) collected.add(driverName);
      }
    });

    // mpv idiom: writing `ao=help` prints the available drivers as a
    // log side-effect, then rejects the property write itself (since
    // "help" is not a real driver name). The wrapper surfaces that
    // rejection as MpvException — we swallow it because the listing
    // has already arrived via the log subscription above.
    try {
      await widget.player.setRawProperty('ao', 'help');
    } on MpvException {
      // Expected — the listing succeeds even when the assignment fails.
    }
    await Future.delayed(const Duration(milliseconds: 300));
    await sub.cancel();

    if (collected.isNotEmpty && mounted) {
      setState(() => _availableDrivers = ['auto', ...collected]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Output Driver'),
        StreamBuilder<String>(
          stream: widget.player.stream.audioDriver,
          initialData: widget.player.state.audioDriver,
          builder: (context, snap) {
            String val = snap.data ?? 'auto';
            if (val.isEmpty) val = 'auto';

            final options = List<String>.from(_availableDrivers);
            if (!options.contains(val)) options.add(val);

            // Subtitle is rendered synchronously; the async `current-ao`
            // lookup is left out here. If a deeper "active driver" hint
            // is needed, fetch it in initState and store on state.
            final subtitle = 'ao=$val';

            return DropdownPropertyCard<String>(
              title: 'Audio Driver',
              subtitle: subtitle,
              icon: Icons.tune_rounded,
              value: val,
              items: options
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) =>
                  v != null ? widget.player.setAudioDriver(v) : null,
            );
          },
        ),

        const PropertySectionHeader(title: 'Engine'),
        StreamBuilder<bool>(
          stream: widget.player.stream.audioNullUntimed,
          initialData: widget.player.state.audioNullUntimed,
          builder: (context, snap) {
            final val = snap.data ?? false;
            return TogglePropertyCard(
              title: 'Fallback to Null',
              subtitle: 'ao-null-untimed=${val ? 'yes' : 'no'}',
              icon: Icons.layers_clear_rounded,
              value: val,
              onChanged: (v) =>
                  unawaited(widget.player.setAudioNullUntimed(v)),
            );
          },
        ),
        PropertyBaseCard(
          title: 'Reload Audio Engine',
          subtitle: 'ao-reload',
          icon: Icons.refresh_rounded,
          isActive: true,
          trailing: FilledButton.tonal(
            onPressed: widget.player.reloadAudio,
            child: const Icon(Icons.sync_rounded, size: 18),
          ),
        ),

        const PropertySectionHeader(title: 'Output Status'),
        StreamBuilder<String>(
          stream: widget.player.stream.currentAo,
          initialData: widget.player.state.currentAo,
          builder: (_, snap) => ReadOnlyPropertyCard(
            title: 'Active Driver',
            subtitle: 'current-ao=${snap.data ?? ''}',
            icon: Icons.speaker_rounded,
            value: (snap.data?.isEmpty ?? true) ? '—' : snap.data!,
          ),
        ),
        StreamBuilder<AudioOutputState>(
          stream: widget.player.stream.audioOutputState,
          initialData: widget.player.state.audioOutputState,
          builder: (_, snap) {
            final state = snap.data ?? AudioOutputState.closed;
            return ReadOnlyPropertyCard(
              title: 'Output State',
              subtitle: 'audio-output-state=${state.mpvValue}',
              icon: Icons.power_settings_new_rounded,
              value: state.mpvValue,
            );
          },
        ),
        StreamBuilder<AudioParams>(
          stream: widget.player.stream.audioOutParams,
          initialData: widget.player.state.audioOutParams,
          builder: (_, snap) {
            final p = snap.data ?? const AudioParams();
            final desc = [
              if (p.format != null) p.format!,
              if (p.sampleRate != null)
                '${(p.sampleRate! / 1000).toStringAsFixed(1)}kHz',
              if (p.channels != null) p.channels!,
            ].join(' / ');
            return ReadOnlyPropertyCard(
              title: 'Output Params',
              subtitle: 'audio-out-params',
              icon: Icons.tune_rounded,
              value: desc.isEmpty ? '—' : desc,
            );
          },
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
