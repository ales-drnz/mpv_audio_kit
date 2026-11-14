// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

const _rate = 48000;
const _window = 4096;
const _hop = 1584; // 33 ms of new audio per poll, as the pcm tap delivers.

/// The last [_window] stereo frames of a 440 Hz tone ending at [end].
PcmFrame _frame(int end) {
  final s = Float32List(_window * 2);
  for (var i = 0; i < _window; i++) {
    final v = 0.3 * math.sin(2 * math.pi * 440 * (end - _window + i) / _rate);
    s[i * 2] = v;
    s[i * 2 + 1] = v;
  }
  return PcmFrame(
    samples: s,
    timestamp: Duration(microseconds: end * 1000000 ~/ _rate),
    sampleRate: _rate,
    channels: 2,
  );
}

String _dart() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final exe = Platform.isWindows ? 'dart.exe' : 'dart';
    final path = [
      root,
      'bin',
      'cache',
      'dart-sdk',
      'bin',
      exe,
    ].join(Platform.pathSeparator);
    if (File(path).existsSync()) return path;
  }
  return 'dart';
}

void main() {
  // BandProcessor is public and takes any SpectrumSettings: in a release
  // build the constructor asserts are skipped, and an overlapFactor of 0
  // threw IntegerDivisionByZeroException from process. `flutter test` always
  // runs asserts, so a `dart` process, which runs none, builds the settings.
  test(
    'settings out of range are refused, in a build without asserts',
    testOn: 'mac-os || linux || windows',
    () async {
      final result = await Process.run(_dart(), [
        'test/_helpers/probes/band_processor_probe.dart',
      ], stdoutEncoding: utf8);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      final report =
          jsonDecode((result.stdout as String).trim().split('\n').last)
              as Map<String, dynamic>;
      expect(report['asserts'], isFalse);
      final cases = report['cases'] as Map<String, dynamic>;
      expect(cases['defaults'], isNull);
      expect(cases['process after a refused set'], isNull);
      for (final MapEntry(:key, :value) in cases.entries) {
        if (!key.startsWith('new ') && !key.startsWith('set ')) continue;
        expect(value, anyOf('ArgumentError', 'RangeError'), reason: key);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  for (final (name, bad) in [
    ('NaN', double.nan),
    ('Inf', double.infinity),
    ('-Inf', double.negativeInfinity),
  ]) {
    test('one $name sample does not stick in the bands', () {
      final p = BandProcessor(SpectrumSettings.defaults);
      var end = _window;
      for (var i = 0; i < 20; i++) {
        p.process(_frame(end));
        end += _hop;
      }
      final poisoned = _frame(end);
      poisoned.samples[100] = bad;
      final hit = p.process(poisoned)!;
      expect(hit.bands.every((v) => v.isFinite), isTrue);
      expect(hit.bins.every((v) => v.isFinite), isTrue);

      FftFrame? last;
      for (var i = 0; i < 200; i++) {
        end += _hop;
        last = p.process(_frame(end)) ?? last;
      }
      expect(last!.bands.every((v) => v.isFinite && v >= 0 && v <= 1), isTrue);
      expect(
        last.bands.reduce(math.max),
        greaterThan(0.5),
        reason: 'the tone is back in the bands',
      );
    });
  }

  group('frames that overlap', () {
    // A stretch of stereo noise: no part of it repeats, so a frame lies
    // over the one before at one offset only.
    final rnd = math.Random(11);
    final noise = Float32List(_rate * 4 * 2);
    for (var i = 0; i < noise.length; i++) {
      noise[i] = rnd.nextDouble() - 0.5;
    }

    /// The frames [from] to [to] of [audio], stamped [stamp] frames in.
    PcmFrame cut(Float32List audio, int from, int to, {int? stamp}) => PcmFrame(
      samples: Float32List.fromList(
        Float32List.sublistView(audio, from * 2, to * 2),
      ),
      timestamp: Duration(microseconds: (stamp ?? to) * 1000000 ~/ _rate),
      sampleRate: _rate,
      channels: 2,
    );

    /// Feeds [tap] the latest [_window] frames every [hop] frames, as a
    /// tap does, and [pieces] the same audio with each sample once. The
    /// two must send the same bands at the same calls.
    void expectSameAsPieces(
      Float32List audio, {
      required int hop,
      int Function(int end)? stamp,
    }) {
      final tap = BandProcessor(SpectrumSettings.defaults);
      final pieces = BandProcessor(SpectrumSettings.defaults);
      var end = _window;
      final first = tap.process(cut(audio, 0, end));
      expect(pieces.process(cut(audio, 0, end))!.bands, first!.bands);
      var sent = 0;
      for (var poll = 0; poll < 60; poll++) {
        final from = end;
        end += hop;
        final a = tap.process(
          cut(audio, end - _window, end, stamp: stamp?.call(end)),
        );
        final b = pieces.process(cut(audio, from, end));
        expect(a == null, b == null, reason: 'poll $poll');
        if (a == null) continue;
        sent++;
        expect(a.bands, b!.bands, reason: 'poll $poll');
        expect(a.bins, b.bins, reason: 'poll $poll');
      }
      expect(sent, greaterThan(20));
    }

    test('each sample is analyzed once: the bands of the audio in pieces', () {
      expectSameAsPieces(noise, hop: _hop);
      // 16 ms and 8 ms between polls: less new audio than one FFT hop.
      expectSameAsPieces(noise, hop: 768);
      expectSameAsPieces(noise, hop: 384);
    });

    test('a clock that is not the samples\' only says where to look', () {
      // The pcm tap stamps a frame with the time of its last write, which
      // is off from the count of samples by a part of a chunk.
      final jitter = math.Random(5);
      var last = _window;
      expectSameAsPieces(
        noise,
        hop: _hop,
        stamp: (end) {
          // Off by up to 400 frames either way, never backwards.
          final at = end + jitter.nextInt(800) - 400;
          return last = math.max(last + 1, at);
        },
      );
    });

    test('a frame that does not continue the one before is analyzed '
        'whole', () {
      final tap = BandProcessor(SpectrumSettings.defaults);
      final whole = BandProcessor(SpectrumSettings.defaults);
      final a0 = cut(noise, 0, _window);
      tap.process(a0);
      whole.process(a0);
      // 33 ms later by the clock, audio from elsewhere (a seek).
      final far = cut(noise, 50000, 50000 + _window, stamp: _window + _hop);
      final farWhole = cut(noise, 50000, 50000 + _window, stamp: 10 * _window);
      expect(tap.process(far)!.bands, whole.process(farWhole)!.bands);
    });

    test('the same frame again, or an older one, is analyzed whole', () {
      final p = BandProcessor(SpectrumSettings.defaults);
      expect(p.process(cut(noise, 0, _window)), isNotNull);
      expect(p.process(cut(noise, 0, _window)), isNotNull);
      expect(p.process(cut(noise, 0, _window, stamp: 100)), isNotNull);
    });

    test('silence keeps sending frames, and the bands fall', () {
      final quiet = Float32List(_rate * 4 * 2);
      final p = BandProcessor(SpectrumSettings.defaults);
      var end = _window;
      p.process(cut(noise, 0, end));
      FftFrame? out;
      var sent = 0;
      for (var poll = 0; poll < 60; poll++) {
        end += _hop;
        final f = p.process(cut(quiet, end - _window, end));
        if (f != null) {
          out = f;
          sent++;
        }
      }
      expect(sent, 60);
      expect(out!.bands.reduce(math.max), lessThan(0.01));
    });

    test('a caller that reuses its buffer gets the same bands', () {
      final own = BandProcessor(SpectrumSettings.defaults);
      final reused = BandProcessor(SpectrumSettings.defaults);
      final buffer = Float32List(_window * 2);
      for (var end = _window; end < _window + 30 * _hop; end += _hop) {
        final fresh = cut(noise, end - _window, end);
        buffer.setAll(0, fresh.samples);
        final a = own.process(fresh);
        final b = reused.process(
          PcmFrame(
            samples: buffer,
            timestamp: fresh.timestamp,
            sampleRate: _rate,
            channels: 2,
          ),
        );
        expect(a?.bands, b?.bands);
      }
    });

    test('another channel count or rate starts over', () {
      final p = BandProcessor(SpectrumSettings.defaults);
      p.process(cut(noise, 0, _window));
      // The same values read as mono: nothing of it is taken as known.
      final mono = PcmFrame(
        samples: Float32List.sublistView(noise, 0, _window),
        timestamp: const Duration(
          microseconds: (_window + _hop) * 1000000 ~/ _rate,
        ),
        sampleRate: _rate,
        channels: 1,
      );
      expect(p.process(mono), isNotNull);
      final rate = PcmFrame(
        samples: Float32List.sublistView(noise, 0, _window),
        timestamp: const Duration(
          microseconds: (_window + 2 * _hop) * 1000000 ~/ _rate,
        ),
        sampleRate: 44100,
        channels: 1,
      );
      expect(p.process(rate), isNotNull);
    });
  });
}
