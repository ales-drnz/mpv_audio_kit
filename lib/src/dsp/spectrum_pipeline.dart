// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../models/fft_frame.dart';
import '../models/pcm_frame.dart';
import '../mpv_bindings.dart';
import '../types/settings/spectrum_settings.dart';
import 'band_processor.dart';
import 'dsp_async_io.dart';

/// Real-time FFT + raw PCM pipeline backed by the mpv `pcm-tap-frame`
/// property.
///
/// Owns two broadcast streams ([spectrumStream], [pcmStream]) and a
/// poll loop that reads `pcm-tap-frame` with an async get at the
/// configured emit rate. The poll loop is **lazy**: it starts on the
/// first listener (to either stream) and stops on the last cancel.
///
/// The pipeline:
///   1. Poll the property → MAP_NODE { sample_rate, channels, pts_ns, samples }.
///   2. Skip a stream when `pts_ns` matches the frame it got last (no new
///      audio). A stream's first listener gets the current frame, paused too.
///   3. Mix down to mono (mean of channels).
///   4. Multiply by the configured window function.
///   5. Real FFT (fftea) → magnitude per bin.
///   6. Power → 10·log₁₀ → clip [minDb, maxDb] → normalise [0, 1].
///   7. Aggregate bins into log-spaced bands (mean per band).
///   8. Apply asymmetric EMA on the bands (fast attack, slow release).
///   9. Emit [FftFrame] (raw bins + smoothed bands) and [PcmFrame].
@internal
class SpectrumPipeline {
  SpectrumPipeline({required AsyncPropertyGet asyncGet})
    : _asyncGet = asyncGet {
    _fftCtrl = StreamController<FftFrame>.broadcast(
      onListen: () {
        _fftActive = true;
        _lastFftPtsNs = 0;
        _maybeStart();
        _poll();
      },
      onCancel: () {
        _fftActive = false;
        _maybeStop();
      },
    );
    _pcmCtrl = StreamController<PcmFrame>.broadcast(
      onListen: () {
        _pcmActive = true;
        _lastPcmPtsNs = 0;
        _maybeStart();
        _poll();
      },
      onCancel: () {
        _pcmActive = false;
        _maybeStop();
      },
    );
  }

  final AsyncPropertyGet _asyncGet;

  late final StreamController<FftFrame> _fftCtrl;
  late final StreamController<PcmFrame> _pcmCtrl;

  Stream<FftFrame> get fftStream => _fftCtrl.stream;
  Stream<PcmFrame> get pcmStream => _pcmCtrl.stream;

  SpectrumSettings _settings = SpectrumSettings.defaults;
  SpectrumSettings get settings => _settings;

  bool _fftActive = false;
  bool _pcmActive = false;
  bool _disposed = false;
  Timer? _pollTimer;
  // Guards against overlapping async polls; see [LoudnessMeterPipeline].
  bool _polling = false;

  // Shared FFT, windowing and EMA pipeline: same component the
  // public [BandProcessor] exposes, so global and per-filter
  // spectrum surfaces stay byte-identical when fed equivalent PCM.
  late final BandProcessor _processor = BandProcessor(_settings);
  // The frame each stream got last. Paused, the output writes nothing and
  // every poll reads the same frame: a stream skips it once it has it.
  // Its first listener starts from 0, so it gets the frame the output
  // holds now (a listener that comes back while paused, an fft listener
  // next to a pcm one), and the other stream gets no duplicate.
  int _lastFftPtsNs = 0;
  int _lastPcmPtsNs = 0;

  /// Replaces the pipeline configuration. Reallocates FFT, window and
  /// EMA memory only on changes that require it; the poll timer is
  /// re-armed only when [SpectrumSettings.emitInterval] changes.
  void setSettings(SpectrumSettings next) {
    final emitChanged = next.emitInterval != _settings.emitInterval;
    _settings = next;
    _processor.setSettings(next);
    if (emitChanged && _pollTimer != null) {
      _pollTimer!.cancel();
      _pollTimer = Timer.periodic(_interval, (_) => _poll());
    }
  }

  /// The shortest poll period. A shorter [SpectrumSettings.emitInterval]
  /// (a zero one would poll as fast as replies come back) is raised to it.
  static const Duration minEmitInterval = Duration(milliseconds: 8);

  Duration get _interval => _settings.emitInterval < minEmitInterval
      ? minEmitInterval
      : _settings.emitInterval;

  void _maybeStart() {
    if (_disposed || _pollTimer != null) return;
    // [BandProcessor] allocates lazily on first [process], so we don't
    // need to prime anything here: just arm the poll loop.
    _pollTimer = Timer.periodic(_interval, (_) => _poll());
  }

  void _maybeStop() {
    if (_fftActive || _pcmActive) return;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _poll() {
    if (_disposed || _polling) return;
    if (!_fftActive && !_pcmActive) return;
    _polling = true;
    unawaited(_doPoll().whenComplete(() => _polling = false));
  }

  Future<void> _doPoll() async {
    final (rc, value) = await _asyncGet(
      'pcm-tap-frame',
      MpvFormat.mpvFormatNode,
    );
    if (_disposed) return;
    if (rc < 0 || value is! Map) return;

    // Scalars first: a stale frame (same pts as the previous poll, e.g.
    // while paused) is discarded BEFORE the sample buffer is reinterpreted.
    final sampleRate = value['sample_rate'] is int
        ? value['sample_rate'] as int
        : 0;
    final channels = value['channels'] is int ? value['channels'] as int : 0;
    final ptsNs = value['pts_ns'] is int ? value['pts_ns'] as int : 0;

    if (sampleRate <= 0 || channels <= 0 || ptsNs == 0) return;
    final fftNew = _fftActive && ptsNs != _lastFftPtsNs;
    final pcmNew = _pcmActive && ptsNs != _lastPcmPtsNs;
    if (!fftNew && !pcmNew) return;

    final samples = float32FromByteValue(value['samples']);
    if (samples == null) return;

    final timestamp = Duration(microseconds: ptsNs ~/ 1000);
    final pcm = PcmFrame(
      samples: samples,
      timestamp: timestamp,
      sampleRate: sampleRate,
      channels: channels,
    );

    if (pcmNew && !_pcmCtrl.isClosed) {
      _lastPcmPtsNs = ptsNs;
      _pcmCtrl.add(pcm);
    }

    if (fftNew && !_fftCtrl.isClosed) {
      _lastFftPtsNs = ptsNs;
      final frame = _processor.process(pcm);
      if (frame != null) _fftCtrl.add(frame);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    if (!_fftCtrl.isClosed) await _fftCtrl.close();
    if (!_pcmCtrl.isClosed) await _pcmCtrl.close();
  }
}
