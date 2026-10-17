// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../player.dart';

/// Builds the file-local `loadfile` `<options>` argument from a [Media]
/// and validates its load-time options (HTTP headers, chunk size, demuxer
/// lavf options) up-front. The `open`, `openAll` and `openPlaylistFile`
/// entry points and the audio and playlist mixins all reach these via the
/// abstract signatures on `_PlayerBase`.
mixin _LoadValidationModule on _PlayerBase {
  @override
  String _buildLoadfileOptions(Media media) => loadfileOptions(media);

  @override
  void _validateLoadOptions(Media media) => validateLoadOptions(media);

  /// Throws [ArgumentError] for a live PCM [media] on a path that cannot
  /// give it its load options (`audio-add`, `loadlist`): mpv would open it
  /// without them and use up its single reader.
  @override
  void _rejectPcm(Media media, String name) {
    if (!isPcmUri(media.uri)) return;
    throw ArgumentError.value(
      media.uri,
      name,
      'a live PcmSource plays only as a playlist entry '
      '(open, openAll, add, replace)',
    );
  }
}

/// Builds the `loadfile` `<options>` argument from a [Media]'s
/// `httpHeaders`, `httpChunkSize`, `demuxerLavfOptions` and `start`, and
/// the raw audio demuxer of a live PCM source. Each value is length-prefixed
/// (`%N%`) so the outer option-list parser doesn't split on the commas
/// inside it: hence the rejection of CR, LF, `,` and NUL in keys and
/// values (and `:` in keys) by [_validateHeaderKey] and
/// [_validateHeaderValue].
/// Returns `''` when the media carries none.
@visibleForTesting
String loadfileOptions(Media media) {
  _checkStart(media);
  final parts = <String>[];

  // A live PCM source: mpv's raw audio demuxer in the source's format.
  final pcm = pcmLoadOptions(media.uri);
  if (pcm != null) parts.add(pcm);

  final headers = media.httpHeaders;
  if (headers != null && headers.isNotEmpty) {
    for (final e in headers.entries) {
      _validateHeaderKey(e.key);
      _validateHeaderValue(e.value);
    }
    final joined = headers.entries.map((e) => '${e.key}: ${e.value}').join(',');
    parts.add('http-header-fields=%${utf8.encode(joined).length}%$joined');
  }

  final chunk = media.httpChunkSize;
  if (chunk != null) {
    if (chunk <= 0) {
      throw ArgumentError.value(
        chunk,
        'httpChunkSize',
        'must be a positive byte count (or null to disable)',
      );
    }
    // Cap every HTTP range request to `chunk` bytes so a throttling CDN
    // (e.g. googlevideo) keeps serving at full speed instead of slowing an
    // unbounded whole-file request to a crawl; `reconnect_*` recover genuine
    // drops (mpv already sets `reconnect=1`).
    //
    // Why BOTH options (verified against FFmpeg 8.1.1 `libavformat/http.c`):
    //   • `request_size` bounds EVERY request, the first one included: the
    //     gate is `if (s->initial_requests || s->request_size)` (http.c:1594)
    //     and mpv leaves `seekable` unset (→ -1, ≠ 0), so the bounded-range
    //     branch is taken even for the opening probe.
    //   • `initial_request_size` only overrides the size used for that probe;
    //     after the first chunk ffmpeg clears `initial_requests` (http.c:1857),
    //     so on its own the steady-state reads would revert to an unbounded
    //     `Range: bytes=off-`.
    // Setting both keeps the probe AND every steady-state read bounded.
    // (`request_size` alone would also suffice here; `initial_request_size`
    // alone would NOT: chunk 2+ would go unbounded.)
    final value =
        'initial_request_size=$chunk,request_size=$chunk,'
        'reconnect_streamed=1,reconnect_on_network_error=1';
    parts.add('stream-lavf-o=%${utf8.encode(value).length}%$value');
  }

  final lavf = media.demuxerLavfOptions;
  if (lavf != null && lavf.isNotEmpty) {
    for (final e in lavf.entries) {
      _validateDemuxerLavfOption(e.key, e.value);
    }
    // File-local `demuxer-lavf-o`, scoped to this entry like the options
    // above. Entries are comma-joined (validated comma-free).
    final value = lavf.entries.map((e) => '${e.key}=${e.value}').join(',');
    parts.add('demuxer-lavf-o=%${utf8.encode(value).length}%$value');
  }

  // mpv applies it after a resume point it loads for the file, so it wins.
  final start = media.start;
  if (start != null) parts.add('start=${durationToOption(start)}');

  return parts.join(',');
}

/// Throws [ArgumentError] for a negative [Media.start], or one on a live
/// PCM entry, which is not seekable and plays from its first chunk.
void _checkStart(Media media) {
  final start = media.start;
  if (start == null) return;
  if (start.isNegative) {
    throw ArgumentError.value(start, 'start', 'must not be negative');
  }
  if (isPcmUri(media.uri)) {
    throw ArgumentError.value(
      start,
      'start',
      'a live PcmSource plays from its first chunk',
    );
  }
}

final RegExp _kForbiddenInHeaderKey = RegExp(r'[\r\n,:\x00]');
final RegExp _kForbiddenInHeaderValue = RegExp(r'[\r\n,\x00]');

/// Up-front validator for a [Media]'s load-time options, called by every
/// load entry point before `resolveUri` runs so a bad value fails fast,
/// before any optimistic state write.
@visibleForTesting
void validateLoadOptions(Media media) {
  _checkStart(media);
  pcmLoadOptions(media.uri);
  final headers = media.httpHeaders;
  if (headers != null && headers.isNotEmpty) {
    for (final e in headers.entries) {
      _validateHeaderKey(e.key);
      _validateHeaderValue(e.value);
    }
  }
  final chunk = media.httpChunkSize;
  if (chunk != null && chunk <= 0) {
    throw ArgumentError.value(
      chunk,
      'httpChunkSize',
      'must be a positive byte count (or null to disable)',
    );
  }
  final lavf = media.demuxerLavfOptions;
  if (lavf != null && lavf.isNotEmpty) {
    for (final e in lavf.entries) {
      _validateDemuxerLavfOption(e.key, e.value);
    }
  }
}

final RegExp _kForbiddenInLavfOption = RegExp(r'[\r\n,\x00]');

/// A `demuxer-lavf-o` entry sits in a comma-separated list, so its key and
/// value must be non-empty and free of comma, CR, LF and NUL. Mirrors the
/// header validators.
void _validateDemuxerLavfOption(String key, String value) {
  if (key.isEmpty) {
    throw ArgumentError.value(
      key,
      'demuxerLavfOptions key',
      'must not be empty',
    );
  }
  if (_kForbiddenInLavfOption.hasMatch(key) ||
      _kForbiddenInLavfOption.hasMatch(value)) {
    throw ArgumentError.value(
      '$key=$value',
      'demuxerLavfOptions',
      'must not contain CR, LF, NUL, or comma',
    );
  }
}

void _validateHeaderKey(String key) {
  if (key.isEmpty) {
    throw ArgumentError.value(key, 'header name', 'must not be empty');
  }
  if (_kForbiddenInHeaderKey.hasMatch(key)) {
    throw ArgumentError.value(
      key,
      'header name',
      'must not contain CR, LF, NUL, comma, or colon',
    );
  }
}

void _validateHeaderValue(String value) {
  if (_kForbiddenInHeaderValue.hasMatch(value)) {
    throw ArgumentError.value(
      value,
      'header value',
      'must not contain CR, LF, NUL, or comma (would split or inject the HTTP request)',
    );
  }
}
