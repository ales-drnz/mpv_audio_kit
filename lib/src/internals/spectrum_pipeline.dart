// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:fftea/fftea.dart';
import 'package:meta/meta.dart';

import '../models/fft_frame.dart';
import '../models/pcm_frame.dart';
import '../mpv_bindings.dart';
import '../types/settings/spectrum_settings.dart';

/// Real-time FFT + raw PCM pipeline backed by the mpv `pcm-tap-frame`
/// property.
///
/// Owns two broadcast streams ([spectrumStream], [pcmStream]) and a
/// poll loop that calls `mpv_get_property("pcm-tap-frame")` at the
/// configured emit rate. The poll loop is **lazy**: it starts on the
/// first listener (to either stream) and stops on the last cancel.
///
/// The pipeline:
///   1. Poll the property → MAP_NODE { sample_rate, channels, pts_ns, samples }.
///   2. Skip emit when `pts_ns` matches the previous poll (no new audio).
///   3. Mix down to mono (mean of channels).
///   4. Multiply by the configured window function.
///   5. Real FFT (fftea) → magnitude per bin.
///   6. Power → 10·log₁₀ → clip [minDb, maxDb] → normalise [0, 1].
///   7. Aggregate bins into log-spaced bands (mean per band).
///   8. Apply asymmetric EMA on the bands (fast attack, slow release).
///   9. Emit [FftFrame] (raw bins + smoothed bands) and [PcmFrame].
@internal
class SpectrumPipeline {
  SpectrumPipeline({
    required MpvLibrary lib,
    required Pointer<MpvHandle> handle,
  })  : _lib = lib,
        _handle = handle {
    _spectrumCtrl = StreamController<FftFrame>.broadcast(
      onListen: () {
        _spectrumActive = true;
        _maybeStart();
      },
      onCancel: () {
        _spectrumActive = false;
        _maybeStop();
      },
    );
    _pcmCtrl = StreamController<PcmFrame>.broadcast(
      onListen: () {
        _pcmActive = true;
        _maybeStart();
      },
      onCancel: () {
        _pcmActive = false;
        _maybeStop();
      },
    );
  }

  final MpvLibrary _lib;
  final Pointer<MpvHandle> _handle;

  late final StreamController<FftFrame> _spectrumCtrl;
  late final StreamController<PcmFrame> _pcmCtrl;

  Stream<FftFrame> get spectrumStream => _spectrumCtrl.stream;
  Stream<PcmFrame> get pcmStream => _pcmCtrl.stream;

  SpectrumSettings _settings = SpectrumSettings.defaults;
  SpectrumSettings get settings => _settings;

  bool _spectrumActive = false;
  bool _pcmActive = false;
  bool _disposed = false;
  Timer? _pollTimer;

  // FFT state — recreated on fftSize / window changes, kept across polls.
  FFT? _fft;
  Float64List? _fftInput;
  // Reusable complex buffer for inPlaceFft — avoids the per-frame
  // `Float64x2List(fftSize)` allocation realFft would do internally.
  Float64x2List? _fftBuffer;
  Float32List? _window;
  Float32List? _smoothedBands;
  // Per-band bin range (start inclusive, end exclusive). null = recompute
  // on next FFT (after sample-rate or band-config change).
  Int32List? _bandStartBin;
  Int32List? _bandEndBin;
  int _lastBandSampleRate = 0;
  int _lastPolledPtsNs = 0;

  /// Replaces the pipeline configuration. Reallocates FFT / window /
  /// EMA memory only on changes that require it; the poll timer is
  /// re-armed only when [SpectrumSettings.emitInterval] changes.
  void setSettings(SpectrumSettings next) {
    final fftSizeChanged = next.fftSize != _settings.fftSize;
    final windowChanged =
        next.window != _settings.window || fftSizeChanged;
    final bandConfigChanged = next.bandCount != _settings.bandCount ||
        next.bandLowHz != _settings.bandLowHz ||
        next.bandHighHz != _settings.bandHighHz;
    final emitChanged = next.emitInterval != _settings.emitInterval;

    _settings = next;

    if (fftSizeChanged) {
      _fft = FFT(next.fftSize);
      _fftInput = Float64List(next.fftSize);
      _fftBuffer = Float64x2List(next.fftSize);
    }
    if (windowChanged) {
      _window = next.window.compute(next.fftSize);
    }
    if (bandConfigChanged || fftSizeChanged) {
      _smoothedBands = Float32List(next.bandCount);
      _bandStartBin = null; // forces lazy recompute on next FFT
      _bandEndBin = null;
    }
    if (emitChanged && _pollTimer != null) {
      _pollTimer!.cancel();
      _pollTimer = Timer.periodic(_settings.emitInterval, (_) => _poll());
    }
  }

  void _maybeStart() {
    if (_disposed || _pollTimer != null) return;
    if (_handle == nullptr) return;
    // Lazy first-time alloc — avoids paying the FFT setup cost when
    // nothing ever subscribes to either stream.
    _fft ??= FFT(_settings.fftSize);
    _fftInput ??= Float64List(_settings.fftSize);
    _fftBuffer ??= Float64x2List(_settings.fftSize);
    _window ??= _settings.window.compute(_settings.fftSize);
    _smoothedBands ??= Float32List(_settings.bandCount);
    _pollTimer = Timer.periodic(_settings.emitInterval, (_) => _poll());
  }

  void _maybeStop() {
    if (_spectrumActive || _pcmActive) return;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _poll() {
    if (_disposed) return;
    if (!_spectrumActive && !_pcmActive) return;
    if (_handle == nullptr) return;

    final result = calloc<MpvNode>();
    try {
      final rc = using<int>((arena) {
        final name = 'pcm-tap-frame'.toNativeUtf8(allocator: arena);
        return _lib.mpvGetProperty(
          _handle,
          name,
          MpvFormat.mpvFormatNode,
          result.cast(),
        );
      });
      if (rc < 0) return;
      if (result.ref.format != MpvFormat.mpvFormatNodeMap) return;
      final list = result.ref.u.list.ref;

      var sampleRate = 0;
      var channels = 0;
      var ptsNs = 0;
      Float32List? samples;

      for (var i = 0; i < list.num; i++) {
        final keyPtr = list.keys[i];
        final key = keyPtr.cast<Utf8>().toDartString();
        final node = (list.values + i).ref;
        switch (key) {
          case 'sample_rate':
            if (node.format == MpvFormat.mpvFormatInt64) {
              sampleRate = node.u.int64;
            }
          case 'channels':
            if (node.format == MpvFormat.mpvFormatInt64) {
              channels = node.u.int64;
            }
          case 'pts_ns':
            if (node.format == MpvFormat.mpvFormatInt64) {
              ptsNs = node.u.int64;
            }
          case 'samples':
            if (node.format == MpvFormat.mpvFormatByteArray) {
              final ba = node.u.ba.ref;
              if (ba.size > 0) {
                final floatCount = ba.size ~/ 4;
                final src = ba.data.cast<Float>().asTypedList(floatCount);
                samples = Float32List(floatCount)..setAll(0, src);
              }
            }
        }
      }

      if (samples == null ||
          sampleRate <= 0 ||
          channels <= 0 ||
          ptsNs == 0) {
        return;
      }
      if (ptsNs == _lastPolledPtsNs) return;
      _lastPolledPtsNs = ptsNs;

      final timestamp = Duration(microseconds: ptsNs ~/ 1000);

      if (_pcmActive && !_pcmCtrl.isClosed) {
        _pcmCtrl.add(PcmFrame(
          samples: samples,
          timestamp: timestamp,
          sampleRate: sampleRate,
          channels: channels,
        ));
      }

      if (_spectrumActive && !_spectrumCtrl.isClosed) {
        final frame = _runFft(samples, sampleRate, channels, timestamp);
        if (frame != null) _spectrumCtrl.add(frame);
      }
    } finally {
      _lib.mpvFreeNodeContents(result);
      calloc.free(result);
    }
  }

  FftFrame? _runFft(
    Float32List samples,
    int sampleRate,
    int channels,
    Duration timestamp,
  ) {
    final fftSize = _settings.fftSize;
    final samplesPerChannel = samples.length ~/ channels;
    if (samplesPerChannel <= 0) return null;

    final input = _fftInput!;

    // Feed the LATEST `fftSize` samples per channel. If the ring isn't
    // full yet (audio just started), front-pad with zeros.
    final available = math.min(samplesPerChannel, fftSize);
    final padding = fftSize - available;
    final startSample = samplesPerChannel - available;
    for (var i = 0; i < padding; i++) {
      input[i] = 0.0;
    }
    if (channels == 1) {
      for (var i = 0; i < available; i++) {
        input[padding + i] = samples[startSample + i];
      }
    } else {
      // Mono mixdown: arithmetic mean across all channels.
      final inv = 1.0 / channels;
      for (var i = 0; i < available; i++) {
        var sum = 0.0;
        final base = (startSample + i) * channels;
        for (var c = 0; c < channels; c++) {
          sum += samples[base + c];
        }
        input[padding + i] = sum * inv;
      }
    }

    // Apply window AND pack into the complex buffer in one pass —
    // avoids realFft's internal allocation by reusing _fftBuffer.
    final window = _window!;
    final buf = _fftBuffer!;
    for (var i = 0; i < fftSize; i++) {
      buf[i] = Float64x2(input[i] * window[i], 0);
    }
    _fft!.inPlaceFft(buf);

    // Result occupies `fftSize` complex values; the first `fftSize/2`
    // bins are the unique positive-frequency content (the upper half
    // is the conjugate mirror).
    final spectrum = buf;

    final binCount = fftSize ~/ 2;
    final rawBins = Float32List(binCount);

    final minDb = _settings.minDb;
    final maxDb = _settings.maxDb;
    final dbRange = maxDb - minDb;
    if (dbRange <= 0) return null;

    // Power → log → clip → normalise [0, 1].
    for (var i = 0; i < binCount; i++) {
      final c = spectrum[i];
      final power = c.x * c.x + c.y * c.y;
      // 10·log₁₀(power + ε) — ε keeps the log finite at silence.
      final db = 10 * (math.log(power + 1e-12) / math.ln10);
      var n = (db - minDb) / dbRange;
      if (n < 0) n = 0;
      if (n > 1) n = 1;
      rawBins[i] = n;
    }

    // Compute / refresh bin → band mapping when sample rate changes
    // or after a setSettings reset.
    if (_bandStartBin == null || sampleRate != _lastBandSampleRate) {
      _computeBandMapping(sampleRate, fftSize, binCount);
      _lastBandSampleRate = sampleRate;
    }

    // Bins → bands (mean of bins inside each band).
    final bandCount = _settings.bandCount;
    final smoothedBands = _smoothedBands!;
    final attack = _settings.attackSmoothing;
    final release = _settings.releaseSmoothing;
    final bandStart = _bandStartBin!;
    final bandEnd = _bandEndBin!;

    for (var b = 0; b < bandCount; b++) {
      final start = bandStart[b];
      final end = bandEnd[b];
      var sum = 0.0;
      final count = end - start;
      if (count <= 0) {
        sum = 0;
      } else {
        for (var i = start; i < end; i++) {
          sum += rawBins[i];
        }
        sum /= count;
      }
      final prev = smoothedBands[b];
      final alpha = sum > prev ? attack : release;
      smoothedBands[b] = prev + alpha * (sum - prev);
    }

    // Copy the smoothed bands so subscribers see a stable snapshot
    // (we keep mutating `_smoothedBands` on every frame).
    final bandsOut = Float32List(bandCount)..setAll(0, smoothedBands);

    return FftFrame(
      bins: rawBins,
      bands: bandsOut,
      timestamp: timestamp,
      sampleRate: sampleRate,
      bandLowHz: _settings.bandLowHz,
      bandHighHz: math.min(_settings.bandHighHz, sampleRate / 2.0),
    );
  }

  void _computeBandMapping(int sampleRate, int fftSize, int binCount) {
    final bandCount = _settings.bandCount;
    final bandLow = math.max(_settings.bandLowHz, 1.0);
    final nyquist = sampleRate / 2.0;
    final bandHigh = math.min(_settings.bandHighHz, nyquist);
    final start = Int32List(bandCount);
    final end = Int32List(bandCount);
    if (bandHigh <= bandLow || binCount <= 0) {
      _bandStartBin = start;
      _bandEndBin = end;
      return;
    }
    final binHz = sampleRate / fftSize;
    final ratio = math.pow(bandHigh / bandLow, 1 / bandCount).toDouble();
    for (var b = 0; b < bandCount; b++) {
      final lowHz = bandLow * math.pow(ratio, b);
      final highHz = bandLow * math.pow(ratio, b + 1);
      var s = (lowHz / binHz).floor();
      var e = (highHz / binHz).ceil();
      if (s < 0) s = 0;
      if (s >= binCount) s = binCount - 1;
      if (e <= s) e = s + 1;
      if (e > binCount) e = binCount;
      start[b] = s;
      end[b] = e;
    }
    _bandStartBin = start;
    _bandEndBin = end;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    if (!_spectrumCtrl.isClosed) await _spectrumCtrl.close();
    if (!_pcmCtrl.isClosed) await _pcmCtrl.close();
  }
}
