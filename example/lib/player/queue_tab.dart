import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

class QueueTab extends StatefulWidget {
  final Player player;

  const QueueTab({super.key, required this.player});

  @override
  State<QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends State<QueueTab> {
  bool _picking = false;
  bool _dragging = false;

  // Local list — updated optimistically on reorder to avoid StreamBuilder flash.
  List<Media> _list = [];
  int _currentIndex = 0;
  bool _trackLoaded =
      false; // true when a track is actually loaded (playing or paused)
  StreamSubscription<Playlist>? _playlistSub;
  StreamSubscription<Duration>? _durationSub;

  Player get player => widget.player;

  bool get _isDesktop =>
      Theme.of(context).platform == TargetPlatform.macOS ||
      Theme.of(context).platform == TargetPlatform.windows ||
      Theme.of(context).platform == TargetPlatform.linux;

  @override
  void initState() {
    super.initState();
    _applyPlaylist(player.state.playlist);
    _playlistSub = player.stream.playlist.listen(_applyPlaylist);
    _trackLoaded = player.state.duration > Duration.zero;
    _durationSub = player.stream.duration.listen((d) {
      if (mounted) setState(() => _trackLoaded = d > Duration.zero);
    });
  }

  void _applyPlaylist(Playlist p) {
    if (mounted) {
      setState(() {
        _list = List.from(p.medias);
        _currentIndex = p.index;
      });
    }
  }

  @override
  void dispose() {
    _playlistSub?.cancel();
    _durationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Note: shuffle / repeat live next to the play/pause button
          // in the Player tab; prefetch lives in Settings → Network.
          // Live prefetch state is surfaced as a chip below the seek
          // slider in the Player tab.
          const SizedBox(height: 16),
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UP NEXT',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  _QueueActionButton(
                    onPressed: () async {
                      if (_picking) return;
                      setState(() => _picking = true);
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.any,
                          allowMultiple: true,
                        );
                        if (result != null) {
                          final wasEmpty = player.state.playlist.medias.isEmpty;
                          for (final file in result.files) {
                            final path = file.path;
                            if (path != null) await player.add(Media(path));
                          }
                          if (wasEmpty) player.play();
                        }
                      } finally {
                        if (mounted) setState(() => _picking = false);
                      }
                    },
                    icon: Icons.folder_open_rounded,
                    label: 'Add File',
                  ),
                  const SizedBox(width: 8),
                  if (_list.isNotEmpty)
                    _QueueActionButton(
                      onPressed: player.clearPlaylist,
                      icon: Icons.delete_outline_rounded,
                      label: 'Clear Queue',
                      isError: true,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Queue box
          Expanded(
            child: DropTarget(
              onDragEntered: (_) => setState(() => _dragging = true),
              onDragExited: (_) => setState(() => _dragging = false),
              onDragDone: (detail) async {
                setState(() => _dragging = false);
                final wasEmpty = player.state.playlist.medias.isEmpty;
                for (final file in detail.files) {
                  await player.add(Media(file.path));
                }
                if (wasEmpty && detail.files.isNotEmpty) player.play();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _dragging
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Material(
                  color: _dragging
                      ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: _list.isEmpty
                      ? _EmptyQueuePlaceholder(
                          isDragging: _dragging,
                          isDesktop: _isDesktop,
                        )
                      : ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          padding: EdgeInsets.zero,
                          // Remove the default elevation rectangle on the dragged item.
                          proxyDecorator: (child, index, animation) => child,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              final adjusted = newIndex > oldIndex
                                  ? newIndex - 1
                                  : newIndex;
                              final item = _list.removeAt(oldIndex);
                              _list.insert(adjusted, item);
                              // Keep _currentIndex pointing to the same track.
                              if (_currentIndex == oldIndex) {
                                _currentIndex = adjusted;
                              } else if (oldIndex < _currentIndex &&
                                  adjusted >= _currentIndex) {
                                _currentIndex--;
                              } else if (oldIndex > _currentIndex &&
                                  adjusted <= _currentIndex) {
                                _currentIndex++;
                              }
                            });
                            player.move(oldIndex, newIndex);
                          },
                          itemCount: _list.length,
                          itemBuilder: (context, i) {
                            final media = _list[i];
                            final isCurrent =
                                i == _currentIndex && _trackLoaded;
                            final cs = Theme.of(context).colorScheme;
                            final label =
                                (media.extras?['title'] as String?) ??
                                media.uri.split('/').last;

                            final isFirst = i == 0;
                            final isLast = i == _list.length - 1;
                            final radius = BorderRadius.vertical(
                              top: isFirst
                                  ? const Radius.circular(12)
                                  : Radius.zero,
                              bottom: isLast
                                  ? const Radius.circular(12)
                                  : Radius.zero,
                            );

                            return Card(
                              key: ValueKey(media.uri),
                              elevation: 0,
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: radius,
                              ),
                              color: isCurrent
                                  ? cs.primaryContainer.withValues(alpha: 0.5)
                                  : cs.surfaceContainerLow,
                              child: InkWell(
                                onTap: () => player.jump(i),
                                mouseCursor: SystemMouseCursors.click,
                                borderRadius: radius,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      // Drag handle
                                      ReorderableDragStartListener(
                                        index: i,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Icon(
                                            Icons.drag_handle_rounded,
                                            size: 18,
                                            color: cs.onSurfaceVariant
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Track icon
                                      // Track index in circle
                                      Container(
                                        width: 30,
                                        height: 30,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isCurrent
                                              ? cs.primary
                                              : cs.surfaceContainerHighest,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$i',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isCurrent
                                                ? cs.onPrimary
                                                : cs.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Title + optional "Now Playing" label
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isCurrent
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: isCurrent
                                                    ? cs.primary
                                                    : cs.onSurface,
                                              ),
                                            ),
                                            if (isCurrent)
                                              Text(
                                                'Now Playing',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: cs.primary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Remove
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                        ),
                                        color: cs.onSurfaceVariant,
                                        onPressed: () => player.remove(i),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyQueuePlaceholder extends StatelessWidget {
  final bool isDragging;
  final bool isDesktop;

  const _EmptyQueuePlaceholder({
    required this.isDragging,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isDragging ? cs.primary : cs.onSurfaceVariant;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDragging ? Icons.download_rounded : Icons.queue_music_rounded,
            size: 48,
            color: color,
          ),
          const SizedBox(height: 16),
          Text(
            isDragging ? 'Drop to add' : 'Queue is empty',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          if (isDesktop && !isDragging) ...[
            const SizedBox(height: 8),
            Text(
              'Drop files here or use Add File',
              style: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QueueActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isError;

  const _QueueActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ActionChip(
      onPressed: onPressed,
      avatar: Icon(icon, size: 16, color: isError ? cs.error : cs.primary),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isError ? cs.error : cs.onSurface,
        ),
      ),
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
