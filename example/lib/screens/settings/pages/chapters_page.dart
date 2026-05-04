import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../../shared/property_cards.dart';

class ChaptersPage extends StatelessWidget {
  final Player player;
  const ChaptersPage({super.key, required this.player});

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Chapter Navigation'),

        // Prev / Next chapter buttons. mpv accepts `chapter` writes that
        // clamp to the valid range, so the buttons stay enabled when no
        // chapter is active and tap is a no-op.
        StreamBuilder<int?>(
          stream: player.stream.currentChapter,
          initialData: player.state.currentChapter,
          builder: (context, currentSnap) {
            return StreamBuilder<List<Chapter>>(
              stream: player.stream.chapters,
              initialData: player.state.chapters,
              builder: (context, chaptersSnap) {
                final current = currentSnap.data;
                final chapters = chaptersSnap.data ?? const <Chapter>[];
                final hasChapters = chapters.isNotEmpty;
                final atFirst = current == null || current <= 0;
                final atLast =
                    current == null || current >= chapters.length - 1;
                return PropertyBaseCard(
                  title: 'Current Chapter',
                  subtitle: 'chapter=${current ?? -1}',
                  icon: Icons.bookmark_rounded,
                  isActive: hasChapters && current != null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        onPressed: hasChapters && !atFirst
                            ? () => player.setChapter(current - 1)
                            : null,
                        tooltip: 'Previous chapter',
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        onPressed: hasChapters && !atLast
                            ? () => player.setChapter(current + 1)
                            : null,
                        tooltip: 'Next chapter',
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: 8),
        const PropertySectionHeader(title: 'Chapter List'),

        StreamBuilder<List<Chapter>>(
          stream: player.stream.chapters,
          initialData: player.state.chapters,
          builder: (context, chaptersSnap) {
            final chapters = chaptersSnap.data ?? const <Chapter>[];
            if (chapters.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.bookmark_border_rounded,
                        size: 48,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No chapters in the current file',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try a file with chapter markers (e.g. an MKA / audiobook)',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return StreamBuilder<int?>(
              stream: player.stream.currentChapter,
              initialData: player.state.currentChapter,
              builder: (context, currentSnap) {
                final current = currentSnap.data;
                return Column(
                  children: [
                    for (var i = 0; i < chapters.length; i++)
                      _ChapterTile(
                        index: i,
                        chapter: chapters[i],
                        isActive: i == current,
                        formattedTime: _fmt(chapters[i].time),
                        onTap: () => player.setChapter(i),
                      ),
                  ],
                );
              },
            );
          },
        ),

        const SizedBox(height: 16),
        const PropertySectionHeader(title: 'Active Chapter Metadata'),

        // mpv populates `chapter-metadata` with the per-chapter tag map.
        // Most files use just `title`, but some carry richer data.
        StreamBuilder<Map<String, String>>(
          stream: player.stream.chapterMetadata,
          initialData: player.state.chapterMetadata,
          builder: (context, snap) {
            final meta = snap.data ?? const <String, String>{};
            if (meta.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No metadata for the active chapter',
                  style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              );
            }
            return Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry in meta.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 110,
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                  color: cs.primary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final int index;
  final Chapter chapter;
  final bool isActive;
  final String formattedTime;
  final VoidCallback onTap;

  const _ChapterTile({
    required this.index,
    required this.chapter,
    required this.isActive,
    required this.formattedTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = chapter.title?.trim().isNotEmpty == true
        ? chapter.title!
        : 'Chapter ${index + 1}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isActive
          ? cs.primaryContainer.withValues(alpha: 0.4)
          : cs.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? cs.primary : cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
