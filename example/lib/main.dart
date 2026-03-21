import 'dart:io';
import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/player_page.dart';
import 'services/audio_handler.dart';
import 'services/settings_service.dart';

late final SettingsService settingsService;
late final Player player;
late final MpvAudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(450, 850),
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
  settingsService = await SettingsService.init();

  player = Player(
    configuration: const PlayerConfiguration(
      initialVolume: 50.0,
      autoPlay: true,
      logLevel: 'debug',
    ),
  );

  audioHandler = await AudioService.init(
    builder: () => MpvAudioHandler(player),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.alesdrnz.mpvaudiokit.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: false,
      androidStopForegroundOnPause: true,
      notificationColor: Color(0xFF6366f1),
    ),
  );

  await settingsService.restore(player);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mpv_audio_kit',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const CustomScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366f1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ExcludeSemantics(child: PlayerPage()),
    );
  }
}

class CustomScrollBehavior extends MaterialScrollBehavior {
  const CustomScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
