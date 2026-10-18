// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The waveform and the loudness scan of libmpv-r18 (bulk_analysis,
// loudness_scan). Up to r17 the analysis converted frames of more than 8
// channels from the wrong planes, and kept its converter across a change
// of channel layout: both crashed the process (F63). It decoded the first
// audio track whatever the player played (F67), could not read an fd://
// source (F156), and placed the samples of a source with a start time off
// the playback axis (F64).
//
// Fixtures (test/fixtures/analysis), made with ffmpeg:
//   opus_16ch_2s.opus          2 s sine on 16 channels, libopus mapping 255
//   mp3_stereo_then_mono.mp3   2 s stereo MP3 then 2 s mono MP3, joined
//   two_tracks_quiet_loud.mka  2 s Opus tracks: a sine at -30 dB (about
//                              -52 LUFS), then pink noise (about -22 LUFS)
//   vorbis_start_100s.ogg      4 s of pink noise after 1 s of silence,
//                              timestamps starting at 100 s

@TestOn('mac-os || linux || windows')
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

typedef _OpenNative = Int32 Function(Pointer<Utf8>, Int32);
typedef _Open = int Function(Pointer<Utf8>, int);
typedef _CloseNative = Int32 Function(Int32);
typedef _Close = int Function(int);

void main() {
  final dir = '${Directory.current.path}/test/fixtures/analysis';
  final opus16 = '$dir/opus_16ch_2s.opus';
  final stereoMono = '$dir/mp3_stereo_then_mono.mp3';
  final twoTracks = '$dir/two_tracks_quiet_loud.mka';
  final late = '$dir/vorbis_start_100s.ogg';

  analysisSuite(
    fixturePath: opus16,
    extraFixtures: [stereoMono, twoTracks, late],
    () {
      libmpvReleaseGroup(18, 'The analysis', () {
        late Player player;

        setUp(() async => player = await buildPlayer());
        tearDown(() => player.dispose());

        // The first value of [stream] that [done] accepts after the reset
        // of a load: the stream replays the result of the previous file.
        Future<T> afterReset<T extends Object>(
          Stream<T?> stream,
          bool Function(T) done,
        ) {
          var reset = false;
          return stream
              .where((v) {
                if (v == null) reset = true;
                return reset && v != null && done(v);
              })
              .first
              .then((v) => v!)
              .timeout(const Duration(seconds: 15));
        }

        // Opens [url] paused and returns the final waveform and the
        // finished loudness scan.
        Future<(WaveformData, LoudnessScan)> analyse(String url) async {
          final wave = afterReset(player.stream.waveform, (w) => !w.decoding);
          final scan = afterReset(
            player.stream.loudnessScan,
            (s) =>
                s.state != LoudnessScanState.idle &&
                s.state != LoudnessScanState.scanning,
          );
          await player.open(Media(url), play: false);
          return (await wave, await scan);
        }

        // Ready, with data in every bin but a tail past the end of the
        // audio, when the length mpv estimated is a little longer.
        void expectWhole(WaveformData wave, LoudnessScan scan) {
          expect(scan.state, LoudnessScanState.ready);
          expect(scan.integrated, isNotNull);
          final filled = wave.filled.where((bin) => bin == 1).length;
          expect(
            filled / wave.filled.length,
            greaterThan(0.9),
            reason: '$filled of ${wave.filled.length} bins have data',
          );
        }

        test('a file of 16 channels is analysed', () async {
          final (wave, scan) = await analyse(opus16);
          expectWhole(wave, scan);
          expect(scan.integrated!, greaterThan(-40));
        }, timeout: const Timeout(Duration(seconds: 30)));

        // The loudness of a stream whose channel count changes may end
        // failed: the waveform has to read the mono half.
        test('a file whose channel layout changes is analysed', () async {
          final (wave, scan) = await analyse(stereoMono);
          expect(
            scan.state,
            isIn([LoudnessScanState.ready, LoudnessScanState.failed]),
          );
          // mpv takes the length from the bitrate of the stereo half, so
          // the mono half starts about two thirds in, after a gap of the
          // encoder's padding.
          final mono = wave.max.skip(wave.max.length * 7 ~/ 10);
          expect(
            mono.every((peak) => peak > 0.02),
            isTrue,
            reason: 'the mono half is read, and not silent',
          );
        }, timeout: const Timeout(Duration(seconds: 30)));

        test(
          'the analysis measures the audio track the player plays',
          () async {
            await player.setRawProperty('aid', '2');
            final (_, loud) = await analyse(twoTracks);
            expect(
              loud.integrated,
              inInclusiveRange(-26, -18),
              reason: 'track 2, the pink noise, measures about -22 LUFS',
            );
            await player.setRawProperty('aid', '1');
            final (_, quiet) = await analyse(twoTracks);
            expect(
              quiet.integrated,
              inInclusiveRange(-56, -48),
              reason: 'track 1, the quiet sine, measures about -52 LUFS',
            );
          },
          timeout: const Timeout(Duration(seconds: 40)),
        );

        test(
          'an fd:// source is analysed like its path',
          () async {
            final libc = DynamicLibrary.process();
            final open = libc.lookupFunction<_OpenNative, _Open>('open');
            final close = libc.lookupFunction<_CloseNative, _Close>('close');
            final fd = using(
              (arena) => open(late.toNativeUtf8(allocator: arena), 0),
            );
            expect(fd, greaterThanOrEqualTo(0));
            addTearDown(() => close(fd));
            final (byPathWave, byPath) = await analyse(late);
            final (byFdWave, byFd) = await analyse('fd://$fd');
            expectWhole(byFdWave, byFd);
            expect(byFd.integrated, closeTo(byPath.integrated!, 0.05));
            expect(byFdWave.max.length, byPathWave.max.length);
          },
          skip: Platform.isWindows
              ? 'fd:// sources fall back to the progressive waveform'
              : null,
          timeout: const Timeout(Duration(seconds: 40)),
        );

        test('a source with a start time is analysed on the playback '
            'axis', () async {
          final (wave, scan) = await analyse(late);
          expectWhole(wave, scan);
          expect(
            scan.integrated!,
            greaterThan(-40),
            reason: 'the pink noise is measured, not silence',
          );
          // The first second is silence: the peaks rise after it.
          final firstBins = wave.max.length ~/ 5;
          expect(wave.max.take(firstBins ~/ 2).every((m) => m < 0.01), isTrue);
          expect(wave.max.skip(firstBins * 2).any((m) => m > 0.1), isTrue);
        }, timeout: const Timeout(Duration(seconds: 30)));
      });
    },
  );
}
