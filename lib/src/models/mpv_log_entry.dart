// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// A structured log entry emitted by the mpv engine.
///
/// Received via [PlayerStream.log]. Filter by [level] to reduce noise.
///
/// Example:
/// ```dart
/// player.stream.log.listen((entry) {
///   if (entry.level == 'error') print('[${entry.prefix}] ${entry.text}');
/// });
/// ```
class MpvLogEntry {
  /// The mpv subsystem that generated this message (e.g. `'ffmpeg'`, `'demux'`).
  final String prefix;

  /// Severity level: `'trace'`, `'debug'`, `'v'`, `'info'`, `'warn'`, `'error'`, `'fatal'`.
  final String level;

  /// The raw log message text (may include a trailing newline).
  final String text;

  const MpvLogEntry({
    required this.prefix,
    required this.level,
    required this.text,
  });

  @override
  String toString() => '[$prefix] $level: $text';
}
