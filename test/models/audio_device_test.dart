// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  group('AudioDevice', () {
    test('positional name + description', () {
      const d = AudioDevice('coreaudio/AppleHDA', 'Built-in Speakers');
      expect(d.name, 'coreaudio/AppleHDA');
      expect(d.description, 'Built-in Speakers');
    });

    test('AudioDevice.auto() factory is canonical default', () {
      const d = AudioDevice.auto();
      expect(d.name, 'auto');
      expect(d.description, 'Auto');
    });

    test('equality compares ONLY by name (description is metadata)', () {
      // The library tracks devices by their mpv-side identifier; the
      // human-readable description is metadata that may legitimately
      // differ between system probes (locale changes, plug/unplug
      // events) without being a "different device".
      const a = AudioDevice('hw:0,0', 'Built-in');
      const b = AudioDevice('hw:0,0', 'Built-in (Localized)');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different name → not equal', () {
      const a = AudioDevice('a', 'desc');
      const b = AudioDevice('b', 'desc');
      expect(a, isNot(b));
    });

    test('toString includes both name and description', () {
      const d = AudioDevice('a', 'b');
      final s = d.toString();
      expect(s, contains('a'));
      expect(s, contains('b'));
    });
  });
}
