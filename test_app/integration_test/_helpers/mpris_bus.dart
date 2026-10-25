// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'dart:io';

/// The MPRIS2 service of one process on the session bus, read and driven
/// with gdbus, as a desktop shell sees it. Plain Dart, so the parser can be
/// checked off the app against any MPRIS service.
class MprisBus {
  MprisBus(this.busName);

  /// The bus name linux/mpris_server.cc takes:
  /// `org.mpris.MediaPlayer2.<appName>.instance<pid>`, with every character
  /// of [appName] that is not a letter or a digit turned into `_`.
  factory MprisBus.of(String appName, int pid) {
    var suffix = appName.replaceAll(RegExp('[^A-Za-z0-9]'), '_');
    if (suffix.isEmpty) suffix = 'mpv_audio_kit';
    if (RegExp('^[0-9]').hasMatch(suffix)) suffix = '_$suffix';
    return MprisBus('org.mpris.MediaPlayer2.$suffix.instance$pid');
  }

  final String busName;

  static const objectPath = '/org/mpris/MediaPlayer2';
  static const rootIface = 'org.mpris.MediaPlayer2';
  static const playerIface = 'org.mpris.MediaPlayer2.Player';

  /// Whether some connection owns [busName] right now.
  Future<bool> hasOwner() async {
    final reply = await _gdbus([
      '--dest',
      'org.freedesktop.DBus',
      '--object-path',
      '/org/freedesktop/DBus',
      '--method',
      'org.freedesktop.DBus.NameHasOwner',
      busName,
    ]);
    return (parseGVariant(reply) as List).single as bool;
  }

  /// One property of [iface], through org.freedesktop.DBus.Properties.
  Future<Object?> property(String iface, String name) async {
    final reply = await _gdbus([
      '--dest',
      busName,
      '--object-path',
      objectPath,
      '--method',
      'org.freedesktop.DBus.Properties.Get',
      iface,
      name,
    ]);
    return (parseGVariant(reply) as List).single;
  }

  Future<String> playbackStatus() async =>
      await property(playerIface, 'PlaybackStatus') as String;

  Future<Map<String, Object?>> metadata() async =>
      Map<String, Object?>.from(await property(playerIface, 'Metadata') as Map);

  /// Calls [method] of the player interface. [args] are GVariant text, with
  /// their type when it is not a string, e.g. `int64 500000`.
  Future<void> call(String method, [List<String> args = const []]) => _gdbus([
    '--dest',
    busName,
    '--object-path',
    objectPath,
    '--method',
    '$playerIface.$method',
    '--',
    ...args,
  ]);

  Future<String> _gdbus(List<String> args) async {
    final result = await Process.run('gdbus', ['call', '--session', ...args]);
    if (result.exitCode != 0) {
      throw ProcessException(
        'gdbus',
        args,
        '${result.stderr}'.trim(),
        result.exitCode,
      );
    }
    return '${result.stdout}'.trim();
  }
}

/// Parses the GVariant text gdbus prints (g_variant_print with types):
/// tuples and arrays become lists, dictionaries maps, variants their value,
/// the numbers int or double, strings and object paths String.
Object? parseGVariant(String text) {
  final parser = _GVariantParser(text);
  final value = parser.value();
  parser.skipSpace();
  if (!parser.atEnd) {
    throw FormatException('trailing text', text, parser.pos);
  }
  return value;
}

class _GVariantParser {
  _GVariantParser(this.text);

  final String text;
  int pos = 0;

  static const _typeWords = {
    'boolean',
    'byte',
    'int16',
    'uint16',
    'int32',
    'uint32',
    'int64',
    'uint64',
    'handle',
    'double',
    'string',
    'objectpath',
    'signature',
  };

  bool get atEnd => pos >= text.length;

  void skipSpace() {
    while (!atEnd && ' \t\n\r'.contains(text[pos])) {
      pos++;
    }
  }

  Never _fail(String what) => throw FormatException(what, text, pos);

  void _expect(String c) {
    skipSpace();
    if (atEnd || text[pos] != c) _fail('expected $c');
    pos++;
  }

  /// Whether the next character, after spaces, is [c]; consumes it if so.
  bool _take(String c) {
    skipSpace();
    if (!atEnd && text[pos] == c) {
      pos++;
      return true;
    }
    return false;
  }

  Object? value() {
    skipSpace();
    if (atEnd) _fail('expected a value');
    final c = text[pos];
    switch (c) {
      case '(':
        pos++;
        return _items(')');
      case '[':
        pos++;
        return _items(']');
      case '<':
        pos++;
        final inner = value();
        _expect('>');
        return inner;
      case '{':
        pos++;
        return _dict();
      case "'":
      case '"':
        return _string();
      case '@':
        // A type for what follows, e.g. `@as []`: the value says enough.
        while (!atEnd && !' \t\n'.contains(text[pos])) {
          pos++;
        }
        return value();
    }
    final word = RegExp(
      r'[A-Za-z_][A-Za-z0-9_]*',
    ).matchAsPrefix(text, pos)?.group(0);
    if (word != null) {
      pos += word.length;
      if (word == 'true') return true;
      if (word == 'false') return false;
      if (word == 'nothing') return null;
      if (word == 'just') return value();
      if (_typeWords.contains(word)) return value();
      _fail('unknown word $word');
    }
    return _number();
  }

  List<Object?> _items(String close) {
    final items = <Object?>[];
    if (_take(close)) return items;
    while (true) {
      items.add(value());
      if (_take(close)) return items;
      _expect(',');
      // A one-element tuple ends with a comma: `(<'Playing'>,)`.
      if (_take(close)) return items;
    }
  }

  Map<Object?, Object?> _dict() {
    final map = <Object?, Object?>{};
    if (_take('}')) return map;
    while (true) {
      final key = value();
      _expect(':');
      map[key] = value();
      if (_take('}')) return map;
      _expect(',');
    }
  }

  String _string() {
    final quote = text[pos++];
    final out = StringBuffer();
    while (true) {
      if (atEnd) _fail('unterminated string');
      final c = text[pos++];
      if (c == quote) return out.toString();
      if (c != r'\') {
        out.write(c);
        continue;
      }
      if (atEnd) _fail('unterminated escape');
      final e = text[pos++];
      switch (e) {
        case 'n':
          out.write('\n');
        case 't':
          out.write('\t');
        case 'r':
          out.write('\r');
        case 'a':
          out.write('\x07');
        case 'b':
          out.write('\b');
        case 'f':
          out.write('\f');
        case 'v':
          out.write('\v');
        case 'u':
          out.writeCharCode(int.parse(text.substring(pos, pos + 4), radix: 16));
          pos += 4;
        case 'U':
          out.writeCharCode(int.parse(text.substring(pos, pos + 8), radix: 16));
          pos += 8;
        default:
          out.write(e);
      }
    }
  }

  num _number() {
    final match = RegExp(
      r'[-+]?(0x[0-9a-fA-F]+|[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?|inf|nan)',
    ).matchAsPrefix(text, pos);
    if (match == null) _fail('expected a number');
    pos = match.end;
    final s = match.group(0)!;
    if (s.endsWith('inf')) {
      return s.startsWith('-') ? double.negativeInfinity : double.infinity;
    }
    if (s.endsWith('nan')) return double.nan;
    if (s.contains('0x')) {
      final negative = s.startsWith('-');
      final n = int.parse(s.replaceFirst(RegExp(r'^[-+]?0x'), ''), radix: 16);
      return negative ? -n : n;
    }
    return int.tryParse(s) ?? double.parse(s);
  }
}
