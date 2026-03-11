/// Modes for ReplayGain normalization.
enum ReplayGainMode {
  /// Disable ReplayGain.
  none('no'),

  /// Use track-based ReplayGain.
  track('track'),

  /// Use album-based ReplayGain.
  album('album');

  final String value;
  const ReplayGainMode(this.value);
}
