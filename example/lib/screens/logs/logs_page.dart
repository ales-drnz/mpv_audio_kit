import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../shared/property_cards.dart';
import '../../shared/snack_messenger.dart';
import 'widgets/filter_bar.dart';
import 'widgets/log_action_button.dart';
import 'widgets/log_terminal_action.dart';

class LogsPage extends StatefulWidget {
  final Player player;
  final List<String> logs;
  final VoidCallback onClearLogs;
  final bool isPinned;
  final VoidCallback onTogglePin;
  final void Function(String message) onAppendLog;

  const LogsPage({
    super.key,
    required this.player,
    required this.logs,
    required this.onClearLogs,
    required this.isPinned,
    required this.onTogglePin,
    required this.onAppendLog,
  });

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  LogFilter _selectedFilter = LogFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  void didUpdateWidget(LogsPage oldWidget) {
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
        // `af=help` prints the filter list as a log side-effect then
        // rejects the assignment ("help" isn't a real filter chain) —
        // swallow the expected MpvException.
        try {
          await widget.player.setRawProperty('af', 'help');
        } on MpvException {/* expected */}
        break;
      case 'drivers':
        widget.onAppendLog(
          'Requesting available Audio Output drivers via mpv help...',
        );
        // Same idiom as `af=help`: prints the driver list, then mpv
        // refuses to set ao to "help".
        try {
          await widget.player.setRawProperty('ao', 'help');
        } on MpvException {/* expected */}
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
        showFloatingSnack(
          context,
          content: const Text('Filtered logs copied to clipboard'),
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
                    LogActionButton(
                      label: 'Filters',
                      icon: Icons.filter_list_rounded,
                      onPressed: () => _requestHelp('filters'),
                    ),
                    LogActionButton(
                      label: 'Drivers',
                      icon: Icons.settings_input_component_rounded,
                      onPressed: () => _requestHelp('drivers'),
                    ),
                    LogActionButton(
                      label: 'Devices',
                      icon: Icons.speaker_group_rounded,
                      onPressed: () => _requestHelp('devices'),
                    ),
                    LogActionButton(
                      label: 'Properties',
                      icon: Icons.list_alt_rounded,
                      onPressed: () => _requestHelp('properties'),
                    ),
                    LogActionButton(
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
                FilterBar(
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
                        LogTerminalAction(
                          icon: widget.isPinned
                              ? Icons.output_rounded
                              : Icons.dock_rounded,
                          onPressed: widget.onTogglePin,
                          tooltip: widget.isPinned
                              ? 'Unpin console'
                              : 'Pin console to side',
                        ),
                        const SizedBox(width: 8),
                        LogTerminalAction(
                          icon: Icons.copy_all_rounded,
                          onPressed: _copyLogs,
                          tooltip: 'Copy current logs',
                        ),
                        const SizedBox(width: 8),
                        LogTerminalAction(
                          icon: Icons.delete_sweep_rounded,
                          onPressed: widget.onClearLogs,
                          tooltip: 'Clear all logs',
                        ),
                        const SizedBox(width: 8),
                        LogTerminalAction(
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
