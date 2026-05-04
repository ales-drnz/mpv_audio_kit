import 'package:flutter/material.dart';
import 'page_meta.dart';

class GridCard extends StatelessWidget {
  final PageMeta entry;
  final VoidCallback onTap;
  const GridCard({super.key, required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '--${entry.label}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: cs.onPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const Spacer(),
              Icon(entry.icon, size: 22, color: cs.onSurfaceVariant),
              const SizedBox(height: 6),
              Text(
                entry.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
