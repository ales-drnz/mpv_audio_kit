// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Module for network, cache, and buffering configuration.
mixin _NetworkModule on _PlayerBase {
  /// Amount of network data fetched ahead of the playback position.
  ///
  /// Sub-second precision is preserved (sent to mpv as a fractional float).
  Future<void> setCacheSecs(Duration secs) async {
    _checkNotDisposed();
    _prop('cache-secs', durationToSeconds(secs).toStringAsFixed(3));
    _updateField(
        (s) => s.copyWith(cacheSecs: secs), _reactives.cacheSecs, secs);
  }

  /// Cache behavior. See [CacheMode] for the available variants.
  Future<void> setCache(CacheMode mode) async {
    _checkNotDisposed();
    _prop('cache', mode.mpvValue);
    _updateField(
        (s) => s.copyWith(cacheMode: mode), _reactives.cacheMode, mode);
  }

  /// Whether to spill overflow cache to temporary disk files.
  Future<void> setCacheOnDisk(bool enable) async {
    _checkNotDisposed();
    _prop('cache-on-disk', enable ? 'yes' : 'no');
    _updateField((s) => s.copyWith(cacheOnDisk: enable), _reactives.cacheOnDisk, enable);
  }

  /// Sets the audio buffer size.
  Future<void> setAudioBuffer(Duration size) async {
    _checkNotDisposed();
    _prop('audio-buffer', durationToSeconds(size).toStringAsFixed(3));
    _updateField(
        (s) => s.copyWith(audioBuffer: size), _reactives.audioBuffer, size);
  }

  /// Enables or disables streaming silence when no audio is playing.
  Future<void> setAudioStreamSilence(bool enable) async {
    _checkNotDisposed();
    _prop('audio-stream-silence', enable ? 'yes' : 'no');
    _updateField((s) => s.copyWith(audioStreamSilence: enable), _reactives.audioStreamSilence, enable);
  }

  /// Whether to automatically pause when the cache runs empty.
  Future<void> setCachePause(bool enable) async {
    _checkNotDisposed();
    _prop('cache-pause', enable ? 'yes' : 'no');
    _updateField((s) => s.copyWith(cachePause: enable), _reactives.cachePause, enable);
  }

  /// Pre-buffer required before auto-resuming after a stall.
  Future<void> setCachePauseWait(Duration wait) async {
    _checkNotDisposed();
    _prop('cache-pause-wait', durationToSeconds(wait).toStringAsFixed(3));
    _updateField((s) => s.copyWith(cachePauseWait: wait),
        _reactives.cachePauseWait, wait);
  }

  /// Network connection timeout. mpv accepts integer seconds only, so the
  /// value is rounded down before being sent.
  Future<void> setNetworkTimeout(Duration timeout) async {
    _checkNotDisposed();
    final seconds = timeout.inSeconds;
    _prop('network-timeout', seconds.toString());
    _updateField((s) => s.copyWith(networkTimeout: timeout),
        _reactives.networkTimeout, timeout);
  }

  /// Whether to verify TLS/SSL certificates for network streams.
  Future<void> setTlsVerify(bool enable) async {
    _checkNotDisposed();
    _prop('tls-verify', enable ? 'yes' : 'no');
    _updateField((s) => s.copyWith(tlsVerify: enable), _reactives.tlsVerify, enable);
  }

  /// Sets the maximum bytes the demuxer is allowed to cache.
  Future<void> setDemuxerMaxBytes(int bytes) async {
    _checkNotDisposed();
    final mib = bytes ~/ (1024 * 1024);
    _prop('demuxer-max-bytes', '${mib}MiB');
    _updateField((s) => s.copyWith(demuxerMaxBytes: bytes), _reactives.demuxerMaxBytes, bytes);
  }

  /// Sets the maximum seekback buffer size.
  Future<void> setDemuxerMaxBackBytes(int bytes) async {
    _checkNotDisposed();
    final mib = bytes ~/ (1024 * 1024);
    _prop('demuxer-max-back-bytes', '${mib}MiB');
    _updateField((s) => s.copyWith(demuxerMaxBackBytes: bytes), _reactives.demuxerMaxBackBytes, bytes);
  }

  /// Sets the demuxer readahead time.
  Future<void> setDemuxerReadaheadSecs(int seconds) async {
    _checkNotDisposed();
    _prop('demuxer-readahead-secs', seconds.toString());
    _updateField((s) => s.copyWith(demuxerReadaheadSecs: seconds), _reactives.demuxerReadaheadSecs, seconds);
  }

  /// Whether to fallback to untimed null output if audio output fails.
  Future<void> setAudioNullUntimed(bool enable) async {
    _checkNotDisposed();
    _prop('ao-null-untimed', enable ? 'yes' : 'no');
    _updateField((s) => s.copyWith(audioNullUntimed: enable), _reactives.audioNullUntimed, enable);
  }
}
