/// Formats a [Duration] as `H:MM:SS` (or `MM:SS` when the value is
/// under one hour). Used by the seek slider, chapter list, and any
/// other widget that needs a compact time-of-playback string.
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}
