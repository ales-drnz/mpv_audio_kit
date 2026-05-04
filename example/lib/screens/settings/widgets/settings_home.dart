import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../../shared/property_cards.dart';
import 'clipping_banner.dart';
import 'grid_card.dart';
import 'page_meta.dart';

class SettingsHome extends StatefulWidget {
  final Player player;
  final void Function(String, WidgetBuilder) onNavigate;

  const SettingsHome({
    super.key,
    required this.player,
    required this.onNavigate,
  });

  @override
  State<SettingsHome> createState() => _SettingsHomeState();
}

class _SettingsHomeState extends State<SettingsHome> {
  StreamSubscription<MpvLogEntry>? _logSub;
  bool _clippingDetected = false;
  Timer? _clippingTimer;

  @override
  void initState() {
    super.initState();
    _logSub = widget.player.stream.log.listen((line) {
      if (line.text.contains('clipping')) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PropertySectionHeader(title: 'Settings'),
          if (_clippingDetected) ...[
            const ClippingBanner(),
            const SizedBox(height: 12),
          ],
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.2,
            ),
            itemCount: settingsEntries.length,
            itemBuilder: (context, i) {
              final entry = settingsEntries[i];
              return GridCard(
                entry: entry,
                onTap: () => widget.onNavigate(
                  entry.title,
                  (_) => entry.builder(widget.player),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
