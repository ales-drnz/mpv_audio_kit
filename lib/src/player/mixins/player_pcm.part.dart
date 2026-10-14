// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Live PCM input: [openPcmStream] creates a [PcmSource] and opens it, and
/// dispose aborts the sources opened this way.
mixin _PcmModule on _PlayerBase {
  /// Creates a live [PcmSource] of [format] and opens it as the sole
  /// playlist entry, like [Player.open] with its [PcmSource.toMedia].
  /// Feed the returned source and [PcmSource.close] it when the input
  /// ends: the entry then ends normally after the last sample.
  ///
  /// Playback starts a fraction of a second after the first chunk, as
  /// soon as mpv has read its first block of audio. [maxBuffered] and
  /// [extras] are those of [PcmSource.create] and [PcmSource.toMedia].
  ///
  /// The player aborts the source when it is disposed. To queue several
  /// sources back to back, create them with [PcmSource.create] and pass
  /// their media to [Player.openAll] or [Player.add].
  ///
  /// ```dart
  /// final source = await player.openPcmStream(
  ///   const PcmFormat(sampleRate: 24000, channels: 1),
  /// );
  /// socket.listen(
  ///   (message) => source.add(message as Uint8List),
  ///   onDone: source.close,
  /// );
  /// ```
  Future<PcmSource> openPcmStream(
    PcmFormat format, {
    bool play = true,
    Duration maxBuffered = const Duration(seconds: 30),
    Map<String, Object?>? extras,
  }) async {
    _checkNotDisposed();
    final source = PcmSource.create(format, maxBuffered: maxBuffered);
    _pcmSources.add(source);
    unawaited(source.done.then((_) => _pcmSources.remove(source)));
    try {
      await (this as Player).open(source.toMedia(extras: extras), play: play);
    } catch (_) {
      source.abort();
      rethrow;
    }
    if (_disposed) source.abort();
    return source;
  }

  /// Aborts the sources [openPcmStream] opened (dispose).
  void _abortPcmSources() {
    for (final source in _pcmSources.toList()) {
      source.abort();
    }
    _pcmSources.clear();
  }
}
