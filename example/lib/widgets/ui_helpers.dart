import 'package:flutter/material.dart';

Widget buildSectionCard(
  BuildContext context,
  String title,
  List<Widget> children,
) {
  return Card(
    elevation: 0,
    color: Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
    margin: const EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}

Widget buildSliderRow(
  String label,
  double value,
  double min,
  double max,
  ValueChanged<double> onChanged,
) {
  return Row(
    children: [
      SizedBox(
        width: 90,
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
      Expanded(
        child: Slider(
          min: min,
          max: max,
          value: value.clamp(min, max),
          onChanged: onChanged,
        ),
      ),
      SizedBox(
        width: 40,
        child: Text(
          value.toStringAsFixed(2),
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ],
  );
}

Widget buildDropdownRow<T>(
  String label,
  T value,
  List<DropdownMenuItem<T>> items,
  ValueChanged<T?> onChanged,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: DropdownButton<T>(
            isExpanded: true,
            value: value,
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    ),
  );
}

Widget buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Switch(value: value, onChanged: onChanged),
      Text(label, style: const TextStyle(fontSize: 13)),
    ],
  );
}
