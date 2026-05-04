import 'package:flutter/material.dart';

class LogTerminalAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const LogTerminalAction({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(icon, size: 16, color: Colors.white38),
          ),
        ),
      ),
    );
  }
}
