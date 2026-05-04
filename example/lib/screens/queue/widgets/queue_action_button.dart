import 'package:flutter/material.dart';

class QueueActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isError;

  const QueueActionButton({
    super.key,
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
