import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../widgets/property_cards.dart';

class QueueTab extends StatefulWidget {
  final Player player;

  const QueueTab({super.key, required this.player});

  @override
  State<QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends State<QueueTab> {
  bool _picking = false;

  Player get player => widget.player;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Playlist>(
      stream: player.stream.playlist,
      initialData: player.state.playlist,
      builder: (context, snap) {
        final playlist = snap.data ?? const Playlist.empty();
        final list = playlist.medias;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Shuffle Property
            StreamBuilder<bool>(
              stream: player.stream.shuffle,
              initialData: player.state.shuffle,
              builder: (context, snap) {
                final isShuffle = snap.data ?? false;
                return TogglePropertyCard(
                  title: 'Shuffle Playback',
                  subtitle: 'shuffle=${isShuffle ? 'yes' : 'no'}',
                  icon: Icons.shuffle_rounded,
                  value: isShuffle,
                  onChanged: (v) => player.setShuffle(v),
                );
              },
            ),
            // Loop Property
            StreamBuilder<PlaylistMode>(
              stream: player.stream.playlistMode,
              initialData: player.state.playlistMode,
              builder: (context, snap) {
                final mode = snap.data ?? PlaylistMode.none;
                final (subtitle, icon) = switch (mode) {
                  PlaylistMode.none => (
                    'loop-playlist=no',
                    Icons.repeat_rounded,
                  ),
                  PlaylistMode.single => (
                    'loop-file=yes',
                    Icons.repeat_one_rounded,
                  ),
                  PlaylistMode.loop => (
                    'loop-playlist=yes',
                    Icons.repeat_rounded,
                  ),
                };
                return SegmentedPropertyCard<PlaylistMode>(
                  title: 'Repeat Mode',
                  subtitle: subtitle,
                  icon: icon,
                  value: mode,
                  segments: const [
                    (PlaylistMode.none, 'Off'),
                    (PlaylistMode.single, 'Single'),
                    (PlaylistMode.loop, 'All'),
                  ],
                  onChanged: player.setPlaylistMode,
                );
              },
            ),
            const SizedBox(height: 16),
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
                            final wasEmpty =
                                player.state.playlist.medias.isEmpty;
                            for (final file in result.files) {
                              final path = file.path;
                              if (path != null) {
                                await player.add(Media(path));
                              }
                            }
                            if (wasEmpty) {
                              player.play();
                            }
                          }
                        } finally {
                          if (mounted) setState(() => _picking = false);
                        }
                      },
                      icon: Icons.folder_open_rounded,
                      label: 'Add File',
                    ),
                    const SizedBox(width: 8),
                    if (list.isNotEmpty)
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
            if (list.isEmpty)
              Material(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.queue_music_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Queue is empty',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Material(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (context, i) => Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 20,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    itemBuilder: (context, i) {
                      final media = list[i];
                      final isCurrent = i == playlist.index;
                      final label =
                          (media.extras?['title'] as String?) ??
                          media.uri.split('/').last;
                      return ListTile(
                        onTap: () => player.jump(i),
                        contentPadding: const EdgeInsets.only(
                          left: 16,
                          right: 8,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isCurrent
                                ? Icons.play_arrow_rounded
                                : Icons.music_note_rounded,
                            color: isCurrent
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isCurrent
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: isCurrent
                            ? Text(
                                'Now Playing',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => player.remove(i),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
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
