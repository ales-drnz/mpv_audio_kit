/// Layout / behavior metrics used across multiple screens. Keeping
/// them centralised so the responsive layout logic and the in-page
/// widgets agree on the same numbers.
class AppMetrics {
  AppMetrics._();

  /// Width of the pinned console sidebar in desktop layout. Must
  /// match the `SizedBox(width: ...)` in `screens/home/home_page.dart`.
  static const double consolePinnedWidth = 380;

  /// Below this width the layout falls back to single-column mobile
  /// mode. The value is also the threshold above which the user can
  /// pin the console.
  static const double wideLayoutThreshold = 720;

  /// Vertical lift for floating SnackBars so they clear the in-body
  /// NavigationBar (Material 3 default ~80 px + breathing room).
  static const double navBarLift = 96;

  /// How far back the player slider lets you rewind on a live source
  /// (seconds). Falls within mpv's typical `--demuxer-max-back-bytes`
  /// budget (50 MiB ≈ 7–30 minutes of audio depending on bitrate).
  static const Duration liveRewindWindow = Duration(seconds: 60);
}
