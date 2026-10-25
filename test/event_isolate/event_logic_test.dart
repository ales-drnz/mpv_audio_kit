// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The event logic the native and the web pumps share, without libmpv: a
// fake reader answers from a map, synchronously (as the native pump's
// blocking reads resolve) or later (as the web pump's replies come), and
// the events the logic sends are compared.

import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/internals/core_events.dart';
import 'package:mpv_audio_kit/src/internals/event_logic.dart';
import 'package:mpv_audio_kit/src/internals/event_sequencer.dart';
import 'package:mpv_audio_kit/src/mpv_constants.dart';

/// Answers reads from [values]; with [later], each answer comes on a later
/// turn of the event loop instead of at once.
final class _Reader implements CoreReader {
  _Reader(this.values, {this.later = false});

  final Map<String, Object?> values;
  final bool later;
  final List<String> reads = [];

  Future<T?> _read<T>(String name) {
    reads.add(name);
    final value = values[name] as T?;
    if (!later) return Future.value(value);
    return Future<T?>.delayed(Duration.zero, () => value);
  }

  @override
  Future<String?> string(String name) => _read(name);
  @override
  Future<double?> float(String name) => _read(name);
  @override
  Future<int?> int64(String name) => _read(name);
  @override
  Future<int?> flag(String name) => _read(name);
  @override
  Future<Object?> node(String name) => _read(name);
}

/// The events a logic sends, as short lines.
String _describe(MpvIsolateEvent e) => switch (e) {
  MpvEventStartFile(:final entryId) => 'start $entryId',
  MpvEventFileLoaded(:final path, :final timePos, :final coverMime) =>
    'loaded $path $timePos ${coverMime ?? '-'}',
  MpvEventEndFile(:final entryId, :final reason, :final lastEntry) =>
    'end $entryId $reason last=$lastEntry',
  MpvEventEndOfContent(:final eof, :final parked, :final lastEntry) =>
    'eoc eof=$eof parked=$parked last=$lastEntry',
  MpvEventPlaybackRestart(:final timePos) => 'restart $timePos',
  MpvEventPropertyDouble(:final name, :final value) => '$name=$value',
  MpvEventPropertyInt(:final name, :final value) => '$name=$value',
  MpvEventPropertyString(:final name, :final value) => '$name=$value',
  MpvEventPropertyNode(:final name, :final value) => '$name=$value',
  MpvEventPropertyUnavailable(:final name) => '$name=none',
  MpvEventPropertyGroup(:final events) =>
    'group ${events.map(_describe).join(', ')}',
  MpvEventAudioReconfig() => 'reconfig',
  MpvEventReply(:final userdata) => 'reply $userdata',
  _ => e.runtimeType.toString(),
};

/// The core's answers while entry 7 is the first of two and has played to
/// its end, parked by keep-open.
Map<String, Object?> _parkedFirstOfTwo() => {
  'path': '/a.flac',
  'playlist': [
    {'filename': '/a.flac', 'id': 7},
    {'filename': '/b.flac', 'id': 8},
  ],
  'time-pos': 1.0,
  'chapter': -1,
  'chapter-list': <Object?>[],
  'embedded-cover-art-data': Uint8List.fromList([1, 2, 3]),
  'embedded-cover-art-mime': 'image/png',
  'playlist-pos': 0,
  'playlist/0/id': 7,
  'eof-reached': 1,
  'pause': 1,
  'playlist/0/filename': '/a.flac',
  'playlist-count': 2,
  'playlist/1/id': 8,
  'duration': 1.0,
};

/// A script of decoded events, each a dispatch or a property change.
typedef _Step = Future<void>? Function(EventLogic logic);

final List<_Step> _script = [
  (l) => l.property('duration', MpvFormat.mpvFormatDouble, 1.0),
  (l) => l.dispatch(MpvEventStartFile(7)),
  (l) => l.property('duration', MpvFormat.mpvFormatNone, kPropertyUnavailable),
  (l) => l.dispatch(MpvEventFileLoaded()),
  (l) => l.dispatch(MpvEventReply(41, 0)),
  (l) => l.dispatch(MpvEventPlaybackRestart()),
  (l) => l.property('eof-reached', MpvFormat.mpvFormatFlag, 1),
  (l) => l.property('pause', MpvFormat.mpvFormatFlag, 1),
  (l) =>
      l.dispatch(MpvEventEndFile(7, MpvEndFileReason.mpvEndFileReasonEof, 0)),
  (l) => l.dispatch(MpvEventStartFile(8)),
];

/// Runs [_script] the way the native pump does: each dispatch's reads
/// resolve before the next event is taken.
Future<List<String>> _runNative(Map<String, Object?> values) async {
  final out = <String>[];
  final logic = EventLogic(_Reader(values), (e) => out.add(_describe(e)))
    ..observe('duration', MpvFormat.mpvFormatDouble);
  for (final step in _script) {
    final reads = step(logic);
    if (reads != null) await reads;
  }
  return out;
}

/// Runs [_script] the way the web pump does: through the sequencer, with
/// reads answered later, and the rest of the script arriving while they are
/// in flight.
Future<List<String>> _runWeb(Map<String, Object?> values) async {
  final out = <String>[];
  final logic = EventLogic(
    _Reader(values, later: true),
    (e) => out.add(_describe(e)),
  )..observe('duration', MpvFormat.mpvFormatDouble);
  final queue = Queue<_Step>();
  final sequencer = EventSequencer(
    take: () {
      if (queue.isEmpty) return (false, null, false);
      return (true, queue.removeFirst()(logic), false);
    },
    flushTrailing: logic.flushTrailing,
    waitSeconds: () => null,
    onError: (e, _) => out.add('error $e'),
  );
  for (final step in _script) {
    queue.add(step);
    sequencer.pump();
  }
  while (queue.isNotEmpty || sequencer.stepping) {
    await Future<void>.delayed(Duration.zero);
    sequencer.pump();
  }
  return out;
}

void main() {
  test(
    'FILE_LOADED reads its payload, re-reads, then the end of content',
    () async {
      final values = _parkedFirstOfTwo();
      final reader = _Reader(values);
      final out = <String>[];
      final logic = EventLogic(reader, (e) => out.add(_describe(e)))
        ..observe('duration', MpvFormat.mpvFormatDouble);
      await logic.property('duration', MpvFormat.mpvFormatDouble, 1.0);
      await logic.dispatch(MpvEventStartFile(7));
      await logic.property(
        'duration',
        MpvFormat.mpvFormatNone,
        kPropertyUnavailable,
      );
      reader.reads.clear();
      await logic.dispatch(MpvEventFileLoaded());
      expect(out, [
        'duration=1.0',
        'start 7',
        'duration=none',
        'duration=1.0',
        'loaded /a.flac 1.0 image/png',
        'eoc eof=true parked=true last=false',
      ]);
      expect(reader.reads, [
        'embedded-cover-art-data',
        'embedded-cover-art-mime',
        'path',
        'playlist',
        'time-pos',
        'chapter',
        'chapter-list',
        'duration',
        'playlist-pos',
        'playlist/0/id',
        'eof-reached',
        'pause',
        'playlist/0/filename',
        'time-pos',
        'playlist-count',
        'playlist-pos',
        'playlist/0/id',
      ]);
    },
  );

  test('the end of content of an entry not started yet is not sent', () async {
    final values = _parkedFirstOfTwo()..['playlist/0/id'] = 9;
    final out = <String>[];
    final logic = EventLogic(_Reader(values), (e) => out.add(_describe(e)));
    await logic.dispatch(MpvEventStartFile(7));
    await logic.property('eof-reached', MpvFormat.mpvFormatFlag, 1);
    expect(out, ['start 7', 'eof-reached=1']);
  });

  test(
    'pause takes an end-of-content read but never reaches the player',
    () async {
      final reader = _Reader(_parkedFirstOfTwo());
      final out = <String>[];
      final logic = EventLogic(reader, (e) => out.add(_describe(e)));
      await logic.dispatch(MpvEventStartFile(7));
      await logic.property('pause', MpvFormat.mpvFormatFlag, 1);
      expect(out, ['start 7', 'eoc eof=true parked=true last=false']);
    },
  );

  test('END_FILE reads the last entry for EOF only', () async {
    final reader = _Reader(_parkedFirstOfTwo());
    final out = <String>[];
    final logic = EventLogic(reader, (e) => out.add(_describe(e)));
    expect(
      logic.dispatch(
        MpvEventEndFile(8, MpvEndFileReason.mpvEndFileReasonStop, 0),
      ),
      isNull,
    );
    await logic.dispatch(
      MpvEventEndFile(8, MpvEndFileReason.mpvEndFileReasonEof, 0),
    );
    expect(out, ['end 8 2 last=false', 'end 8 0 last=true']);
    expect(reader.reads, ['playlist-count', 'playlist/1/id']);
  });

  test(
    'PLAYBACK_RESTART drops a held time-pos and sends the landing',
    () async {
      final out = <String>[];
      final logic = EventLogic(
        _Reader(_parkedFirstOfTwo()..['time-pos'] = 0.5),
        (e) => out.add(_describe(e)),
      );
      await logic.property('time-pos', MpvFormat.mpvFormatDouble, 0.1);
      // Inside the throttle window: held, not sent.
      await logic.property('time-pos', MpvFormat.mpvFormatDouble, 0.2);
      expect(logic.holdsValues, isTrue);
      await logic.dispatch(MpvEventPlaybackRestart());
      logic.flushTrailing();
      expect(out, ['time-pos=0.1', 'restart 0.5']);
    },
  );

  test(
    'PLAYBACK_RESTART forwards core-idle past the dedup, before itself',
    () async {
      final out = <String>[];
      final reader = _Reader(_parkedFirstOfTwo()..['core-idle'] = 0);
      final logic = EventLogic(reader, (e) => out.add(_describe(e)));
      await logic.property('core-idle', MpvFormat.mpvFormatFlag, 0);
      await logic.dispatch(MpvEventPlaybackRestart());
      expect(out, ['core-idle=0', 'core-idle=0', 'restart 1.0']);
      expect(reader.reads.take(2), ['core-idle', 'time-pos']);
    },
  );

  test('the audio params group crosses once', () async {
    final out = <String>[];
    final logic = EventLogic(_Reader({}), (e) => out.add(_describe(e)));
    await logic.property('audio-params', MpvFormat.mpvFormatNode, {
      'channels': 2,
    });
    await logic.property('audio-codec', MpvFormat.mpvFormatString, 'flac');
    expect(out, isEmpty);
    await logic.property('audio-codec-name', MpvFormat.mpvFormatString, 'flac');
    expect(out, [
      'group audio-params={channels: 2}, audio-codec=flac, '
          'audio-codec-name=flac',
    ]);
  });

  test('a repeated value is sent once, an unobserved format never', () async {
    final out = <String>[];
    final logic = EventLogic(_Reader({}), (e) => out.add(_describe(e)));
    await logic.property('volume', MpvFormat.mpvFormatDouble, 50.0);
    await logic.property('volume', MpvFormat.mpvFormatDouble, 50.0);
    await logic.property(
      'volume',
      MpvFormat.mpvFormatOsdString,
      kPropertyUnobserved,
    );
    expect(out, ['volume=50.0']);
  });

  test(
    'reads answered later through the sequencer give the native order',
    () async {
      final native = await _runNative(_parkedFirstOfTwo());
      final web = await _runWeb(_parkedFirstOfTwo());
      expect(native, [
        'duration=1.0',
        'start 7',
        'duration=none',
        'duration=1.0',
        'loaded /a.flac 1.0 image/png',
        'eoc eof=true parked=true last=false',
        'reply 41',
        'restart 1.0',
        'eoc eof=true parked=true last=false',
        'eof-reached=1',
        'eoc eof=true parked=true last=false',
        'eoc eof=true parked=true last=false',
        'end 7 0 last=false',
        'start 8',
      ]);
      expect(web, native);
    },
  );
}
