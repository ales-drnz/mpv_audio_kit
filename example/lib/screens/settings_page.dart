import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../widgets/property_cards.dart';
import 'settings/filters_page.dart';
import 'settings/speed_page.dart';
import 'settings/pitch_page.dart';
import 'settings/replaygain_page.dart';
import 'settings/volume_page.dart';
import 'settings/audio_page.dart';
import 'settings/aid_page.dart';
import 'settings/ao_page.dart';
import 'settings/cache_page.dart';
import 'settings/demuxer_page.dart';
import 'settings/network_page.dart';
import 'settings/tls_page.dart';
import 'settings/stream_silence_page.dart';
import 'settings/cover_art_page.dart';

class SettingsPage extends StatefulWidget {
  final Player player;

  const SettingsPage({super.key, required this.player});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => _SettingsHome(
            player: widget.player,
            onNavigate: (title, builder) {
              _navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: Text(title),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => _navigatorKey.currentState?.pop(),
                      ),
                    ),
                    body: builder(context),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SettingsHome extends StatefulWidget {
  final Player player;
  final Function(String, WidgetBuilder) onNavigate;

  const _SettingsHome({required this.player, required this.onNavigate});

  @override
  State<_SettingsHome> createState() => _SettingsHomeState();
}

class _SettingsHomeState extends State<_SettingsHome> {
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

  void _go(String title, Widget page) {
    widget.onNavigate(title, (_) => page);
  }

  @override
  Widget build(BuildContext context) {
    final entries = [
      _NavEntry(
        label: 'af',
        icon: Icons.equalizer_rounded,
        title: 'Filters',
        onTap: () => _go('Filters', FiltersPage(player: widget.player)),
      ),
      _NavEntry(
        label: 'speed',
        icon: Icons.speed_rounded,
        title: 'Speed',
        onTap: () => _go('Speed', SpeedPage(player: widget.player)),
      ),
      _NavEntry(
        label: 'pitch',
        icon: Icons.music_note_rounded,
        title: 'Pitch',
        onTap: () => _go('Pitch', PitchPage(player: widget.player)),
      ),
      _NavEntry(
        label: 'replaygain',
        icon: Icons.av_timer_rounded,
        title: 'ReplayGain',
        onTap: () => _go('ReplayGain', ReplayGainPage(player: widget.player)),
      ),
      _NavEntry(
        label: 'volume',
        icon: Icons.volume_up_rounded,
        title: 'Volume',
        onTap: () => _go('Volume', VolumePage(player: widget.player)),
      ),
      _NavEntry(
        label: 'audio',
        icon: Icons.settings_input_component_rounded,
        title: 'Audio Hardware',
        onTap: () => _go('Audio Hardware', AudioPage(player: widget.player)),
      ),
      _NavEntry(
        label: 'aid',
        icon: Icons.audiotrack_rounded,
        title: 'Audio Track',
        onTap: () => _go('Audio Track', AidPage(player: widget.player)),
      ),
      _NavEntry(
        label: 'ao',
        icon: Icons.router_rounded,
        title: 'Audio Output',
        onTap: () => _go('Audio Output', AoPage(player: widget.player)),
      ),
      _NavEntry(
        label: 'cache',
        icon: Icons.cached_rounded,
        title: 'Cache',
        onTap: () => _go('Cache', CachePage(player: widget.player)),
      ),
      _NavEntry(
        label: 'demuxer',
        icon: Icons.dns_rounded,
        title: 'Demuxer',
        onTap: () => _go('Demuxer', DemuxerPage(player: widget.player)),
      ),
      _NavEntry(
        label: 'network',
        icon: Icons.cloud_rounded,
        title: 'Network',
        onTap: () => _go('Network', NetworkPage(player: widget.player)),
      ),
      _NavEntry(
        label: 'tls',
        icon: Icons.enhanced_encryption_rounded,
        title: 'TLS',
        onTap: () => _go('TLS', TlsPage(player: widget.player)),
      ),
      _NavEntry(
        label: 'stream',
        icon: Icons.shutter_speed_rounded,
        title: 'Stream Silence',
        onTap: () =>
            _go('Stream Silence', StreamSilencePage(player: widget.player)),
      ),
      _NavEntry(
        label: 'cover',
        icon: Icons.image_rounded,
        title: 'Cover Art',
        onTap: () => _go('Cover Art', CoverArtPage(player: widget.player)),
      ),
    ];

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PropertySectionHeader(title: 'Settings'),
          if (_clippingDetected) ...[
            _ClippingBanner(),
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
            itemCount: entries.length,
            itemBuilder: (context, i) => _GridCard(entry: entries[i]),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NavEntry {
  final String label;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _NavEntry({
    required this.label,
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class _GridCard extends StatelessWidget {
  final _NavEntry entry;
  const _GridCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: entry.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '--${entry.label}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const Spacer(),
              Icon(entry.icon, size: 22, color: cs.onSurfaceVariant),
              const SizedBox(height: 6),
              Text(
                entry.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClippingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
