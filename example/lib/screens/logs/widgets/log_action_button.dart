import 'package:flutter/material.dart';

class LogActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const LogActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(icon, size: 16, color: cs.primary),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
      backgroundColor: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}
