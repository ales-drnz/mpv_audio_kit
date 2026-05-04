import 'package:flutter/material.dart';

enum LogFilter { all, manual, error, warn, info, debug }

class FilterBar extends StatelessWidget {
  final LogFilter selected;
  final ValueChanged<LogFilter> onChanged;

  const FilterBar({super.key, required this.selected, required this.onChanged});

  Color _getFilterColor(LogFilter filter) {
    switch (filter) {
      case LogFilter.all:
        return Colors.blueGrey;
      case LogFilter.manual:
        return const Color(0xFFFF00FF);
      case LogFilter.error:
        return Colors.redAccent;
      case LogFilter.warn:
        return Colors.orangeAccent;
      case LogFilter.info:
        return Colors.cyanAccent;
      case LogFilter.debug:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: LogFilter.values.map((filter) {
        final isSelected = selected == filter;
        final color = _getFilterColor(filter);

        return FilterChip(
          avatar: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          label: Text(
            filter.name.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? cs.onPrimaryContainer : null,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onChanged(filter),
          backgroundColor: cs.surfaceContainerLow,
          selectedColor: cs.primaryContainer,
          visualDensity: VisualDensity.compact,
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
        );
      }).toList(),
    );
  }
}
