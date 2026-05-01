import 'package:flutter/widgets.dart';

/// Convenience [StreamBuilder] that pairs a [stream] with the matching
/// snapshot value as `initialData` — both come from the same observable
/// surface, so callers don't have to repeat
/// `StreamBuilder<T>(stream: player.stream.X, initialData: player.state.X, builder: ...)`
/// at every settings card.
///
/// Usage:
/// ```dart
/// PlayerStreamBuilder<bool>(
///   stream: player.stream.mute,
///   initial: player.state.mute,
///   builder: (context, value) => Switch(value: value, onChanged: ...),
/// )
/// ```
///
/// `value` in the builder is the resolved `snap.data ?? initial`, so
/// callers don't have to write the `?? defaultValue` defensive check.
class PlayerStreamBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final T initial;
  final Widget Function(BuildContext context, T value) builder;

  const PlayerStreamBuilder({
    super.key,
    required this.stream,
    required this.initial,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: initial,
      builder: (context, snap) => builder(context, snap.data ?? initial),
    );
  }
}
