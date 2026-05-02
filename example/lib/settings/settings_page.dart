import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../shared/property_cards.dart';
import 'pages/filters_page.dart';
import 'pages/speed_page.dart';
import 'pages/pitch_page.dart';
import 'pages/replaygain_page.dart';
import 'pages/volume_page.dart';
import 'pages/audio_page.dart';
import 'pages/aid_page.dart';
import 'pages/ao_page.dart';
import 'pages/cache_page.dart';
import 'pages/demuxer_page.dart';
import 'pages/network_page.dart';
import 'pages/tls_page.dart';
import 'pages/stream_silence_page.dart';
import 'pages/cover_art_page.dart';
import 'pages/chapters_page.dart';
import 'pages/ab_loop_page.dart';
import 'pages/hooks_page.dart';
import 'pages/prefetch_page.dart';
import 'pages/playback_info_page.dart';
import 'pages/file_info_page.dart';
import 'pages/about_page.dart';

/// One row of metadata per settings page. Adding a new settings page
/// = appending one entry to [_entries] below; no other code changes.
typedef _PageBuilder = Widget Function(Player player);

class _PageMeta {
  final String label;
  final IconData icon;
  final String title;
  final _PageBuilder builder;

  const _PageMeta({
    required this.label,
    required this.icon,
    required this.title,
    required this.builder,
  });
}

const _entries = <_PageMeta>[
  _PageMeta(
    label: 'af',
    icon: Icons.equalizer_rounded,
    title: 'Filters',
    builder: _filters,
  ),
  _PageMeta(
    label: 'speed',
    icon: Icons.speed_rounded,
    title: 'Speed',
    builder: _speed,
  ),
  _PageMeta(
    label: 'pitch',
    icon: Icons.music_note_rounded,
    title: 'Pitch',
    builder: _pitch,
  ),
  _PageMeta(
    label: 'replaygain',
    icon: Icons.av_timer_rounded,
    title: 'ReplayGain',
    builder: _replaygain,
  ),
  _PageMeta(
    label: 'volume',
    icon: Icons.volume_up_rounded,
    title: 'Volume',
    builder: _volume,
  ),
  _PageMeta(
    label: 'audio',
    icon: Icons.settings_input_component_rounded,
    title: 'Audio Hardware',
    builder: _audio,
  ),
  _PageMeta(
    label: 'aid',
    icon: Icons.audiotrack_rounded,
    title: 'Audio Track',
    builder: _aid,
  ),
  _PageMeta(
    label: 'ao',
    icon: Icons.router_rounded,
    title: 'Audio Output',
    builder: _ao,
  ),
  _PageMeta(
    label: 'cache',
    icon: Icons.cached_rounded,
    title: 'Cache',
    builder: _cache,
  ),
  _PageMeta(
    label: 'demuxer',
    icon: Icons.dns_rounded,
    title: 'Demuxer',
    builder: _demuxer,
  ),
  _PageMeta(
    label: 'network',
    icon: Icons.cloud_rounded,
    title: 'Network',
    builder: _network,
  ),
  _PageMeta(
    label: 'tls',
    icon: Icons.enhanced_encryption_rounded,
    title: 'TLS',
    builder: _tls,
  ),
  _PageMeta(
    label: 'stream',
    icon: Icons.shutter_speed_rounded,
    title: 'Stream Silence',
    builder: _streamSilence,
  ),
  _PageMeta(
    label: 'cover',
    icon: Icons.image_rounded,
    title: 'Cover Art',
    builder: _coverArt,
  ),
  _PageMeta(
    label: 'chapter',
    icon: Icons.bookmark_rounded,
    title: 'Chapters',
    builder: _chapters,
  ),
  _PageMeta(
    label: 'ab-loop',
    icon: Icons.repeat_one_on_rounded,
    title: 'A-B Loop',
    builder: _abLoop,
  ),
  _PageMeta(
    label: 'hook',
    icon: Icons.cable_rounded,
    title: 'Hooks Lab',
    builder: _hooks,
  ),
  _PageMeta(
    label: 'prefetch',
    icon: Icons.fast_forward_rounded,
    title: 'Prefetch',
    builder: _prefetch,
  ),
  _PageMeta(
    label: 'playback',
    icon: Icons.timeline_rounded,
    title: 'Playback Info',
    builder: _playbackInfo,
  ),
  _PageMeta(
    label: 'file',
    icon: Icons.description_rounded,
    title: 'File Info',
    builder: _fileInfo,
  ),
  _PageMeta(
    label: 'about',
    icon: Icons.info_outline_rounded,
    title: 'About',
    builder: _about,
  ),
];

// Top-level page builders so the const list above can reference them
// (closures aren't const-compatible).
Widget _filters(Player p) => FiltersPage(player: p);
Widget _speed(Player p) => SpeedPage(player: p);
Widget _pitch(Player p) => PitchPage(player: p);
Widget _replaygain(Player p) => ReplayGainPage(player: p);
Widget _volume(Player p) => VolumePage(player: p);
Widget _audio(Player p) => AudioPage(player: p);
Widget _aid(Player p) => AidPage(player: p);
Widget _ao(Player p) => AoPage(player: p);
Widget _cache(Player p) => CachePage(player: p);
Widget _demuxer(Player p) => DemuxerPage(player: p);
Widget _network(Player p) => NetworkPage(player: p);
Widget _tls(Player p) => TlsPage(player: p);
Widget _streamSilence(Player p) => StreamSilencePage(player: p);
Widget _coverArt(Player p) => CoverArtPage(player: p);
Widget _chapters(Player p) => ChaptersPage(player: p);
Widget _abLoop(Player p) => AbLoopPage(player: p);
Widget _hooks(Player p) => HooksPage(player: p);
Widget _prefetch(Player p) => PrefetchPage(player: p);
Widget _playbackInfo(Player p) => PlaybackInfoPage(player: p);
Widget _fileInfo(Player p) => FileInfoPage(player: p);
Widget _about(Player p) => AboutPage(player: p);

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

  @override
  Widget build(BuildContext context) {
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
            itemCount: _entries.length,
            itemBuilder: (context, i) {
              final entry = _entries[i];
              return _GridCard(
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

class _GridCard extends StatelessWidget {
  final _PageMeta entry;
  final VoidCallback onTap;
  const _GridCard({required this.entry, required this.onTap});

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
        onTap: onTap,
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
