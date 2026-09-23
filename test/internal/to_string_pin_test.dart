import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

/// Pins toString output of value types so a regex-replace mishap (literal `\$`)
/// cannot return. See review entry "PlayerState.toString() rotto" (0.1.0).
void main() {
  group('toString interpolates correctly', () {
    test('PlayerState toString renders values, not literal \$', () {
      const s = PlayerState();
      final out = s.toString();
      expect(out, contains('playing: false'));
      expect(out, isNot(contains(r'$playing')));
      expect(out, isNot(contains(r'$position')));
      expect(out, isNot(contains(r'$volume')));
    });

    test('effect toString renders values, not literal \$', () {
      final out = const BassEffect(gain: 3).toString();
      expect(out, contains('gain: 3.0'));
      expect(out, contains('enabled: true'));
      expect(out, isNot(contains(r'$gain')));
      expect(out, isNot(contains(r'$enabled')));
      expect(
        const RawAudioEffect('lavfi-aecho').toString(),
        'RawAudioEffect(lavfi-aecho, enabled: true)',
      );
    });
  });
}
