import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'tabs/playback_tab.dart';
import 'tabs/queue_tab.dart';
import 'tabs/logs_tab.dart';
import 'settings_page.dart';
import '../main.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final Player _player;
  String? _error;
  final List<String> _logs = [];
  bool _isConsolePinned = false;
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
      _player = Player(
        configuration: const PlayerConfiguration(
          initialVolume: 50.0,
          autoPlay: true,
          logLevel: 'debug',
        ),
      );

      // Restore settings
      settingsService.restore(_player);

      // Listen for changes and save them
      _player.stream.volume.listen((v) => settingsService.save('volume', v));
      _player.stream.volumeMax.listen((v) => settingsService.save('volume-max', v));
      _player.stream.rate.listen((v) => settingsService.save('rate', v));
      _player.stream.pitch.listen((v) => settingsService.save('pitch', v));
      _player.stream.mute.listen((v) => settingsService.save('mute', v));

      _player.stream.playlistMode.listen((v) => settingsService.save('playlist_mode', v.name));
      _player.stream.shuffle.listen((v) => settingsService.save('shuffle', v));

      _player.stream.audioSampleRate.listen((v) => settingsService.save('audio-samplerate', v));
      _player.stream.audioFormat.listen((v) => settingsService.save('audio-format', v));
      _player.stream.audioChannels.listen((v) => settingsService.save('audio-channels', v));
      _player.stream.audioClientName.listen((v) => settingsService.save('audio-client-name', v));
      _player.stream.audioDevice.listen((v) => settingsService.save('audio-device', v.name));
      _player.stream.audioSpdif.listen((v) => settingsService.save('audio-spdif', v));
      _player.stream.audioExclusive.listen((v) => settingsService.save('audio-exclusive', v));
      _player.stream.audioBuffer.listen((v) => settingsService.save('audio-buffer', v));
      _player.stream.audioDelay.listen((v) => settingsService.save('audio-delay', v));

      _player.stream.gaplessMode.listen((v) => settingsService.save('gapless-audio', v));
      _player.stream.replayGainMode.listen((v) => settingsService.save('replaygain', v));
      _player.stream.replayGainPreamp.listen((v) => settingsService.save('replaygain-preamp', v));
      _player.stream.replayGainFallback.listen((v) => settingsService.save('replaygain-fallback', v));
      _player.stream.replayGainClip.listen((v) => settingsService.save('replaygain-clip', v));
      _player.stream.volumeGain.listen((v) => settingsService.save('volume-gain', v));
      _player.stream.pitchCorrection.listen((v) => settingsService.save('pitch-correction', v));

      _player.stream.cacheMode.listen((v) => settingsService.save('cache', v));
      _player.stream.cacheSecs.listen((v) => settingsService.save('cache-secs', v));
      _player.stream.cacheOnDisk.listen((v) => settingsService.save('cache-on-disk', v));
      _player.stream.cachePause.listen((v) => settingsService.save('cache-pause', v));
      _player.stream.cachePauseWait.listen((v) => settingsService.save('cache-pause-wait', v));
      _player.stream.demuxerMaxBytes.listen((v) => settingsService.save('demuxer-max-bytes', v));
      _player.stream.demuxerReadaheadSecs.listen((v) => settingsService.save('demuxer-readahead-secs', v));
      _player.stream.demuxerMaxBackBytes.listen((v) => settingsService.save('demuxer-max-back-bytes', v));

      _player.stream.networkTimeout.listen((v) => settingsService.save('network-timeout', v));
      _player.stream.tlsVerify.listen((v) => settingsService.save('tls-verify', v));
      _player.stream.streamSilence.listen((v) => settingsService.save('stream-silence', v));
      _player.stream.aoNullUntimed.listen((v) => settingsService.save('ao-null-untimed', v));
      _player.stream.audioTrack.listen((v) => settingsService.save('aid', v));
      _player.stream.equalizerGains.listen((v) => settingsService.save('equalizer_gains', v));

      _player.stream.log.listen((line) {
        if (mounted) {
          setState(() {
            _logs.add(line);
            if (_logs.length > 500) {
              _logs.removeAt(0);
            }
          });
        }
      });
      _player.stream.playing.listen((p) {
        debugPrint('[player] playing → $p');
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final showPinned = _isConsolePinned && isWide;

            final List<Widget> mainPages = [
              PlaybackTab(player: _player),
              QueueTab(player: _player),
              SettingsPage(player: _player),
            ];

            if (!showPinned) {
              mainPages.add(
                LogsTab(
                  player: _player,
                  logs: List.from(_logs),
                  isPinned: false,
                  onClearLogs: () => setState(() => _logs.clear()),
                  onTogglePin: () => _handleTogglePin(true),
                ),
              );
            }

            final safeIndex = _navIndex.clamp(0, mainPages.length - 1);
            Widget content = Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 650),
                      child: IndexedStack(
                        index: safeIndex,
                        children: mainPages,
                      ),
                    ),
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
                        player: _player,
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
