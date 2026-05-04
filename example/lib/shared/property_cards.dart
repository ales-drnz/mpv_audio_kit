import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'snack_messenger.dart';

/// Shared height for compact trailing controls (dropdown / text field) so
/// every property card renders the same row height regardless of which
/// control sits on the right.
const double _kTrailingHeight = 40.0;

/// A base layout for all property-based cards to ensure visual consistency.
///
/// `icon` is optional — pass `null` to render the card without the
/// leading badge (used by lists where the title alone identifies the
/// row, e.g. the Stream Lab URL catalog).
class PropertyBaseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Widget? body;
  final bool isActive;

  const PropertyBaseCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.trailing,
    this.body,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final t = trailing;
    final b = body;
    final ic = icon;

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
                if (ic != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      ic,
                      size: 20,
                      color: isActive ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
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
                                showCopiedSnack(context, subtitle);
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
                    constraints: const BoxConstraints(maxWidth: 180),
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

/// A card for read-only properties — pure observation surface (no
/// interaction). The trailing slot shows the formatted value in
/// monospace, right-aligned, ellipsised when long.
class ReadOnlyPropertyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;

  const ReadOnlyPropertyCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PropertyBaseCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      isActive: true,
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
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
    final cs = Theme.of(context).colorScheme;
    final displayValue = (_dragValue ?? widget.value).clamp(
      widget.min,
      widget.max,
    );
    final def = widget.defaultValue;
    final atDefault = def == null || (displayValue - def).abs() < 1e-9;
    final showReset = def != null && !atDefault;

    return PropertyBaseCard(
      title: widget.title,
      subtitle: widget.subtitle,
      icon: widget.icon,
      isActive: true,
      // Value pill + (optional) reset pill in the trailing slot, on the
      // same row as icon / title / subtitle so the row height stays
      // consistent with [TogglePropertyCard] / [DropdownPropertyCard] /
      // [TextPropertyCard]. The two pills are visually separate so the
      // reset reads as a distinct action, not a sub-element of the value.
      trailing: SizedBox(
        height: _kTrailingHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.labelBuilder?.call(displayValue) ??
                    displayValue.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: cs.onSurface,
                ),
              ),
            ),
            if (showReset) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: 'Reset to default',
                child: Material(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _dragValue = def);
                      widget.onChanged(def);
                    },
                    child: SizedBox(
                      width: _kTrailingHeight,
                      height: _kTrailingHeight,
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: Slider(
        value: displayValue,
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        onChanged: (v) => setState(() => _dragValue = v),
        onChangeEnd: (v) => widget.onChanged(v),
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
        height: _kTrailingHeight,
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
                // Custom builder for the CLOSED state of the dropdown:
                // truncates long labels with ellipsis instead of wrapping
                // to a second line. The expanded menu items still use the
                // original `child` (free-form, can be multi-line if the
                // caller wants).
                selectedItemBuilder: (context) => items
                    .map((item) => Align(
                          alignment: Alignment.centerLeft,
                          child: DefaultTextStyle.merge(
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            child: item.child,
                          ),
                        ))
                    .toList(),
                onChanged: onChanged,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
                isExpanded: true,
                alignment: Alignment.centerLeft,
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

/// A card for multi-select properties shown as toggleable check pills in
/// the card body. Visually aligned with the rest of the property cards:
/// the same primaryContainer / onSurfaceVariant palette used by the icon
/// badge, a leading check icon when selected, and pill-shape rows wrapping
/// onto new lines on narrow widths.
class CheckPillsPropertyCard<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Set<T> values;
  final List<(T, String)> options;
  final ValueChanged<Set<T>> onChanged;

  const CheckPillsPropertyCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.values,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PropertyBaseCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      isActive: values.isNotEmpty,
      body: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((o) {
          final selected = values.contains(o.$1);
          return Material(
            color: selected
                ? cs.primaryContainer
                : cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                final next = {...values};
                selected ? next.remove(o.$1) : next.add(o.$1);
                onChanged(next);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected
                          ? Icons.check_rounded
                          : Icons.add_rounded,
                      size: 14,
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      o.$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: selected ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.5),
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
        height: _kTrailingHeight,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          // [DropdownButton] centres its content via the iconSize+padding
          // intrinsic; the TextField has no equivalent baseline, so we
          // pin the same height on the SizedBox and let [Center] handle
          // vertical alignment of the dense input.
          child: Center(
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
      ),
    );
  }
}

/// A card for a toggleable filter with collapsible parameter sliders.
///
/// The header row shows the icon, title, subtitle, an expand chevron, and a
/// toggle switch. The param area animates open/closed and is dimmed when the
/// filter is disabled.
class ExpandableFilterCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final List<Widget> params;

  const ExpandableFilterCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onToggle,
    required this.params,
  });

  @override
  State<ExpandableFilterCard> createState() => _ExpandableFilterCardState();
}

class _ExpandableFilterCardState extends State<ExpandableFilterCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.enabled
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 20,
                    color: widget.enabled ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
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
                              ClipboardData(text: widget.subtitle),
                            ).then((_) {
                              if (context.mounted) {
                                showCopiedSnack(context, widget.subtitle);
                              }
                            });
                          },
                          child: Text(
                            widget.subtitle,
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
                if (widget.params.isNotEmpty)
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      icon: Icon(
                        Icons.expand_more_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                      onPressed: () => setState(() => _expanded = !_expanded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ),
                Switch(value: widget.enabled, onChanged: widget.onToggle),
              ],
            ),
            if (_expanded && widget.params.isNotEmpty)
              IgnorePointer(
                ignoring: !widget.enabled,
                child: Opacity(
                  opacity: widget.enabled ? 1.0 : 0.4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 20, thickness: 0.5),
                      for (var i = 0; i < widget.params.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 12, thickness: 0.5),
                        widget.params[i],
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A compact labeled slider for use inside [ExpandableFilterCard].
///
/// Visual updates happen during drag; [onChanged] is only called on release.
class FilterParamSlider extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final double defaultValue;
  final String Function(double) labelBuilder;
  final ValueChanged<double> onChanged;

  const FilterParamSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.labelBuilder,
    required this.onChanged,
    this.divisions = 100,
  });

  @override
  State<FilterParamSlider> createState() => _FilterParamSliderState();
}

// Shared trailing pill height for filter-param widgets — 32 (instead of
// the standalone `_kTrailingHeight = 40`) keeps the rows compact inside
// the already-padded ExpandableFilterCard while preserving the same
// visual language as PropertyBaseCard's trailing pills.
const double _kFilterParamHeight = 32.0;

/// Bordered "pill" container shared by FilterParamSlider's value display,
/// FilterParamDropdown, and the reset button — same fill / radius as
/// PropertyBaseCard's trailing pills, scaled down for the in-card use.
Widget _filterParamPill({
  required ColorScheme cs,
  required Widget child,
  EdgeInsets? padding,
}) {
  return Container(
    height: _kFilterParamHeight,
    padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );
}

Widget _filterParamResetPill({
  required ColorScheme cs,
  required VoidCallback onPressed,
}) {
  return Tooltip(
    message: 'Reset to default',
    child: Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: SizedBox(
          width: _kFilterParamHeight,
          height: _kFilterParamHeight,
          child: Icon(
            Icons.refresh_rounded,
            size: 16,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    ),
  );
}

Widget _filterParamLabel(String label, ColorScheme cs) => Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: cs.onSurface,
      ),
    );

class _FilterParamSliderState extends State<FilterParamSlider> {
  double? _dragValue;

  @override
  void didUpdateWidget(FilterParamSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragValue != null && widget.value != oldWidget.value) {
      _dragValue = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final display = (_dragValue ?? widget.value).clamp(widget.min, widget.max);
    final atDefault = (widget.value - widget.defaultValue).abs() < 1e-9;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _filterParamLabel(widget.label, cs)),
              const SizedBox(width: 8),
              _filterParamPill(
                cs: cs,
                child: Text(
                  widget.labelBuilder(display),
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (!atDefault) ...[
                const SizedBox(width: 6),
                _filterParamResetPill(
                  cs: cs,
                  onPressed: () {
                    setState(() => _dragValue = null);
                    widget.onChanged(widget.defaultValue);
                  },
                ),
              ],
            ],
          ),
          Slider(
            value: display,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            onChanged: (v) => setState(() => _dragValue = v),
            onChangeEnd: (v) {
              setState(() => _dragValue = null);
              widget.onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

/// A compact labeled dropdown for use inside [ExpandableFilterCard].
class FilterParamDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final T defaultValue;
  final List<T> options;
  final String Function(T) optionLabel;
  final ValueChanged<T> onChanged;

  const FilterParamDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.defaultValue,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final atDefault = value == defaultValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: _filterParamLabel(label, cs)),
          const SizedBox(width: 8),
          _filterParamPill(
            cs: cs,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isDense: true,
                iconSize: 18,
                borderRadius: BorderRadius.circular(12),
                dropdownColor: cs.surfaceContainerHighest,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
                items: options
                    .map((o) => DropdownMenuItem<T>(
                          value: o,
                          child: Text(optionLabel(o)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
          if (!atDefault) ...[
            const SizedBox(width: 6),
            _filterParamResetPill(
              cs: cs,
              onPressed: () => onChanged(defaultValue),
            ),
          ],
        ],
      ),
    );
  }
}

/// A compact labeled toggle for use inside [ExpandableFilterCard].
class FilterParamSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final bool defaultValue;
  final ValueChanged<bool> onChanged;

  const FilterParamSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.defaultValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final atDefault = value == defaultValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: _filterParamLabel(label, cs)),
          const SizedBox(width: 8),
          SizedBox(
            height: _kFilterParamHeight,
            child: Switch(value: value, onChanged: onChanged),
          ),
          if (!atDefault) ...[
            const SizedBox(width: 6),
            _filterParamResetPill(
              cs: cs,
              onPressed: () => onChanged(defaultValue),
            ),
          ],
        ],
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
