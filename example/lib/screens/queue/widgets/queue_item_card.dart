import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

class QueueItemCard extends StatelessWidget {
  final Media media;
  final int index;
  final int total;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const QueueItemCard({
    super.key,
    required this.media,
    required this.index,
    required this.total,
    required this.isCurrent,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label =
        (media.extras?['title'] as String?) ?? media.uri.split('/').last;
    final isFirst = index == 0;
    final isLast = index == total - 1;
    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(12) : Radius.zero,
      bottom: isLast ? const Radius.circular(12) : Radius.zero,
    );

    return Card(
      key: ValueKey(media.uri),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: radius),
      color: isCurrent
          ? cs.primaryContainer.withValues(alpha: 0.5)
          : cs.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.drag_handle_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCurrent ? cs.primary : cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCurrent ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        color: isCurrent ? cs.primary : cs.onSurface,
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
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                color: cs.onSurfaceVariant,
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
