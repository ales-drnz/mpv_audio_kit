// Minimal mpv_audio_kit example
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

Future<void> main() async {
  // Registers the native libmpv backend. Call once before any Player.
  MpvAudioKit.ensureInitialized();

  // Initiate the player.
  final player = Player();

  // Publish to the OS media session.
  await player.setMediaSession(const MediaSession());

  // Open and play.
  await player.open(const Media('https://example.com/song.mp3'));
  await player.play();

  // Call dispose() when you're done with the player for good.
  // await player.dispose();
}
