import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/property_cards.dart';

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

    widget.player.setRawProperty('ao', 'help');
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
            final val = snap.data ?? 'auto';
            final options = List<String>.from(_availableDrivers);
            if (!options.contains(val)) options.add(val);
            return DropdownPropertyCard<String>(
              title: 'Audio Driver',
              subtitle: 'ao=$val',
              icon: Icons.tune_rounded,
              value: val,
              items: options
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => v != null ? widget.player.setAudioDriver(v) : null,
            );
          },
        ),

        const PropertySectionHeader(title: 'Engine'),
        StreamBuilder<bool>(
          stream: widget.player.stream.aoNullUntimed,
          initialData: widget.player.state.aoNullUntimed,
          builder: (context, snap) {
            final val = snap.data ?? false;
            return TogglePropertyCard(
              title: 'Fallback to Null',
              subtitle: 'ao-null-untimed=${val ? 'yes' : 'no'}',
              icon: Icons.layers_clear_rounded,
              value: val,
              onChanged: (v) =>
                  widget.player.setRawProperty('ao-null-untimed', v ? 'yes' : 'no'),
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

        const SizedBox(height: 16),
      ],
    );
  }
}
