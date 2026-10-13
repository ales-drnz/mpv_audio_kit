// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// Issue #25: a tagless ADTS AAC opened after a tagged file on the same
/// player must not keep the previous file's tags in `state.metadata`.
void main() {
  final codec = '${Directory.current.path}/test/fixtures/codec';
  final tagged = '$codec/wma_v2_44100.wma';
  final tagless = '$codec/aac_adts_44100.aac';

  runtimeSuite(extraFixtures: [tagged, tagless], () {
    for (final viaStop in [true, false]) {
      test('a tagless AAC after a tagged WMA clears the tags'
          '${viaStop ? ' (stop in between)' : ''}', () async {
        final player = await buildPlayer();
        addTearDown(player.dispose);

        final tags = player.stream.metadata
            .firstWhere((m) => m.isNotEmpty)
            .timeout(const Duration(seconds: 10));
        await openAndWaitForLoad(player, tagged);
        await tags;

        if (viaStop) await player.stop();
        await openAndWaitForLoad(player, tagless);
        await Future<void>.delayed(const Duration(milliseconds: 300));

        expect(await player.getRawPropertyNode('metadata'), isEmpty);
        expect(_slashes(player.state.path), _slashes(tagless));
        expect(player.state.metadata, isEmpty);
        expect(await player.stream.metadata.first, isEmpty);
      });
    }
  });
}

String _slashes(String path) => path.replaceAll(r'\', '/');
