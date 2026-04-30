import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/property_cards.dart';

enum LogFilter { all, manual, error, warn, info, debug }

class LogsTab extends StatefulWidget {
  final Player player;
  final List<String> logs;
  final VoidCallback onClearLogs;
  final bool isPinned;
  final VoidCallback onTogglePin;
  final void Function(String message) onAppendLog;

  const LogsTab({
    super.key,
    required this.player,
    required this.logs,
    required this.onClearLogs,
    required this.isPinned,
    required this.onTogglePin,
    required this.onAppendLog,
  });

  @override
  State<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<LogsTab> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  LogFilter _selectedFilter = LogFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  void didUpdateWidget(LogsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll if a new log was added
    if (widget.logs.length > oldWidget.logs.length) {
      _scrollToBottom();
    }
  }

  List<String> get _filteredLogs {
    if (_selectedFilter == LogFilter.all) {
      return widget.logs;
    }
    return widget.logs.where((log) {
      switch (_selectedFilter) {
        case LogFilter.manual:
          return log.contains('[mpv_audio_kit]') ||
              log.contains('Set property:');
        case LogFilter.error:
          return log.contains(' fatal: ') || log.contains(' error: ');
        case LogFilter.warn:
          return log.contains(' warn: ');
        case LogFilter.info:
          return log.contains(' info: ');
        case LogFilter.debug:
          final isManual =
              log.contains('[mpv_audio_kit]') || log.contains('Set property:');
          return !isManual &&
              (log.contains(' debug: ') ||
                  log.contains(' v: ') ||
                  log.contains(' trace: '));
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _sendCommand(String cmd) async {
    if (cmd.contains('=')) {
      final parts = cmd.split('=');
      await widget.player.setRawProperty(parts[0].trim(), parts[1].trim());
    } else {
      await widget.player.sendRawCommand(cmd.split(' '));
    }
  }

  Future<void> _requestHelp(String type) async {
    switch (type) {
      case 'filters':
        widget.onAppendLog(
          'Requesting audio filters help (check console if not below)...',
        );
        await widget.player.setRawProperty('af', 'help');
        break;
      case 'drivers':
        widget.onAppendLog(
          'Requesting available Audio Output drivers via mpv help...',
        );
        await widget.player.setRawProperty('ao', 'help');
        break;
      case 'devices':
        final devices = widget.player.state.audioDevices;
        widget.onAppendLog('Detected Audio Devices (from audio-device-list):');
        for (final d in devices) {
          widget.onAppendLog('  - "${d.name}" : ${d.description}');
        }
        break;
      case 'properties':
        final list = await widget.player.getRawProperty('property-list');
        if (list != null) {
          widget.onAppendLog('Common mpv Properties:');
          widget.onAppendLog('  ${list.replaceAll(',', ', ')}');
        }
        break;
      case 'commands':
        final list = await widget.player.getRawProperty('command-list');
        if (list != null) {
          widget.onAppendLog('Available mpv Commands:');
          widget.onAppendLog('  ${list.replaceAll(',', ', ')}');
        }
        break;
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _copyLogs() {
    final text = _filteredLogs.join('\n');
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Filtered logs copied to clipboard'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayLogs = _filteredLogs;

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PropertySectionHeader(title: 'Quick Diagnostic Commands'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _LogActionButton(
                      label: 'Filters',
                      icon: Icons.filter_list_rounded,
                      onPressed: () => _requestHelp('filters'),
                    ),
                    _LogActionButton(
                      label: 'Drivers',
                      icon: Icons.settings_input_component_rounded,
                      onPressed: () => _requestHelp('drivers'),
                    ),
                    _LogActionButton(
                      label: 'Devices',
                      icon: Icons.speaker_group_rounded,
                      onPressed: () => _requestHelp('devices'),
                    ),
                    _LogActionButton(
                      label: 'Properties',
                      icon: Icons.list_alt_rounded,
                      onPressed: () => _requestHelp('properties'),
                    ),
                    _LogActionButton(
                      label: 'Commands',
                      icon: Icons.terminal_rounded,
                      onPressed: () => _requestHelp('commands'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _commandController,
                  decoration: InputDecoration(
                    hintText: 'Enter mpv command (e.g. af=help)',
                    hintStyle: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(Icons.code_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send_rounded),
                      onPressed: () {
                        if (_commandController.text.isNotEmpty) {
                          unawaited(_sendCommand(_commandController.text));
                          _commandController.clear();
                        }
                      },
                    ),
                    filled: true,
                    fillColor: cs.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  onSubmitted: (val) {
                    if (val.isNotEmpty) {
                      unawaited(_sendCommand(val));
                      _commandController.clear();
                    }
                  },
                ),
                const SizedBox(height: 16),
                _FilterBar(
                  selected: _selectedFilter,
                  onChanged: (f) => setState(() => _selectedFilter = f),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              color: Colors.black.withValues(alpha: 0.9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.terminal_rounded,
                          size: 16,
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'ENGINE OUTPUT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const Spacer(),
                        _LogTerminalAction(
                          icon: widget.isPinned
                              ? Icons.output_rounded
                              : Icons.dock_rounded,
                          onPressed: widget.onTogglePin,
                          tooltip: widget.isPinned
                              ? 'Unpin console'
                              : 'Pin console to side',
                        ),
                        const SizedBox(width: 8),
                        _LogTerminalAction(
                          icon: Icons.copy_all_rounded,
                          onPressed: _copyLogs,
                          tooltip: 'Copy current logs',
                        ),
                        const SizedBox(width: 8),
                        _LogTerminalAction(
                          icon: Icons.delete_sweep_rounded,
                          onPressed: widget.onClearLogs,
                          tooltip: 'Clear all logs',
                        ),
                        const SizedBox(width: 8),
                        _LogTerminalAction(
                          icon: Icons.arrow_downward_rounded,
                          onPressed: _scrollToBottom,
                          tooltip: 'Scroll to bottom',
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: displayLogs.length,
                      itemBuilder: (context, index) {
                        final log = displayLogs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            log,
                            style: TextStyle(
                              color: _getLogColor(log),
                              fontFamily: 'monospace',
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains(' fatal: ') || log.contains(' error: ')) {
      return Colors.redAccent.withValues(alpha: 0.9);
    }
    if (log.contains(' warn: ')) {
      return Colors.orangeAccent.withValues(alpha: 0.9);
    }
    if (log.contains('[mpv_audio_kit]') || log.contains('Set property:')) {
      return const Color(0xFFFF00FF);
    }
    if (log.contains(' info: ')) {
      return Colors.cyanAccent.withValues(alpha: 0.8);
    }
    if (log.contains(' debug: ') ||
        log.contains(' v: ') ||
        log.contains(' trace: ')) {
      return Colors.greenAccent.withValues(alpha: 0.7);
    }
    return Colors.white38;
  }
}

class _FilterBar extends StatelessWidget {
  final LogFilter selected;
  final ValueChanged<LogFilter> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  Color _getFilterColor(LogFilter filter) {
    switch (filter) {
      case LogFilter.all:
        return Colors.blueGrey;
      case LogFilter.manual:
        return const Color(0xFFFF00FF);
      case LogFilter.error:
        return Colors.redAccent;
      case LogFilter.warn:
        return Colors.orangeAccent;
      case LogFilter.info:
        return Colors.cyanAccent;
      case LogFilter.debug:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: LogFilter.values.map((filter) {
        final isSelected = selected == filter;
        final color = _getFilterColor(filter);

        return FilterChip(
          avatar: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          label: Text(
            filter.name.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? cs.onPrimaryContainer : null,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onChanged(filter),
          backgroundColor: cs.surfaceContainerLow,
          selectedColor: cs.primaryContainer,
          visualDensity: VisualDensity.compact,
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
        );
      }).toList(),
    );
  }
}

class _LogActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _LogActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(icon, size: 16, color: cs.primary),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
      backgroundColor: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}

class _LogTerminalAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _LogTerminalAction({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(icon, size: 16, color: Colors.white38),
          ),
        ),
      ),
    );
  }
}
