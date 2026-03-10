import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'tabs/playback_tab.dart';
import 'tabs/stream_lab_tab.dart';
import 'tabs/pitch_tab.dart';
import 'tabs/hardware_tab.dart';
import 'tabs/system_tab.dart';
import 'tabs/gain_tab.dart';
import 'tabs/dsp_tab.dart';
import 'tabs/network_tab.dart';
import 'tabs/log_tab.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final MpvPlayer _player;
  String? _error;
  final List<String> _logs = [];
  int _navIndex = 0;
  double _logWidth = 350.0;

  @override
  void initState() {
    super.initState();
    try {
      _player = MpvPlayer(
        config: const PlayerConfig(
          initialVolume: 50.0,
          autoPlay: true,
          logLevel: 'debug',
        ),
      );
      _player.logStream.listen((line) {
        setState(() {
          _logs.add(line);
          if (_logs.length > 200) _logs.removeAt(0);
        });
      });
      _player.stateStream.listen((s) {
        debugPrint('[player] state → $s');
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

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth > 700;

            // On wide screens, log tab is hidden from nav (shown as sidebar).
            // On narrow, log tab is the last nav destination.
            final List<Widget> pages = [
              PlaybackTab(player: _player),
              StreamLabTab(player: _player),
              PitchTab(player: _player),
              HardwareTab(player: _player),
              SystemTab(player: _player),
              GainTab(player: _player),
              DspTab(player: _player),
              NetworkTab(player: _player),
              if (!isWide) LogTab(logs: _logs),
            ];


            // Clamp navIndex in case we switch between wide/narrow
            final safeIndex = _navIndex.clamp(0, pages.length - 1);

            // ── Tab definitions ──────────────────────────────────────
            const row1 = [
              _NavTabItem(icon: Icons.music_note, label: 'Player'),
              _NavTabItem(icon: Icons.cell_tower, label: 'Streams'),
              _NavTabItem(icon: Icons.speed, label: 'Pitch'),
              _NavTabItem(icon: Icons.speaker, label: 'Routing'),
              _NavTabItem(icon: Icons.memory, label: 'System'),
            ];
            const row2Base = [
              _NavTabItem(icon: Icons.graphic_eq, label: 'Gain'),
              _NavTabItem(icon: Icons.filter_hdr, label: 'DSP'),
              _NavTabItem(icon: Icons.wifi, label: 'Network'),
            ];
            final row2 = isWide
                ? row2Base
                : [...row2Base, const _NavTabItem(icon: Icons.terminal, label: 'Log')];

            final allTabs = [...row1, ...row2];

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: pages[safeIndex]),
                      _TwoRowNavBar(
                        row1: row1,
                        row2: row2,
                        allTabs: allTabs,
                        selectedIndex: safeIndex,
                        onTabSelected: (i) => setState(() => _navIndex = i),
                      ),
                    ],
                  ),
                ),
                // Desktop sidebar log
                if (isWide) ...[
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _logWidth -= details.delta.dx;
                          _logWidth = _logWidth.clamp(200.0, 800.0);
                        });
                      },
                      child: Container(
                        width: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: Center(
                          child: Container(
                            width: 4,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildLogSection(),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogSection() {
    return Container(
      width: _logWidth,
      color: Colors.black87,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MPV ENGINE LOGS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.copy,
                      size: 14,
                      color: Colors.white70,
                    ),
                    tooltip: 'Copy all',
                    onPressed: () =>
                        _copyLogs((l) => true, 'All logs copied to clipboard'),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.warning,
                      size: 14,
                      color: Colors.orange,
                    ),
                    tooltip: 'Copy warnings only',
                    onPressed: () => _copyLogs(
                      (l) => l.toLowerCase().contains('warn'),
                      'Warnings copied to clipboard',
                    ),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    icon: const Icon(Icons.error, size: 14, color: Colors.red),
                    tooltip: 'Copy errors only',
                    onPressed: () => _copyLogs(
                      (l) =>
                          l.toLowerCase().contains('error') ||
                          l.toLowerCase().contains('fatal'),
                      'Errors copied to clipboard',
                    ),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: SelectionArea(
              child: ListView.builder(
                reverse: true,
                itemCount: _logs.length,
                itemBuilder: (_, i) {
                  final line = _logs[_logs.length - 1 - i];
                  final color = line.contains('error') || line.contains('fatal')
                      ? Colors.red[300]
                      : line.contains('warn')
                      ? Colors.orange[300]
                      : line.contains('Set property:') ||
                            line.contains('Run command:')
                      ? Colors.purpleAccent[100]
                      : Colors.green[300];
                  return Text(
                    line,
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: color ?? Colors.grey[300],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyLogs(bool Function(String) filter, String successMessage) {
    final filtered = _logs.where(filter).join('\n');
    if (filtered.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: filtered));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No logs to copy',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

// ── Data class for a single nav tab ─────────────────────────────────────────
class _NavTabItem {
  final IconData icon;
  final String label;
  const _NavTabItem({required this.icon, required this.label});
}

// ── Two-row bottom navigation bar ────────────────────────────────────────────
class _TwoRowNavBar extends StatelessWidget {
  final List<_NavTabItem> row1;
  final List<_NavTabItem> row2;
  final List<_NavTabItem> allTabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _TwoRowNavBar({
    required this.row1,
    required this.row2,
    required this.allTabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final surface = cs.surfaceContainer;
    final divider = cs.outlineVariant.withOpacity(0.4);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: divider, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(context, row1, 0),
          Divider(height: 0.5, thickness: 0.5, color: divider),
          _buildRow(context, row2, row1.length),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    List<_NavTabItem> tabs,
    int offset,
  ) {
    return Row(
      children: tabs.asMap().entries.map((entry) {
        final i = entry.key + offset;
        final tab = entry.value;
        final selected = i == selectedIndex;
        return _NavTab(
          item: tab,
          selected: selected,
          onTap: () => onTabSelected(i),
        );
      }).toList(),
    );
  }
}

// ── Single tab item ───────────────────────────────────────────────────────────
class _NavTab extends StatelessWidget {
  final _NavTabItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : cs.onSurfaceVariant;
    final bg = selected ? cs.primary.withOpacity(0.12) : Colors.transparent;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            border: selected
                ? Border(bottom: BorderSide(color: cs.primary, width: 2))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 20, color: color),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w400,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
