import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../shared/property_cards.dart';

/// Hook Lab — demonstrates the [Player.registerHook] / [Player.continueHook]
/// API by intercepting mpv's `on_load` event and logging each invocation.
///
/// The "Echo" mode is the safest demo: it logs the hook event, immediately
/// continues, and never modifies the URL. Toggle the "Rewrite" mode to
/// upper-case the `stream-open-filename` for `file://` URLs (a no-op for
/// http schemes — just demonstrates the rewrite-then-continue path).
class HooksPage extends StatefulWidget {
  final Player player;
  const HooksPage({super.key, required this.player});

  @override
  State<HooksPage> createState() => _HooksPageState();
}

class _HooksPageState extends State<HooksPage> {
  bool _hookActive = false;
  bool _rewriteMode = false;
  final List<_HookLogEntry> _log = [];
  StreamSubscription<MpvHookEvent>? _hookSub;

  Player get player => widget.player;

  @override
  void dispose() {
    _hookSub?.cancel();
    super.dispose();
  }

  void _toggleHook(bool enable) {
    if (enable) {
      // The 5-second timeout is a safety net: if our handler errors or
      // forgets to call continueHook, mpv won't stall indefinitely.
      player.registerHook('on_load', timeout: const Duration(seconds: 5));
      _hookSub = player.stream.hook.listen(_handleHook);
    } else {
      _hookSub?.cancel();
      _hookSub = null;
      // Note: mpv has no public hook-unregister; the dispatch keeps
      // running on the wrapper side but we stop reacting and let any
      // future fires auto-continue via the timeout above.
    }
    setState(() => _hookActive = enable);
  }

  Future<void> _handleHook(MpvHookEvent event) async {
    if (event.name != 'on_load') return;
    final originalUrl =
        await player.getRawProperty('stream-open-filename') ?? '';
    String? rewrittenUrl;
    if (_rewriteMode && originalUrl.startsWith('file://')) {
      rewrittenUrl = originalUrl.toUpperCase();
      await player.setRawProperty('stream-open-filename', rewrittenUrl);
    }
    if (mounted) {
      setState(() {
        _log.insert(
          0,
          _HookLogEntry(
            name: event.name,
            id: event.id,
            url: originalUrl,
            rewrittenUrl: rewrittenUrl,
            timestamp: DateTime.now(),
          ),
        );
        if (_log.length > 20) _log.removeRange(20, _log.length);
      });
    }
    player.continueHook(event.id);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Hook Registration'),

        TogglePropertyCard(
          title: 'Listen on `on_load`',
          subtitle: 'mpv_hook_add(on_load)',
          icon: Icons.cable_rounded,
          value: _hookActive,
          onChanged: _toggleHook,
        ),

        TogglePropertyCard(
          title: 'Rewrite file:// URLs',
          subtitle: 'stream-open-filename (rewrite on hook)',
          icon: Icons.text_fields_rounded,
          value: _rewriteMode,
          onChanged: (v) => setState(() => _rewriteMode = v),
        ),

        const PropertySectionHeader(title: 'Hook Activity'),

        if (_log.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.hourglass_empty_rounded,
                    size: 48,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _hookActive
                        ? 'Waiting for the next file load…'
                        : 'Enable the hook above to start capturing events',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          for (final entry in _log) _HookLogTile(entry: entry),

        const SizedBox(height: 16),
      ],
    );
  }
}

class _HookLogEntry {
  final String name;
  final int id;
  final String url;
  final String? rewrittenUrl;
  final DateTime timestamp;

  const _HookLogEntry({
    required this.name,
    required this.id,
    required this.url,
    required this.rewrittenUrl,
    required this.timestamp,
  });
}

class _HookLogTile extends StatelessWidget {
  final _HookLogEntry entry;
  const _HookLogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = entry.timestamp;
    final timeStr =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: cs.onPrimary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'id=${entry.id}',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              entry.url.isEmpty ? '(empty stream-open-filename)' : entry.url,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: cs.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (entry.rewrittenUrl != null) ...[
              const SizedBox(height: 2),
              Text(
                '→ ${entry.rewrittenUrl}',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
