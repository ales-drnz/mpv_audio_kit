import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../pages/ab_loop_page.dart';
import '../pages/about_page.dart';
import '../pages/aid_page.dart';
import '../pages/ao_page.dart';
import '../pages/audio_page.dart';
import '../pages/cache_page.dart';
import '../pages/chapters_page.dart';
import '../pages/cover_art_page.dart';
import '../pages/demuxer_page.dart';
import '../pages/file_info_page.dart';
import '../pages/filters_page.dart';
import '../pages/hooks_page.dart';
import '../pages/network_page.dart';
import '../pages/pitch_page.dart';
import '../pages/playback_info_page.dart';
import '../pages/prefetch_page.dart';
import '../pages/replaygain_page.dart';
import '../pages/spectrum_page.dart';
import '../pages/speed_page.dart';
import '../pages/stream_silence_page.dart';
import '../pages/tls_page.dart';
import '../pages/volume_page.dart';

/// One row of metadata per settings page. Adding a new settings page
/// = appending one entry to [settingsEntries] below; no other code changes.
typedef PageBuilder = Widget Function(Player player);

class PageMeta {
  final String label;
  final IconData icon;
  final String title;
  final PageBuilder builder;

  const PageMeta({
    required this.label,
    required this.icon,
    required this.title,
    required this.builder,
  });
}

const settingsEntries = <PageMeta>[
  PageMeta(
    label: 'af',
    icon: Icons.equalizer_rounded,
    title: 'Filters',
    builder: _filters,
  ),
  PageMeta(
    label: 'speed',
    icon: Icons.speed_rounded,
    title: 'Speed',
    builder: _speed,
  ),
  PageMeta(
    label: 'pitch',
    icon: Icons.music_note_rounded,
    title: 'Pitch',
    builder: _pitch,
  ),
  PageMeta(
    label: 'replaygain',
    icon: Icons.av_timer_rounded,
    title: 'ReplayGain',
    builder: _replaygain,
  ),
  PageMeta(
    label: 'spectrum',
    icon: Icons.graphic_eq_rounded,
    title: 'Spectrum',
    builder: _spectrum,
  ),
  PageMeta(
    label: 'volume',
    icon: Icons.volume_up_rounded,
    title: 'Volume',
    builder: _volume,
  ),
  PageMeta(
    label: 'audio',
    icon: Icons.settings_input_component_rounded,
    title: 'Audio Hardware',
    builder: _audio,
  ),
  PageMeta(
    label: 'aid',
    icon: Icons.audiotrack_rounded,
    title: 'Audio Track',
    builder: _aid,
  ),
  PageMeta(
    label: 'ao',
    icon: Icons.router_rounded,
    title: 'Audio Output',
    builder: _ao,
  ),
  PageMeta(
    label: 'cache',
    icon: Icons.cached_rounded,
    title: 'Cache',
    builder: _cache,
  ),
  PageMeta(
    label: 'demuxer',
    icon: Icons.dns_rounded,
    title: 'Demuxer',
    builder: _demuxer,
  ),
  PageMeta(
    label: 'network',
    icon: Icons.cloud_rounded,
    title: 'Network',
    builder: _network,
  ),
  PageMeta(
    label: 'tls',
    icon: Icons.enhanced_encryption_rounded,
    title: 'TLS',
    builder: _tls,
  ),
  PageMeta(
    label: 'stream',
    icon: Icons.shutter_speed_rounded,
    title: 'Stream Silence',
    builder: _streamSilence,
  ),
  PageMeta(
    label: 'cover',
    icon: Icons.image_rounded,
    title: 'Cover Art',
    builder: _coverArt,
  ),
  PageMeta(
    label: 'chapter',
    icon: Icons.bookmark_rounded,
    title: 'Chapters',
    builder: _chapters,
  ),
  PageMeta(
    label: 'ab-loop',
    icon: Icons.repeat_one_on_rounded,
    title: 'A-B Loop',
    builder: _abLoop,
  ),
  PageMeta(
    label: 'hook',
    icon: Icons.cable_rounded,
    title: 'Hooks Lab',
    builder: _hooks,
  ),
  PageMeta(
    label: 'prefetch',
    icon: Icons.fast_forward_rounded,
    title: 'Prefetch',
    builder: _prefetch,
  ),
  PageMeta(
    label: 'playback',
    icon: Icons.timeline_rounded,
    title: 'Playback Info',
    builder: _playbackInfo,
  ),
  PageMeta(
    label: 'file',
    icon: Icons.description_rounded,
    title: 'File Info',
    builder: _fileInfo,
  ),
  PageMeta(
    label: 'about',
    icon: Icons.info_outline_rounded,
    title: 'About',
    builder: _about,
  ),
];

// Top-level builders so the const list above can reference them
// (closures aren't const-compatible).
Widget _filters(Player p) => FiltersPage(player: p);
Widget _speed(Player p) => SpeedPage(player: p);
Widget _pitch(Player p) => PitchPage(player: p);
Widget _replaygain(Player p) => ReplayGainPage(player: p);
Widget _spectrum(Player p) => SpectrumPage(player: p);
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
