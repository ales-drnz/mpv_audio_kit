/// mpv_audio_kit — Flutter audio player inspired by libmpv.
///
/// Supports macOS, Linux, Windows, iOS and Android.
/// Exposes the full mpv audio pipeline: lavfi filters, equalizer,
/// compressor, loudnorm, pitch/tempo, and any custom filter.
///
/// Basic usage:
/// ```dart
/// import 'package:mpv_audio_kit/mpv_audio_kit.dart';
///
/// final player = MpvPlayer();
/// await player.open('https://example.com/audio.mp3', play: true);
/// player.stateStream.listen(print);
/// // ...
/// player.dispose();
/// ```
library;
export 'src/mpv_player.dart' show MpvPlayer;
export 'src/player_types.dart'
    show PlayerState, PlayerConfig, MediaInfo, AudioFilter, AudioDevice;
export 'src/mpv_bindings.dart' show MpvLibraryException;
