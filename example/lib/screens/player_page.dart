import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'player/playback_tab.dart';
import 'player/queue_tab.dart';
import 'player/logs_tab.dart';
import 'settings_page.dart';
import 'settings/stream_lab_page.dart';
import '../main.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  String? _error;
  final List<String> _logs = [];
  bool _isConsolePinned = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  int _navIndex = 0;

  Future<void> _handleTogglePin(bool pin) async {
    setState(() => _isConsolePinned = pin);

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final Size size = await windowManager.getSize();
      if (pin) {
        if (size.width < 1100) {
          await windowManager.setSize(Size(1100, size.height), animate: true);
        }
      } else {
        if (size.width >= 1100) {
          await windowManager.setSize(Size(720, size.height), animate: true);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    try {
      // Listen for changes and save them
      player.stream.volume.listen((v) => settingsService.save('volume', v));
      player.stream.volumeMax.listen((v) => settingsService.save('volume-max', v));
      player.stream.rate.listen((v) => settingsService.save('rate', v));
      player.stream.pitch.listen((v) => settingsService.save('pitch', v));
      player.stream.mute.listen((v) => settingsService.save('mute', v));

      player.stream.playlistMode.listen((v) => settingsService.save('playlist_mode', v.name));
      player.stream.shuffle.listen((v) => settingsService.save('shuffle', v));

      player.stream.audioSampleRate.listen((v) => settingsService.save('audio-samplerate', v));
      player.stream.audioFormat.listen((v) => settingsService.save('audio-format', v));
      player.stream.audioChannels.listen((v) => settingsService.save('audio-channels', v));
      player.stream.audioClientName.listen((v) => settingsService.save('audio-client-name', v));
      player.stream.audioDevice.listen((v) => settingsService.save('audio-device', v.name));
      player.stream.audioSpdif.listen((v) => settingsService.save('audio-spdif', v));
      player.stream.audioExclusive.listen((v) => settingsService.save('audio-exclusive', v));
      player.stream.audioBuffer.listen((v) => settingsService.save('audio-buffer', v));
      player.stream.audioDelay.listen((v) => settingsService.save('audio-delay', v));

      player.stream.gaplessMode.listen((v) => settingsService.save('gapless-audio', v));
      player.stream.replayGainMode.listen((v) => settingsService.save('replaygain', v));
      player.stream.replayGainPreamp.listen((v) => settingsService.save('replaygain-preamp', v));
      player.stream.replayGainFallback.listen((v) => settingsService.save('replaygain-fallback', v));
      player.stream.replayGainClip.listen((v) => settingsService.save('replaygain-clip', v));
      player.stream.volumeGain.listen((v) => settingsService.save('volume-gain', v));
      player.stream.pitchCorrection.listen((v) => settingsService.save('pitch-correction', v));

      player.stream.cacheMode.listen((v) => settingsService.save('cache', v));
      player.stream.cacheSecs.listen((v) => settingsService.save('cache-secs', v));
      player.stream.cacheOnDisk.listen((v) => settingsService.save('cache-on-disk', v));
      player.stream.cachePause.listen((v) => settingsService.save('cache-pause', v));
      player.stream.cachePauseWait.listen((v) => settingsService.save('cache-pause-wait', v));
      player.stream.demuxerMaxBytes.listen((v) => settingsService.save('demuxer-max-bytes', v));
      player.stream.demuxerReadaheadSecs.listen((v) => settingsService.save('demuxer-readahead-secs', v));
      player.stream.demuxerMaxBackBytes.listen((v) => settingsService.save('demuxer-max-back-bytes', v));

      player.stream.networkTimeout.listen((v) => settingsService.save('network-timeout', v));
      player.stream.tlsVerify.listen((v) => settingsService.save('tls-verify', v));
      player.stream.streamSilence.listen((v) => settingsService.save('stream-silence', v));
      player.stream.aoNullUntimed.listen((v) => settingsService.save('ao-null-untimed', v));
      player.stream.audioTrack.listen((v) => settingsService.save('aid', v));
      player.stream.equalizerGains.listen((v) => settingsService.save('equalizer_gains', v));

      player.stream.log.listen((line) {
        if (mounted) {
          setState(() {
            _logs.add(line.toString());
            if (_logs.length > 500) {
              _logs.removeAt(0);
            }
          });
        }
      });
      player.stream.playing.listen((p) {
        debugPrint('[player] playing → $p');
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final showPinned = _isConsolePinned && isWide;

            // Pages that respect the 650px constraint
            // Nav: 0=Player, 1=Queue, 2=Stream, 3=Settings, 4=Logs(optional)
            final constrainedPages = <Widget>[
              PlaybackTab(player: player),
              QueueTab(player: player),
              StreamLabPage(player: player),
              if (!showPinned)
                LogsTab(
                  player: player,
                  logs: List.from(_logs),
                  isPinned: false,
                  onClearLogs: () => setState(() => _logs.clear()),
                  onTogglePin: () => _handleTogglePin(true),
                ),
            ];

            final totalNav = showPinned ? 4 : 5;
            final safeIndex = _navIndex.clamp(0, totalNav - 1);
            final isSettings = safeIndex == 3;
            // Constrained IndexedStack skips the settings slot (index 3)
            final constrainedIndex = (safeIndex >= 4 ? safeIndex - 1 : safeIndex)
                .clamp(0, constrainedPages.length - 1);

            Widget content = Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Offstage(
                        offstage: isSettings,
                        child: IndexedStack(
                          index: constrainedIndex,
                          children: constrainedPages,
                        ),
                      ),
                      Offstage(
                        offstage: !isSettings,
                        child: SettingsPage(player: player),
                      ),
                    ],
                  ),
                ),
                NavigationBar(
                  selectedIndex: safeIndex,
                  onDestinationSelected: (i) => setState(() => _navIndex = i),
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.play_arrow_rounded),
                      label: 'Player',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.queue_music_rounded),
                      label: 'Queue',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.rss_feed_rounded),
                      label: 'Stream',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.settings_rounded),
                      label: 'Settings',
                    ),
                    if (!showPinned)
                      const NavigationDestination(
                        icon: Icon(Icons.terminal_rounded),
                        label: 'Logs',
                      ),
                  ],
                ),
              ],
            );

            if (showPinned) {
              return Row(
                children: [
                  Expanded(
                    child: Container(
                      color: theme.colorScheme.surface,
                      child: content,
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  SizedBox(
                    width: 380,
                    child: Material(
                      color: theme.colorScheme.surfaceContainerLow,
                      child: LogsTab(
                        player: player,
                        logs: List.from(_logs),
                        isPinned: true,
                        onClearLogs: () => setState(() => _logs.clear()),
                        onTogglePin: () => _handleTogglePin(false),
                      ),
                    ),
                  ),
                ],
              );
            }

            return content;
          },
        ),
      ),
    );
  }
}
