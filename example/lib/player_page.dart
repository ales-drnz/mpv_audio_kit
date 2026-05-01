import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'player/playback_tab.dart';
import 'player/queue_tab.dart';
import 'player/logs_tab.dart';
import 'settings/settings_page.dart';
import 'settings/pages/stream_lab_page.dart';
import 'services/audio_handler.dart';
import 'services/settings_service.dart';
import 'theme/app_metrics.dart';

class PlayerPage extends StatefulWidget {
  final Player player;
  final MpvAudioHandler audioHandler;
  final SettingsService settingsService;

  const PlayerPage({
    super.key,
    required this.player,
    required this.audioHandler,
    required this.settingsService,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  String? _error;
  final List<String> _logs = [];
  bool _isConsolePinned =
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  int _navIndex = 0;

  // Aggregate of every persistence / log subscription opened in
  // [initState]. Cancelled wholesale in [dispose] to keep the page free
  // of leaked listeners on hot-reload, navigation, or rebuild.
  final List<StreamSubscription<dynamic>> _subs = [];

  void _pushLog(String line) {
    if (!mounted) return;
    setState(() {
      _logs.add(line);
      if (_logs.length > 500) {
        _logs.removeAt(0);
      }
    });
  }

  void _handleAppendLog(String message) {
    _pushLog('[mpv_audio_kit] info: $message');
  }

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
      // Persistence is fully owned by SettingsService — see `wire()` in
      // main.dart. Here we only subscribe to event streams that are not
      // settings: log routing, typed error → SnackBar, debug print.
      _subs.addAll([
        widget.player.stream.log.listen((line) => _pushLog(line.toString())),
        widget.player.stream.internalLog.listen((line) => _pushLog(line.toString())),
        widget.player.stream.playing.listen((p) {
          debugPrint('[player] playing → $p');
        }),
        // Surface typed errors as a transient SnackBar lifted above the
        // in-body NavigationBar (and the pinned console sidebar in
        // desktop wide mode).
        widget.player.stream.error.listen((err) {
          if (!mounted) return;
          final (label, detail) = switch (err) {
            MpvEndFileError(:final reason, :final message) => (
                'Playback error: ${reason.name}',
                message,
              ),
            MpvLogError(:final prefix, :final text) => (
                '[$prefix] error',
                text,
              ),
          };
          _showFloatingSnack(
            Text(detail.isEmpty ? label : '$label — $detail'),
            const Duration(seconds: 4),
            background: Theme.of(context).colorScheme.errorContainer,
          );
        }),
        // endFile fires for every file-end (clean EOF, stop, error). We
        // surface only premature ends — clean completions auto-advance
        // via the playlist and don't need a UI hint.
        widget.player.stream.endFile.listen((event) {
          if (!mounted) return;
          if (event.reachedNaturalEnd) return;
          _showFloatingSnack(
            Text('Track ended early: ${event.reason.name}'),
            const Duration(seconds: 2),
          );
        }),
      ]);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  /// Shows a floating SnackBar lifted above the in-body NavigationBar
  /// and (when present) the pinned console sidebar. The right margin
  /// is calculated dynamically: when the layout is wide AND the
  /// console is pinned, push the snack inside the content column so
  /// it doesn't appear over the log console.
  void _showFloatingSnack(
    Widget content,
    Duration duration, {
    Color? background,
  }) {
    final width = MediaQuery.of(context).size.width;
    final showPinned = _isConsolePinned && width >= AppMetrics.wideLayoutThreshold;
    // 16 px breathing room from the side edge; +console width when the
    // console occupies the right portion of the screen.
    final rightMargin = showPinned ? AppMetrics.consolePinnedWidth + 16 : 16.0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: background,
        margin: EdgeInsets.fromLTRB(16, 0, rightMargin, AppMetrics.navBarLift),
      ),
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
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
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final showPinned = _isConsolePinned && isWide;

            // Pages that respect the 650px constraint
            // Nav: 0=Player, 1=Queue, 2=Stream, 3=Settings, 4=Logs(optional)
            final constrainedPages = <Widget>[
              PlaybackTab(
                player: widget.player,
                audioHandler: widget.audioHandler,
              ),
              QueueTab(player: widget.player),
              StreamLabPage(player: widget.player),
              if (!showPinned)
                LogsTab(
                  player: widget.player,
                  logs: List.from(_logs),
                  isPinned: false,
                  onClearLogs: () => setState(() => _logs.clear()),
                  onTogglePin: () => _handleTogglePin(true),
                  onAppendLog: _handleAppendLog,
                ),
            ];

            final totalNav = showPinned ? 4 : 5;
            final safeIndex = _navIndex.clamp(0, totalNav - 1);
            final isSettings = safeIndex == 3;
            // Constrained IndexedStack skips the settings slot (index 3)
            final constrainedIndex =
                (safeIndex >= 4 ? safeIndex - 1 : safeIndex).clamp(
                  0,
                  constrainedPages.length - 1,
                );

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
                        child: SettingsPage(player: widget.player),
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
                        player: widget.player,
                        logs: List.from(_logs),
                        isPinned: true,
                        onClearLogs: () => setState(() => _logs.clear()),
                        onTogglePin: () => _handleTogglePin(false),
                        onAppendLog: _handleAppendLog,
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
