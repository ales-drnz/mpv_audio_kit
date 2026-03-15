part of '../player.dart';

/// Module for network, cache, and buffering configuration.
mixin _NetworkModule on _PlayerBase {
  /// Seconds of network data fetched ahead of the playback position.
  Future<void> setCacheSecs(double seconds) async {
    _checkNotDisposed();
    _prop('cache-secs', seconds.toStringAsFixed(1));
    _updateState((s) => s.copyWith(cacheSecs: seconds), _cacheSecsCtrl, seconds);
  }

  /// Cache behavior: `'yes'`, `'no'`, or `'auto'`.
  Future<void> setCache(String mode) async {
    _checkNotDisposed();
    _prop('cache', mode);
    _updateState((s) => s.copyWith(cacheMode: mode), _cacheModeCtrl, mode);
  }

  /// Whether to spill overflow cache to temporary disk files.
  Future<void> setCacheOnDisk(bool enable) async {
    _checkNotDisposed();
    _prop('cache-on-disk', enable ? 'yes' : 'no');
    _updateState((s) => s.copyWith(cacheOnDisk: enable), _cacheOnDiskCtrl, enable);
  }

  /// Sets the audio buffer size in seconds.
  Future<void> setAudioBuffer(double seconds) async {
    _checkNotDisposed();
    _prop('audio-buffer', seconds.toStringAsFixed(3));
    _updateState((s) => s.copyWith(audioBuffer: seconds), _audioBufferCtrl, seconds);
  }

  /// Enables or disables streaming silence when no audio is playing.
  Future<void> setStreamSilence(bool enable) async {
    _checkNotDisposed();
    _prop('stream-silence', enable ? 'yes' : 'no');
    _updateState((s) => s.copyWith(streamSilence: enable), _streamSilenceCtrl, enable);
  }

  /// Whether to automatically pause when the cache runs empty.
  Future<void> setCachePause(bool enable) async {
    _checkNotDisposed();
    _prop('cache-pause', enable ? 'yes' : 'no');
    _updateState((s) => s.copyWith(cachePause: enable), _cachePauseCtrl, enable);
  }

  /// Seconds of pre-buffering required before auto-resuming after a stall.
  Future<void> setCachePauseWait(double seconds) async {
    _checkNotDisposed();
    _prop('cache-pause-wait', seconds.toStringAsFixed(1));
    _updateState((s) => s.copyWith(cachePauseWait: seconds), _cachePauseWaitCtrl, seconds);
  }

  /// Network connection timeout in seconds.
  Future<void> setNetworkTimeout(double seconds) async {
    _checkNotDisposed();
    _prop('network-timeout', seconds.toString());
    _updateState((s) => s.copyWith(networkTimeout: seconds), _networkTimeoutCtrl, seconds);
  }

  /// Whether to verify TLS/SSL certificates for network streams.
  Future<void> setTlsVerify(bool enable) async {
    _checkNotDisposed();
    _prop('tls-verify', enable ? 'yes' : 'no');
    _updateState((s) => s.copyWith(tlsVerify: enable), _tlsVerifyCtrl, enable);
  }

  /// Sets the maximum bytes the demuxer is allowed to cache.
  Future<void> setDemuxerMaxBytes(int bytes) async {
    _checkNotDisposed();
    final mib = bytes ~/ (1024 * 1024);
    _prop('demuxer-max-bytes', '${mib}MiB');
    _updateState((s) => s.copyWith(demuxerMaxBytes: bytes), _demuxerMaxBytesCtrl, bytes);
  }

  /// Sets the maximum seekback buffer size.
  Future<void> setDemuxerMaxBackBytes(int bytes) async {
    _checkNotDisposed();
    final mib = bytes ~/ (1024 * 1024);
    _prop('demuxer-max-back-bytes', '${mib}MiB');
    _updateState((s) => s.copyWith(demuxerMaxBackBytes: bytes), _demuxerMaxBackBytesCtrl, bytes);
  }

  /// Sets the demuxer readahead time.
  Future<void> setDemuxerReadaheadSecs(int seconds) async {
    _checkNotDisposed();
    _prop('demuxer-readahead-secs', seconds.toString());
    _updateState((s) => s.copyWith(demuxerReadaheadSecs: seconds), _demuxerReadaheadSecsCtrl, seconds);
  }

  /// Whether to fallback to untimed null output if audio output fails.
  Future<void> setAoNullUntimed(bool enable) async {
    _checkNotDisposed();
    _prop('ao-null-untimed', enable ? 'yes' : 'no');
    _updateState((s) => s.copyWith(aoNullUntimed: enable), _aoNullUntimedCtrl, enable);
  }
}
