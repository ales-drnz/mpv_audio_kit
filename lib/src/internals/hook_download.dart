// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The build hook's download, apart so a test can drive it against a local
// server.

import 'dart:async';
import 'dart:io';

/// An HTTP answer that ends the download: a status other than 200 below
/// 500 (a 404, a 403), or a 5xx still failing after the last attempt.
class DownloadRefused implements Exception {
  /// The refusal of [url] with [statusCode].
  DownloadRefused(this.statusCode, this.url);

  /// The HTTP status of the answer.
  final int statusCode;

  /// The URL that was refused.
  final String url;

  @override
  String toString() =>
      'mpv_audio_kit: HTTP $statusCode for $url'
      '${statusCode == HttpStatus.notFound ? '. The pinned libmpv release '
                'may not be published yet: point the libmpv user define at '
                'a local copy (see hook/build.dart)' : ''}';
}

/// Downloads [url] into [target]. A connection that does not open within
/// [connectTimeout], or a body that sends nothing for [idleTimeout], counts
/// as a network failure, and a network failure (or a 5xx answer) is tried
/// again, up to [attempts] times in all, waiting [backoff] and then twice
/// as long. A 5xx after the last attempt throws [DownloadRefused], and any
/// other HTTP status throws it at once.
Future<void> download(
  String url,
  File target, {
  Duration connectTimeout = const Duration(seconds: 30),
  Duration idleTimeout = const Duration(seconds: 60),
  int attempts = 3,
  Duration backoff = const Duration(seconds: 2),
}) async {
  var wait = backoff;
  for (var attempt = 1; ; attempt++) {
    try {
      await _downloadOnce(url, target, connectTimeout, idleTimeout);
      return;
    } on DownloadRefused {
      rethrow;
    } on Object catch (e) {
      final retryable =
          e is SocketException ||
          e is TimeoutException ||
          e is HttpException ||
          e is HandshakeException ||
          e is _ServerError;
      if (!retryable || attempt >= attempts) {
        if (e is _ServerError) throw DownloadRefused(e.statusCode, url);
        rethrow;
      }
      stderr.writeln(
        'mpv_audio_kit: download of $url failed ($e), '
        'attempt $attempt of $attempts; retrying in ${wait.inSeconds} s',
      );
      await Future<void>.delayed(wait);
      wait *= 2;
    }
  }
}

class _ServerError implements Exception {
  _ServerError(this.statusCode);
  final int statusCode;
  @override
  String toString() => 'HTTP $statusCode';
}

Future<void> _downloadOnce(
  String url,
  File target,
  Duration connectTimeout,
  Duration idleTimeout,
) async {
  final client = HttpClient()
    ..findProxy = HttpClient.findProxyFromEnvironment
    ..connectionTimeout = connectTimeout
    ..idleTimeout = idleTimeout;
  try {
    final request = await client.getUrl(Uri.parse(url)).timeout(connectTimeout);
    final response = await request.close().timeout(idleTimeout);
    if (response.statusCode >= 500) {
      await response.drain<void>().catchError((_) {});
      throw _ServerError(response.statusCode);
    }
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>().catchError((_) {});
      throw DownloadRefused(response.statusCode, url);
    }
    final sink = target.openWrite();
    try {
      await sink.addStream(response.timeout(idleTimeout));
    } finally {
      // After a failed addStream close() reports that failure again, as a
      // closed file: the one thrown above is the one to keep.
      await sink.close().then<void>((_) {}, onError: (Object _) {});
    }
    final expected = response.contentLength;
    if (expected >= 0 && await target.length() != expected) {
      throw HttpException(
        'body cut short: ${await target.length()} of $expected bytes',
        uri: Uri.parse(url),
      );
    }
  } finally {
    client.close(force: true);
  }
}
