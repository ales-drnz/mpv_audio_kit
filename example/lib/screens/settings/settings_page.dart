import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'widgets/settings_home.dart';

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
          builder: (context) => SettingsHome(
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
