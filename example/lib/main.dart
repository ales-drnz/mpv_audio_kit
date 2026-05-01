import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/uri_resolver_flutter.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'player_page.dart';
import 'services/audio_handler.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1000, 800),
      minimumSize: Size(400, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  MpvAudioKit.ensureInitialized();
  // Example for custom libmpv path:
  // MpvAudioKit.ensureInitialized(libmpv: '/path/to/libmpv.so');
  final settingsService = await SettingsService.init();

  final player = Player(
    configuration: const PlayerConfiguration(
      initialVolume: 50.0,
      autoPlay: true,
      logLevel: 'debug',
      // Wire the Flutter-aware URI resolver: translates `asset://`
      // bundle paths via rootBundle and `content://` Android intent
      // URIs via the platform channel. Pure Dart consumers (and the
      // package's own runtime tests) leave this null.
      uriResolver: FlutterUriResolver.normalizeUri,
    ),
  );

  final audioHandler = await AudioService.init(
    builder: () => MpvAudioHandler(player),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.alesdrnz.mpvaudiokit.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: false,
      androidStopForegroundOnPause: true,
      notificationColor: AppTheme.notificationColor,
    ),
  );

  await settingsService.wire(player);

  runApp(MyApp(
    player: player,
    audioHandler: audioHandler,
    settingsService: settingsService,
  ));
}

class MyApp extends StatelessWidget {
  final Player player;
  final MpvAudioHandler audioHandler;
  final SettingsService settingsService;

  const MyApp({
    super.key,
    required this.player,
    required this.audioHandler,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mpv_audio_kit',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppTheme.scrollBehavior,
      theme: AppTheme.light,
      home: ExcludeSemantics(
        child: PlayerPage(
          player: player,
          audioHandler: audioHandler,
          settingsService: settingsService,
        ),
      ),
    );
  }
}
