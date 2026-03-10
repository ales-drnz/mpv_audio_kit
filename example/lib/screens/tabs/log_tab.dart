import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LogTab extends StatefulWidget {
  final List<String> logs;

  const LogTab({super.key, required this.logs});

  @override
  State<LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<LogTab> {
  String _filter = 'all'; // 'all' | 'warn' | 'error'
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<String> get _filteredLogs {
    return widget.logs.where((l) {
      if (_filter == 'warn') return l.toLowerCase().contains('warn');
      if (_filter == 'error') {
        return l.toLowerCase().contains('error') ||
            l.toLowerCase().contains('fatal');
      }
      return true;
    }).toList();
  }

  Color _lineColor(String line) {
    if (line.contains('error') || line.contains('fatal')) {
      return const Color(0xFFEF5350);
    }
    if (line.contains('warn')) return const Color(0xFFFFA726);
    if (line.contains('Set property:') || line.contains('Run command:')) {
      return const Color(0xFFCE93D8);
    }
    return const Color(0xFF81C784);
  }

  void _copyLogs() {
    final text = _filteredLogs.join('\n');
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No logs to copy'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_filteredLogs.length} lines copied to clipboard',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLogs;

    return Container(
      color: const Color(0xFF0D0D0D),
      child: Column(
        children: [
          // ── toolbar ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
            ),
            child: Row(
              children: [
                // Filter chips
                _FilterChip(
                  label: 'All',
                  count: widget.logs.length,
                  selected: _filter == 'all',
                  color: const Color(0xFF81C784),
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Warn',
                  count: widget.logs
                      .where((l) => l.toLowerCase().contains('warn'))
                      .length,
                  selected: _filter == 'warn',
                  color: const Color(0xFFFFA726),
                  onTap: () => setState(() => _filter = 'warn'),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Error',
                  count: widget.logs
                      .where(
                        (l) =>
                            l.toLowerCase().contains('error') ||
                            l.toLowerCase().contains('fatal'),
                      )
                      .length,
                  selected: _filter == 'error',
                  color: const Color(0xFFEF5350),
                  onTap: () => setState(() => _filter = 'error'),
                ),
                const Spacer(),
                // Copy button
                IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: Colors.white54),
                  tooltip: 'Copy filtered logs',
                  onPressed: _copyLogs,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                const SizedBox(width: 4),
                // Clear badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${filtered.length} lines',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white38,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── log list ─────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No logs yet',
                      style: TextStyle(color: Colors.white30, fontSize: 13),
                    ),
                  )
                : SelectionArea(
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final line = filtered[filtered.length - 1 - i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 1),
                          child: Text(
                            line,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontFamily: 'monospace',
                              color: _lineColor(line),
                              height: 1.4,
                            ),
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
}

// ── Small filter chip ────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.white.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? color : Colors.white38,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? color.withOpacity(0.25) : Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9,
                    color: selected ? color : Colors.white38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
