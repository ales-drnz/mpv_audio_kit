import 'package:test/test.dart';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';

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

    test('AudioEffects toString renders values, not literal \$', () {
      const e = AudioEffects();
      final out = e.toString();
      expect(out, contains('custom: ['));
      expect(out, contains('enabled: ['));
      expect(out, isNot(contains(r'$custom')));
      expect(out, isNot(contains(r'$enabled')));
    });
  });
}
