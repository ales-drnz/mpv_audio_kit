// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  group('AudioDevice — semantic invariants', () {
    test('AudioDevice.auto() factory is the canonical default', () {
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
  });
}
