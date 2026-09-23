// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
@Timeout(Duration(seconds: 45))
@Tags(['network'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/libmpv_resolver.dart';
import '../_helpers/setter_test_helpers.dart';

// Behavioral pin for the native `embed_cacert` patch: with `tls-verify` ON and
// NO `tls-ca-file`, a real public HTTPS stream must still verify — proving the
// Mozilla CA roots compiled into libmpv are the trust source (there is no
// filesystem cert file and no auto-extraction anymore).
//
// This is the ground-truth probe of the SHIPPED binary, not vanilla reasoning:
// it greps the loaded libmpv for the bundle's provenance marker. A binary built
// before the patch lacks the marker, so the assertion SKIPS cleanly there and
// self-activates once the embedded binary ships. Also skips on an air-gapped host.
void main() {
  const publicHttps = 'https://streams.radiomast.io/ref-128k-mp3-stereo';

  var embedded = false;
  var networkAvailable = false;

  runtimeSuite(() {
    setUpAll(() async {
      // Ground truth: does THIS binary carry the embedded Mozilla bundle? The
      // provenance header survives verbatim in the compiled-in PEM array. latin1
      // is a lossless byte→char mapping, so a substring search over the bytes is
      // exact (no false UTF-8 decode failures on a binary).
      final bytes = File(resolveLibmpv()!).readAsBytesSync();
      embedded = latin1.decode(bytes).contains('Certificate data from Mozilla');

      try {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 4);
        final req = await client.headUrl(Uri.parse(publicHttps));
        final resp = await req.close().timeout(const Duration(seconds: 4));
        await resp.drain<void>();
        client.close();
        networkAvailable = true;
      } catch (_) {
        networkAvailable = false;
      }
    });

    test(
      'tls-verify ON + public HTTPS verifies via the embedded CA roots',
      () async {
        if (!embedded) {
          markTestSkipped(
            'libmpv predates the embed_cacert patch — rebuild to activate this pin',
          );
          return;
        }
        if (!networkAvailable) {
          markTestSkipped('network unreachable');
          return;
        }
        final player = await buildPlayer();
        addTearDown(() async {
          await player.stop();
          await player.dispose();
        });

        // Verification ON, NO tls-ca-file set: trust must come solely from the
        // roots compiled into libmpv.
        await player.setTlsVerify(true);
        expect(
          player.state.tlsCaFile,
          isEmpty,
          reason: 'no custom CA file — the embedded roots are the only trust',
        );

        final params = player.stream.audioParams
            .firstWhere((p) => p.sampleRate != null)
            .timeout(const Duration(seconds: 20));
        await player.open(const Media(publicHttps), play: false);

        expect(
          (await params).sampleRate,
          isNotNull,
          reason:
              'with tls-verify ON and no tls-ca-file, the embedded Mozilla '
              'roots must verify the server and the demuxer must report a '
              'sample rate — a verify failure would time out here',
        );
      },
    );

    test(
      'setTlsCaFile("") clears a custom override back to the embedded roots',
      () async {
        if (!embedded) {
          markTestSkipped(
            'libmpv predates the embed_cacert patch — rebuild to activate this pin',
          );
          return;
        }
        if (!networkAvailable) {
          markTestSkipped('network unreachable');
          return;
        }
        final player = await buildPlayer();
        addTearDown(() async {
          await player.stop();
          await player.dispose();
        });

        await player.setTlsVerify(true);
        // Pin to a non-existent CA file: trust can no longer be satisfied.
        await player.setTlsCaFile('/nonexistent/does-not-exist.pem');
        expect(player.state.tlsCaFile, '/nonexistent/does-not-exist.pem');

        // Clearing with '' must fall back to the embedded roots via the native
        // empty-ca_file guard — NOT load a file literally named '' (which would
        // empty the trust store and break every HTTPS handshake).
        await player.setTlsCaFile('');
        expect(player.state.tlsCaFile, isEmpty);

        final params = player.stream.audioParams
            .firstWhere((p) => p.sampleRate != null)
            .timeout(const Duration(seconds: 20));
        await player.open(const Media(publicHttps), play: false);

        expect(
          (await params).sampleRate,
          isNotNull,
          reason:
              'setTlsCaFile("") must restore embedded-root trust, not empty '
              'the store',
        );
      },
    );
  });
}
