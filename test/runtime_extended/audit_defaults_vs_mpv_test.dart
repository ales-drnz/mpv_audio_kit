// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// Ground-truth audit: compares every Dart default seed against the value the
// REAL libmpv reports at idle (after the pre-init recipe). A mismatch means
// the package shows a wrong value before the first property observe lands.
// Recipe-overridden options (e.g. audio-client-name) are compared against the
// recipe value, which is the correct "what the player actually has" target.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/src/reactive/default_reactives.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  setUpAll(() => initLibmpvOrSkip());

  test('Dart default seeds match the real libmpv defaults', () async {
    final r = DefaultPropertyReactives();
    final player = await buildPlayer();
    addTearDown(player.dispose);

    String dur(Duration d) => (d.inMicroseconds / 1e6).toString();

    // (mpv option/property name, Dart seed rendered as mpv would).
    final entries = <(String, String)>[
      ('volume', r.volume.value.toString()),
      ('speed', r.rate.value.toString()),
      ('pitch', r.pitch.value.toString()),
      ('mute', r.mute.value ? 'yes' : 'no'),
      ('audio-pitch-correction', r.pitchCorrection.value ? 'yes' : 'no'),
      ('audio-delay', dur(r.audioDelay.value)),
      ('gapless-audio', r.gapless.value.mpvValue),
      ('volume-gain', r.volumeGain.value.toString()),
      ('volume-gain-min', r.volumeGainMin.value.toString()),
      ('volume-gain-max', r.volumeGainMax.value.toString()),
      ('volume-max', r.volumeMax.value.toString()),
      ('demuxer-max-bytes', r.demuxer.value.maxBytes.toString()),
      ('demuxer-max-back-bytes', r.demuxer.value.maxBackBytes.toString()),
      ('demuxer-readahead-secs', dur(r.demuxer.value.readahead)),
      ('network-timeout', dur(r.networkTimeout.value)),
      ('tls-verify', r.tlsVerify.value ? 'yes' : 'no'),
      ('hls-bitrate', r.hlsBitrate.value.mpvValue),
      ('cookies', r.cookies.value ? 'yes' : 'no'),
      ('http-proxy', r.httpProxy.value),
      ('audio-exclusive', r.audioExclusive.value ? 'yes' : 'no'),
      ('audio-set-media-role', r.audioMediaRole.value ? 'yes' : 'no'),
      ('audio-buffer', dur(r.audioBuffer.value)),
      ('audio-stream-silence', r.audioStreamSilence.value ? 'yes' : 'no'),
      ('ao-null-untimed', r.audioNullUntimed.value ? 'yes' : 'no'),
      ('audio-samplerate', r.audioSampleRate.value.toString()),
      ('cover-art-auto', r.coverArtAuto.value.mpvValue),
      ('prefetch-playlist', r.prefetchPlaylist.value ? 'yes' : 'no'),
      ('shuffle', r.shuffle.value ? 'yes' : 'no'),
      ('cache', r.cache.value.mode.mpvValue),
      ('cache-secs', dur(r.cache.value.secs)),
      ('cache-pause', r.cache.value.pause ? 'yes' : 'no'),
      ('cache-on-disk', r.cache.value.onDisk ? 'yes' : 'no'),
      ('cache-pause-wait', dur(r.cache.value.pauseWait)),
      ('cache-pause-initial', r.cache.value.pauseInitial ? 'yes' : 'no'),
      ('replaygain', r.replayGain.value.mode.mpvValue),
      ('replaygain-preamp', r.replayGain.value.preamp.toString()),
      ('replaygain-fallback', r.replayGain.value.fallback.toString()),
      ('replaygain-clip', r.replayGain.value.clip ? 'yes' : 'no'),
      ('audio-client-name', r.audioClientName.value),
    ];

    bool sameNum(String a, String b) {
      final x = double.tryParse(a), y = double.tryParse(b);
      if (x == null || y == null) return false;
      final scale = x.abs() > y.abs() ? x.abs() : y.abs();
      return (x - y).abs() <= (scale == 0 ? 1e-9 : scale * 1e-6);
    }

    final mismatches = <String>[];
    // ignore: avoid_print
    print('\n── default seed  vs  real mpv (idle) ──');
    for (final (name, seed) in entries) {
      final mpv = await player.getRawProperty(name);
      final ok = mpv != null && (mpv == seed || sameNum(mpv, seed));
      if (!ok && mpv != null) mismatches.add('$name: dart=$seed  mpv=$mpv');
      // ignore: avoid_print
      print(
        '  ${mpv == null
            ? '·· n/a   '
            : ok
            ? '✅ match  '
            : '❌ DIFF   '}'
        '${name.padRight(24)} dart=${seed.padRight(14)} mpv=$mpv',
      );
    }

    expect(
      mismatches,
      isEmpty,
      reason:
          'Dart seeds diverge from real mpv defaults:\n${mismatches.join('\n')}',
    );
  }, timeout: const Timeout(Duration(seconds: 25)));
}
