import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../../shared/property_cards.dart';

/// Hook Lab — recipe-based playground for [Player.registerHook].
///
/// Each recipe is a real-world interception pattern: auth-header
/// injection, protocol fallback on TLS failure, forced track selection,
/// or a passive lifecycle trace. Toggling a recipe registers the hooks
/// it needs (mpv has no public hook-unregister, so the registration
/// persists for the [Player] lifetime — disabling a recipe just makes
/// its handler a no-op). The activity log below shows every fire,
/// labelled by the recipes that acted on it.
class HooksPage extends StatefulWidget {
  final Player player;
  const HooksPage({super.key, required this.player});

  @override
  State<HooksPage> createState() => _HooksPageState();
}

enum _Recipe { headers, fallback, pickAudio, trace }

class _RecipeSpec {
  final String title;
  final String description;
  final String? mpvProperty;
  final IconData icon;
  final Set<Hook> hooks;
  const _RecipeSpec({
    required this.title,
    required this.description,
    required this.icon,
    required this.hooks,
    this.mpvProperty,
  });
}

const _recipeSpecs = <_Recipe, _RecipeSpec>{
  _Recipe.headers: _RecipeSpec(
    title: 'Inject HTTP Headers',
    description:
        'Adds Authorization + User-Agent headers on every http(s) stream. '
        'Skipped on local files. The headers are scoped per file via '
        'file-local-options, so they apply only to the loading track.',
    mpvProperty: 'file-local-options/http-header-fields',
    icon: Icons.vpn_key_rounded,
    hooks: {Hook.load},
  ),
  _Recipe.fallback: _RecipeSpec(
    title: 'HTTPS → HTTP Fallback',
    description:
        'When a TLS handshake fails, rewrites the URL to plain http and mpv '
        'automatically retries the open. Skipped if the URL is not https.',
    mpvProperty: 'stream-open-filename',
    icon: Icons.swap_horiz_rounded,
    hooks: {Hook.loadFail},
  ),
  _Recipe.pickAudio: _RecipeSpec(
    title: 'Force First Audio Track',
    description:
        'Right before decoder init, sets aid=1 — overriding the container\'s '
        'default-flag. Useful when the muxer\'s default pick is the wrong '
        'language on a multi-track file.',
    mpvProperty: 'aid',
    icon: Icons.audiotrack_rounded,
    hooks: {Hook.preloaded},
  ),
  _Recipe.trace: _RecipeSpec(
    title: 'Lifecycle Trace',
    description:
        'Passive observer — registers every phase and only logs. Useful to '
        'see the firing order: before_start_file → load → preloaded → unload '
        '→ after_end_file (with load_fail replacing preloaded on errors).',
    icon: Icons.timeline_rounded,
    hooks: {
      Hook.beforeStartFile,
      Hook.load,
      Hook.loadFail,
      Hook.preloaded,
      Hook.unload,
      Hook.afterEndFile,
    },
  ),
};

class _RecipeAction {
  final _Recipe recipe;
  final String label;
  final String? detail;
  const _RecipeAction(this.recipe, this.label, this.detail);
}

class _LogEntry {
  final DateTime timestamp;
  final Hook hook;
  final int id;
  final String url;
  final List<_RecipeAction> actions;
  const _LogEntry({
    required this.timestamp,
    required this.hook,
    required this.id,
    required this.url,
    required this.actions,
  });
}

class _HooksPageState extends State<HooksPage> {
  final Set<_Recipe> _enabled = {};
  final List<_LogEntry> _log = [];
  StreamSubscription<MpvHookEvent>? _hookSub;

  Player get player => widget.player;

  Set<Hook> get _registeredHooks => {
        for (final r in _enabled) ..._recipeSpecs[r]!.hooks,
      };

  @override
  void dispose() {
    _hookSub?.cancel();
    super.dispose();
  }

  void _toggleRecipe(_Recipe r, bool enable) {
    setState(() {
      enable ? _enabled.add(r) : _enabled.remove(r);
    });
    if (enable) {
      // Idempotent on the wrapper side — registering the same hook twice
      // is a no-op. The 5 s timeout is a safety net in case our handler
      // throws or is somehow skipped.
      for (final h in _recipeSpecs[r]!.hooks) {
        player.registerHook(h, timeout: const Duration(seconds: 5));
      }
      _hookSub ??= player.stream.hook.listen(_handleHook);
    } else if (_enabled.isEmpty) {
      _hookSub?.cancel();
      _hookSub = null;
      // mpv has no public hook-unregister — the registrations persist on
      // the wrapper side. Future fires arrive, find no active recipe,
      // and continue immediately via [_handleHook].
    }
  }

  Future<void> _handleHook(MpvHookEvent event) async {
    final url = await player.getRawProperty('stream-open-filename') ?? '';
    final actions = <_RecipeAction>[];

    // Run every active recipe whose hooks include this event. Order is
    // recipe-declaration order, which mirrors the UI list.
    for (final r in _Recipe.values) {
      if (!_enabled.contains(r)) continue;
      if (!_recipeSpecs[r]!.hooks.contains(event.hook)) continue;
      final a = await _runRecipe(r, event, url);
      if (a != null) actions.add(a);
    }

    if (mounted) {
      setState(() {
        _log.insert(
          0,
          _LogEntry(
            timestamp: DateTime.now(),
            hook: event.hook,
            id: event.id,
            url: url,
            actions: actions,
          ),
        );
        if (_log.length > 30) _log.removeRange(30, _log.length);
      });
    }
    // Always continue, even when no recipe acted — registrations persist
    // after a recipe is disabled, so we must close the hook ourselves.
    player.continueHook(event.id);
  }

  Future<_RecipeAction?> _runRecipe(
    _Recipe r,
    MpvHookEvent event,
    String url,
  ) async {
    switch (r) {
      case _Recipe.headers:
        if (!url.startsWith('http')) {
          return const _RecipeAction(
            _Recipe.headers,
            'skipped',
            'non-network URL',
          );
        }
        const headers =
            'Authorization: Bearer demo-token,'
            'User-Agent: mpv_audio_kit_example/1.0';
        await player.setRawProperty(
          'file-local-options/http-header-fields',
          headers,
        );
        return const _RecipeAction(
          _Recipe.headers,
          'injected headers',
          headers,
        );
      case _Recipe.fallback:
        if (!url.startsWith('https://')) {
          return const _RecipeAction(
            _Recipe.fallback,
            'skipped',
            'URL is not https',
          );
        }
        final downgraded = url.replaceFirst('https://', 'http://');
        await player.setRawProperty('stream-open-filename', downgraded);
        return _RecipeAction(
          _Recipe.fallback,
          'rewrote to http',
          '$url\n→ $downgraded',
        );
      case _Recipe.pickAudio:
        // mpv treats aid=1 as "first audio track regardless of the
        // default-flag set by the muxer". For multi-language files
        // where the container default is the wrong track this is a
        // one-line override.
        await player.setRawProperty('aid', '1');
        return const _RecipeAction(_Recipe.pickAudio, 'forced aid=1', null);
      case _Recipe.trace:
        return const _RecipeAction(_Recipe.trace, 'observed', null);
    }
  }

  void _clearLog() => setState(() => _log.clear());

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final registered = _registeredHooks;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _IntroBanner(
          enabledCount: _enabled.length,
          registeredCount: registered.length,
        ),
        const PropertySectionHeader(title: 'Recipes'),
        for (final r in _Recipe.values)
          _RecipeCard(
            spec: _recipeSpecs[r]!,
            enabled: _enabled.contains(r),
            onToggle: (v) => _toggleRecipe(r, v),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              const Expanded(child: PropertySectionHeader(title: 'Activity')),
              if (_log.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearLog,
                  icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                  label: const Text('Clear'),
                ),
            ],
          ),
        ),
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
                    _enabled.isEmpty
                        ? 'Enable a recipe above, then play a track to see hooks fire.'
                        : 'Waiting for the next file load…',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          for (final entry in _log) _LogTile(entry: entry),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _IntroBanner extends StatelessWidget {
  final int enabledCount;
  final int registeredCount;
  const _IntroBanner({
    required this.enabledCount,
    required this.registeredCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.tips_and_updates_rounded, color: cs.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hooks intercept mpv\'s file lifecycle',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$enabledCount recipe(s) active · $registeredCount of 6 phases registered',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final _RecipeSpec spec;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  const _RecipeCard({
    required this.spec,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: enabled
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    spec.icon,
                    size: 20,
                    color: enabled ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    spec.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Switch(value: enabled, onChanged: onToggle),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final h in spec.hooks)
                  _HookChip(hook: h, active: enabled),
                if (spec.mpvProperty != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.6),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '→ ${spec.mpvProperty}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              spec.description,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HookChip extends StatelessWidget {
  final Hook hook;
  final bool active;
  const _HookChip({required this.hook, required this.active});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? cs.primary.withValues(alpha: 0.14)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        hook.mpvName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          color: active ? cs.primary : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final _LogEntry entry;
  const _LogTile({required this.entry});

  (Color, Color) _hookColors(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (entry.hook) {
      Hook.beforeStartFile => (Colors.blueGrey, Colors.white),
      Hook.load => (cs.primary, cs.onPrimary),
      Hook.loadFail => (Colors.redAccent, Colors.white),
      Hook.preloaded => (Colors.tealAccent.shade700, Colors.white),
      Hook.unload => (Colors.deepOrangeAccent, Colors.white),
      Hook.afterEndFile => (Colors.purpleAccent, Colors.white),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = entry.timestamp;
    final timeStr = '${ts.hour.toString().padLeft(2, '0')}:'
        '${ts.minute.toString().padLeft(2, '0')}:'
        '${ts.second.toString().padLeft(2, '0')}.'
        '${ts.millisecond.toString().padLeft(3, '0')}';
    final (badgeBg, badgeFg) = _hookColors(context);

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.hook.mpvName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: badgeFg,
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
                    fontFamily: 'monospace',
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            if (entry.url.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                entry.url,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: cs.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (entry.actions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '(no recipe acted — auto-continued)',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              )
            else
              for (final a in entry.actions) _ActionRow(action: a),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final _RecipeAction action;
  const _ActionRow({required this.action});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spec = _recipeSpecs[action.recipe]!;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(spec.icon, size: 14, color: cs.primary),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  spec.title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  action.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (action.detail != null && action.detail!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 2),
              child: Text(
                action.detail!,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
