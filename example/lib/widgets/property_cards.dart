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
  final double? defaultValue;
  final String Function(double)? labelBuilder;
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
    this.defaultValue,
    this.labelBuilder,
  });

  @override
  State<SliderPropertyCard> createState() => _SliderPropertyCardState();
}

class _SliderPropertyCardState extends State<SliderPropertyCard> {
  double? _dragValue;

  @override
  void didUpdateWidget(SliderPropertyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragValue != null && widget.value != oldWidget.value) {
      _dragValue = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = (_dragValue ?? widget.value).clamp(widget.min, widget.max);
    final def = widget.defaultValue;
    final atDefault = def == null || (displayValue - def).abs() < 1e-9;

    return PropertyBaseCard(
      title: widget.title,
      subtitle: widget.subtitle,
      icon: widget.icon,
      isActive: true,
      trailing: (def != null && !atDefault)
          ? Tooltip(
              message: 'Reset to default',
              child: InkWell(
                onTap: () {
                  setState(() => _dragValue = def);
                  widget.onChanged(def);
                },
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : null,
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
                value: displayValue,
                min: widget.min,
                max: widget.max,
                divisions: widget.divisions,
                onChanged: (v) => setState(() => _dragValue = v),
                onChangeEnd: (v) => widget.onChanged(v),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              widget.labelBuilder?.call(displayValue) ?? displayValue.toStringAsFixed(2),
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
      trailing: SizedBox(
        width: 130,
        child: Container(
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
      ),
    );
  }
}

/// A card for enum properties with ≤3 options using a [SegmentedButton].
class SegmentedPropertyCard<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final T value;
  final List<(T, String)> segments;
  final ValueChanged<T> onChanged;

  const SegmentedPropertyCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.segments,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyBaseCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      isActive: true,
      trailing: SegmentedButton<T>(
        segments: segments
            .map((s) => ButtonSegment<T>(value: s.$1, label: Text(s.$2)))
            .toList(),
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
        showSelectedIcon: false,
        style: ButtonStyle(
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 8),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 30)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          side: WidgetStatePropertyAll(
            BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// A card for string properties using a [TextField].
class TextPropertyCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final ValueChanged<String> onSubmitted;

  const TextPropertyCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onSubmitted,
  });

  @override
  State<TextPropertyCard> createState() => _TextPropertyCardState();
}

class _TextPropertyCardState extends State<TextPropertyCard> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(TextPropertyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PropertyBaseCard(
      title: widget.title,
      subtitle: widget.subtitle,
      icon: widget.icon,
      isActive: true,
      trailing: SizedBox(
        width: 130,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onSubmitted: widget.onSubmitted,
            onTapOutside: (_) {
              _focusNode.unfocus();
              widget.onSubmitted(_controller.text);
            },
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
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
