import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:window_manager/window_manager.dart';
import '../player/player_page.dart';
import '../queue/queue_page.dart';
import '../logs/logs_page.dart';
import '../stream/stream_page.dart';
import '../settings/settings_page.dart';
import '../../services/audio_handler.dart';
import '../../services/settings_service.dart';
import '../../shared/snack_messenger.dart';

class HomePage extends StatefulWidget {
  final Player player;
  final MpvAudioHandler audioHandler;
  final SettingsService settingsService;

  const HomePage({
    super.key,
    required this.player,
    required this.audioHandler,
    required this.settingsService,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    consolePinnedNotifier.value = pin;

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
    // Mirror the initial pinned-state to the global notifier so
    // floating SnackBars positioned from any navigation root (root
    // Navigator pushes from sub-pages, dialogs, …) compute the same
    // rightMargin we use here for the in-body layout.
    consolePinnedNotifier.value = _isConsolePinned;
    try {
      // Persistence is fully owned by SettingsService — see `wire()` in
      // main.dart. Here we only subscribe to event streams that are not
      // settings: log routing, typed error → SnackBar, debug print.
      _subs.addAll([
        widget.player.stream.log.listen((line) => _pushLog(line.toString())),
        widget.player.stream.internalLog.listen(
          (line) => _pushLog(line.toString()),
        ),
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
            // Fixed saturated red — `cs.error` flips to a light salmon
            // in dark theme (M3 tonal-palette inversion), which loses
            // contrast against the white foreground we need for the
            // snackbar's error semantic.
            background: Colors.red.shade700,
            foreground: Colors.white,
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

  /// Local shortcut over [showFloatingSnack] — keeps the call sites in
  /// this file terse. The pinned-console adjustment is handled by the
  /// `ConsolePinnedScope` wrapped around the body in [build].
  void _showFloatingSnack(
    Widget content,
    Duration duration, {
    Color? background,
    Color? foreground,
  }) =>
      showFloatingSnack(
        context,
        content: content,
        duration: duration,
        background: background,
        foreground: foreground,
      );

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
              PlayerPage(
                player: widget.player,
                audioHandler: widget.audioHandler,
              ),
              QueuePage(player: widget.player),
              StreamPage(player: widget.player),
              if (!showPinned)
                LogsPage(
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
                      child: LogsPage(
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
