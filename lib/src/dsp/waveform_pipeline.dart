// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../models/waveform_data.dart';
import 'analysis_poll_pipeline.dart';
import 'dsp_async_io.dart';

/// Static waveform pipeline: polls `waveform-data` while
/// [PlayerStream.waveform] has a listener (`waveform-enabled` on), see
/// [AnalysisPollPipeline].
///
/// As soon as the analyzer reports `state == "ready"` the assembled
/// envelope is emitted once via [stream] and the timer stops until the
/// next track-change. On track change the player calls [reset]: the
/// pipeline drops the current envelope, emits `null`, and rearms the
/// timer if still enabled.
@internal
class WaveformPipeline extends AnalysisPollPipeline<WaveformData> {
  WaveformPipeline({
    required super.asyncGet,
    required super.asyncSet,
    super.pollInterval,
  }) : super(
         enabledProperty: 'waveform-enabled',
         dataProperty: 'waveform-data',
       );

  // Last coverage seen while DECODING, to skip re-emitting unchanged partials.
  int? _lastDecodeCoverage;

  @override
  void onDrop() => _lastDecodeCoverage = null;

  @override
  void onData(Map<Object?, Object?> value) {
    final stateValue = value['state'];
    final state = stateValue is String ? stateValue : null;
    final durationUs = value['duration_us'] is int
        ? value['duration_us'] as int
        : 0;
    final rangeStartUs = value['range_start_us'] is int
        ? value['range_start_us'] as int
        : 0;
    final rangeEndUs = value['range_end_us'] is int
        ? value['range_end_us'] as int
        : 0;
    final min = float32FromByteValue(value['min']);
    final max = float32FromByteValue(value['max']);
    // Absent before libmpv-r14; null then, like a length mismatch.
    final rmsValue = float32FromByteValue(value['rms']);
    final filled = value['filled'] is Uint8List
        ? value['filled'] as Uint8List
        : null;

    final ready = state == 'ready';
    final progressive = state == 'progressive';
    final rolling = state == 'rolling';
    final decoding = state == 'decoding';
    final coverageBins = value['coverage_bins'] is int
        ? value['coverage_bins'] as int
        : null;
    final totalBins = value['total_bins'] is int
        ? value['total_bins'] as int
        : null;

    final haveBins =
        min != null &&
        max != null &&
        min.isNotEmpty &&
        min.length == max.length;
    final rms =
        (rmsValue != null && min != null && rmsValue.length == min.length)
        ? rmsValue
        : null;

    // Fall back to all-covered if the native side omitted/mismatched the
    // flags, so the renderer never misreads it.
    Uint8List safeFilled(Float32List m) =>
        (filled != null && filled.length == m.length)
        ? filled
        : (Uint8List(m.length)..fillRange(0, m.length, 1));

    // ROLLING (true live, unknown total): a sliding window keyed to the
    // demuxer cache. The native side reports the absolute range it holds;
    // the envelope grows and slides, so never cache it — keep polling.
    if (rolling && haveBins && rangeEndUs > rangeStartUs) {
      final data = WaveformData(
        start: Duration(microseconds: rangeStartUs),
        duration: Duration(microseconds: rangeEndUs - rangeStartUs),
        min: min,
        max: max,
        rms: rms,
        filled: safeFilled(min),
        live: true,
      );
      emit(data);
      return;
    }

    // DECODING (local-file bulk analysis in flight): a partial envelope that
    // grows on every poll. The full axis is emitted with [filled] marking the
    // regions decoded so far. Never cache it and never stop the timer — the
    // final `ready` emission below supersedes it. De-dup on coverage so an
    // unchanged snapshot does not churn the UI.
    if (decoding && durationUs > 0 && haveBins) {
      if (coverageBins == null || coverageBins != _lastDecodeCoverage) {
        _lastDecodeCoverage = coverageBins;
        final data = WaveformData(
          duration: Duration(microseconds: durationUs),
          min: min,
          max: max,
          rms: rms,
          filled: safeFilled(min),
          decoding: true,
          coverageBins: coverageBins,
          totalBins: totalBins,
        );
        emit(data);
      }
      return;
    }

    if ((ready || progressive) && durationUs > 0 && haveBins) {
      final data = WaveformData(
        duration: Duration(microseconds: durationUs),
        min: min,
        max: max,
        rms: rms,
        filled: safeFilled(min),
      );
      if (ready) {
        // Bulk envelope is final: keep it and stop polling.
        finish(data);
        return;
      }
      // Progressive (network) envelope grows: keep the timer running so
      // each poll drives the native fold and emits the grown envelope.
      emit(data);
      return;
    }
    if (state == 'failed') {
      // No envelope is coming (true live / unsupported). Stop polling
      // and clear — there is nothing further to wait for.
      stopPolling();
      emit(null);
    }
  }
}
