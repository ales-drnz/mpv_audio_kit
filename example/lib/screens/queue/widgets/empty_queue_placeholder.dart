import 'package:flutter/material.dart';

class EmptyQueuePlaceholder extends StatelessWidget {
  final bool isDragging;
  final bool isDesktop;

  const EmptyQueuePlaceholder({
    super.key,
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
