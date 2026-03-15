import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'tabs/audio_engine_tab.dart';
import 'tabs/demux_cache_tab.dart';
import 'tabs/routing_tab.dart';
import 'tabs/stream_lab_tab.dart';
import 'tabs/system_infra_tab.dart';

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

class _SettingsHome extends StatelessWidget {
  final Player player;
  final Function(String, WidgetBuilder) onNavigate;

  const _SettingsHome({required this.player, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.tune_rounded,
            title: 'Audio Engine',
            subtitle: 'DSP, Equalizer, Gain & Pitch',
            builder: (_) => AudioEngineTab(player: player),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.router_rounded,
            title: 'Routing & Hardware',
            subtitle: 'Drivers, Devices & Output Format',
            builder: (_) => RoutingTab(player: player),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.rss_feed_rounded,
            title: 'Stream Lab',
            subtitle: 'Network Streams & Radio',
            builder: (_) => StreamLabTab(player: player),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.speed_rounded,
            title: 'Demuxer & Cache',
            subtitle: 'Buffering, Prefetch & Memory Pool',
            builder: (_) => DemuxCacheTab(player: player),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.settings_suggest_rounded,
            title: 'System & Infra',
            subtitle: 'Audio Buffer, Exclusive Mode & Logs',
            builder: (_) => SystemInfraTab(player: player),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required WidgetBuilder builder,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => onNavigate(title, builder),
    );
  }
}
