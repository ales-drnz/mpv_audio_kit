import 'package:flutter/material.dart';

import '../theme/app_metrics.dart';

/// Global flag tracking whether the live-log console is currently
/// pinned to the right side of the layout.
///
/// Lives outside the widget tree so [showFloatingSnack] reads the
/// current state regardless of the calling context — pages pushed via
/// `Navigator.of(context).push(MaterialPageRoute(...))` end up under
/// the root navigator (sibling of `HomePage`, not descendant), so an
/// `InheritedWidget` wrapped only around the home body would not be
/// visible to them. The notifier sidesteps the tree entirely.
///
/// `HomePage` is the single writer (mirrors the user's "pin console"
/// toggle). `showFloatingSnack` is the only reader. Defaults to
/// `false` so any code path running before HomePage initialises (early
/// dialogs, splash error toasts) gets a sensible margin.
final ValueNotifier<bool> consolePinnedNotifier = ValueNotifier(false);

/// Single source of truth for the example app's floating SnackBars.
///
/// Lifts the snack above the in-body NavigationBar (`AppMetrics.navBarLift`)
/// and pushes it left of the pinned console panel when the layout is wide.
/// Optional [background] / [foreground] override the colors; passing one
/// forces the other so the snack doesn't end up with white-on-light
/// (the default theme contrast breaks for light containers).
void showFloatingSnack(
  BuildContext context, {
  required Widget content,
  Duration duration = const Duration(seconds: 2),
  Color? background,
  Color? foreground,
}) {
  final width = MediaQuery.of(context).size.width;
  final isWide = width >= AppMetrics.wideLayoutThreshold;
  final showPinned = isWide && consolePinnedNotifier.value;
  final rightMargin =
      showPinned ? AppMetrics.consolePinnedWidth + 16 : 16.0;

  final wrapped = foreground == null
      ? content
      : DefaultTextStyle.merge(
          style: TextStyle(color: foreground),
          child: IconTheme.merge(
            data: IconThemeData(color: foreground),
            child: content,
          ),
        );

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: wrapped,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: background,
      margin: EdgeInsets.fromLTRB(16, 0, rightMargin, AppMetrics.navBarLift),
    ),
  );
}

/// Convenience for the `Copied: <value>` pattern used by every clickable
/// monospace subtitle (lavfi command, mpv property name, …).
void showCopiedSnack(BuildContext context, String value) {
  showFloatingSnack(
    context,
    content: Text('Copied: $value'),
    duration: const Duration(seconds: 1),
  );
}
