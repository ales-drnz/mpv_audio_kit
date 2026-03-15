import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A base layout for all property-based cards to ensure visual consistency.
class PropertyBaseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final Widget? body;
  final bool isActive;

  const PropertyBaseCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.body,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final t = trailing;
    final b = body;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isActive ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: subtitle),
                            ).then((_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Copied: $subtitle'),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                    width: 280,
                                  ),
                                );
                              }
                            });
                          },
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (t != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      maxWidth: 180,
                    ),
                    child: t,
                  ),
                ],
              ],
            ),
            if (b != null) ...[const SizedBox(height: 12), b],
          ],
        ),
      ),
    );
  }
}

/// A card for boolean properties using a [Switch].
class TogglePropertyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const TogglePropertyCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyBaseCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      isActive: value,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

/// A card for numeric properties using a [Slider].
class SliderPropertyCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  const SliderPropertyCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions = 100,
    this.label = '',
  });

  @override
  State<SliderPropertyCard> createState() => _SliderPropertyCardState();
}

class _SliderPropertyCardState extends State<SliderPropertyCard> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final displayValue = _dragValue ?? widget.value;

    return PropertyBaseCard(
      title: widget.title,
      subtitle: widget.subtitle,
      icon: widget.icon,
      isActive: true,
      body: Row(
        children: [
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: displayValue.clamp(widget.min, widget.max),
                min: widget.min,
                max: widget.max,
                divisions: widget.divisions,
                onChanged: (v) {
                  setState(() => _dragValue = v);
                },
                onChangeEnd: (v) async {
                  widget.onChanged(v);
                  // Avoid snap-back for a moment
                  await Future.delayed(const Duration(milliseconds: 500));
                  if (mounted) {
                    setState(() => _dragValue = null);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              widget.label.isNotEmpty
                  ? widget.label
                  : displayValue.toStringAsFixed(2),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card for enum or list properties using a [DropdownButton].
class DropdownPropertyCard<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const DropdownPropertyCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PropertyBaseCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      isActive: true,
      trailing: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
              isExpanded: true,
              alignment: Alignment.centerRight,
              iconSize: 18,
              dropdownColor: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small header for grouping property cards.
class PropertySectionHeader extends StatelessWidget {
  final String title;

  const PropertySectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
