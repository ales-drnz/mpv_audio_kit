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

/// The `stream-lavf-o` entries of every `http://` and `https://` entry,
/// below what [Media.httpChunkSize] and [Media.streamLavfOptions] set
/// (verified against FFmpeg 8.1.1 and mpv 0.41):
/// - `reconnect` and `reconnect_delay_max` are mpv's own values for a
///   progressive stream (stream_lavf.c), which it does not pass to the
///   segments of an HLS or DASH stream. Through `stream-lavf-o` they reach
///   them: demux_lavf.c hands the network options to every nested open.
///   FFmpeg then requests a body cut short again from where it stopped, on
///   a server that accepts ranges (http.c, http_read_stream), after 0, 1,
///   3 and 7 s.
/// - `reconnect_on_network_error` tries a connection that fails to open
///   (refused, reset, DNS, TLS) again on the same schedule (http.c,
///   http_open_cnx), for the open and for each of those reconnects.
/// - `seg_max_retry` is an option of the HLS demuxer, which takes the
///   network options as its own (demux_lavf.c sets them on a demuxer that
///   opens its URL itself). With FFmpeg's 0 a segment that fails to open is
///   skipped at once (hls.c, read_data_continuous). 4 gives it as many
///   retries as a progressive stream gets reconnects. Through
///   `demuxer-lavf-o` it would also drop the prefetch of the entry: that
///   option rebuilds the demuxer when it changes.
/// `reconnect_streamed` is not among them: on a server without range
/// support FFmpeg reconnects from the first byte, so a file cut short
/// plays again from its start, and one sent with no length plays over and
/// over. A live stream asks for it with [Media.streamLavfOptions].
const Map<String, String> _kHttpStreamOptions = {
  'reconnect': '1',
  'reconnect_delay_max': '7',
  'reconnect_on_network_error': '1',
  'seg_max_retry': '4',
};

/// Whether [uri] is an `http://` or `https://` URL.
bool _isHttp(String uri) {
  final head = (uri.length < 8 ? uri : uri.substring(0, 8)).toLowerCase();
  return head.startsWith('http://') || head.startsWith('https://');
}

/// Builds the `loadfile` `<options>` argument from a [Media]'s
/// `httpHeaders`, `httpChunkSize`, `streamLavfOptions`, `demuxerLavfOptions`,
/// `start` and `end`, the stream options of an `http://` or `https://`
/// entry ([_kHttpStreamOptions]), and the raw audio demuxer of a live PCM
/// source. Each value is length-prefixed
/// (`%N%`) so the outer option-list parser doesn't split on the commas
/// inside it. The headers still refuse some characters
/// ([_validateHeaderKey], [_validateHeaderValue]): `,`, since
/// `http-header-fields` is itself a comma-separated list; CR, LF and NUL,
/// which would inject into the HTTP request; and `:` in keys.
/// Returns `''` when the media carries none.
@visibleForTesting
String loadfileOptions(Media media) {
  _checkPlayRange(media);
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

  final stream = _streamOptions(media);
  if (stream.isNotEmpty) parts.add(_keyValueOption('stream-lavf-o', stream));

  final lavf = media.demuxerLavfOptions;
  if (lavf != null && lavf.isNotEmpty) {
    for (final e in lavf.entries) {
      _validateLavfOption(e.key, e.value, 'demuxerLavfOptions');
    }
    // File-local `demuxer-lavf-o`, scoped to this entry like the options
    // above.
    parts.add(_keyValueOption('demuxer-lavf-o', lavf));
  }

  // mpv applies it after a resume point it loads for the file, so it wins.
  final start = media.start;
  if (start != null) parts.add('start=${durationToOption(start)}');
  final end = media.end;
  if (end != null) parts.add('end=${durationToOption(end)}');

  return parts.join(',');
}

/// The `stream-lavf-o` entries of [media], each key once: the defaults of
/// an `http://` or `https://` entry, then those of its chunk size, then its
/// own options, a later value replacing an earlier one.
Map<String, String> _streamOptions(Media media) {
  final stream = <String, String>{
    if (_isHttp(media.uri)) ..._kHttpStreamOptions,
  };
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
    stream.addAll({
      'initial_request_size': '$chunk',
      'request_size': '$chunk',
      'reconnect_streamed': '1',
      'reconnect_on_network_error': '1',
    });
  }
  final own = media.streamLavfOptions;
  if (own != null) {
    for (final e in own.entries) {
      _validateLavfOption(e.key, e.value, 'streamLavfOptions');
    }
    stream.addAll(own);
  }
  return stream;
}

/// The file-local option [name] holding [entries] as `key=value` pairs,
/// comma-joined (each validated comma-free) and length-prefixed.
String _keyValueOption(String name, Map<String, String> entries) {
  final value = entries.entries.map((e) => '${e.key}=${e.value}').join(',');
  return '$name=%${utf8.encode(value).length}%$value';
}

/// Throws [ArgumentError] for a negative [Media.start], an [Media.end]
/// not later than the start (or zero), or either on a live PCM entry,
/// which is not seekable and plays from its first chunk to its last.
void _checkPlayRange(Media media) {
  final start = media.start;
  final end = media.end;
  if (start != null && start.isNegative) {
    throw ArgumentError.value(start, 'start', 'must not be negative');
  }
  if (end != null && end <= (start ?? Duration.zero)) {
    throw ArgumentError.value(
      end,
      'end',
      start == null ? 'must be later than zero' : 'must be later than start',
    );
  }
  if (isPcmUri(media.uri)) {
    if (start != null) {
      throw ArgumentError.value(
        start,
        'start',
        'a live PcmSource plays from its first chunk',
      );
    }
    if (end != null) {
      throw ArgumentError.value(
        end,
        'end',
        'a live PcmSource plays to its last chunk',
      );
    }
  }
}

final RegExp _kForbiddenInHeaderKey = RegExp(r'[\r\n,:\x00]');
final RegExp _kForbiddenInHeaderValue = RegExp(r'[\r\n,\x00]');

/// Up-front validator for a [Media]'s load-time options, called by every
/// load entry point before `resolveUri` runs so a bad value fails fast,
/// before any optimistic state write.
@visibleForTesting
void validateLoadOptions(Media media) {
  _checkPlayRange(media);
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
  for (final (name, options) in [
    ('streamLavfOptions', media.streamLavfOptions),
    ('demuxerLavfOptions', media.demuxerLavfOptions),
  ]) {
    for (final e in options?.entries ?? const <MapEntry<String, String>>[]) {
      _validateLavfOption(e.key, e.value, name);
    }
  }
}

final RegExp _kForbiddenInLavfOption = RegExp(r'[\r\n,\x00]');

/// A `stream-lavf-o` or `demuxer-lavf-o` entry sits in a comma-separated
/// list, so its key must be non-empty and the key and value free of comma,
/// CR, LF and NUL. [name] is the [Media] field it came from. Mirrors the
/// header validators.
void _validateLavfOption(String key, String value, String name) {
  if (key.isEmpty) {
    throw ArgumentError.value(key, '$name key', 'must not be empty');
  }
  if (_kForbiddenInLavfOption.hasMatch(key) ||
      _kForbiddenInLavfOption.hasMatch(value)) {
    throw ArgumentError.value(
      '$key=$value',
      name,
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
