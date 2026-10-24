// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/core_calls.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart' show MpvFormat;
import 'package:test/test.dart';

import '../_helpers/fake_mpv.dart';

/// The player's calls to libmpv on a [FakeMpv]: which commands move the
/// playlist indices, how a refusal surfaces, the bundle rollback and the
/// chapter-list node.
void main() {
  late FakeMpv mpv;
  late CoreCalls calls;

  setUp(() {
    mpv = FakeMpv();
    calls = CoreCalls(mpv);
  });

  group('commands that move the playlist indices', () {
    final cases = <List<String>, bool>{
      ['playlist-remove', '0']: true,
      ['playlist-move', '0', '2']: true,
      ['playlist-clear']: true,
      ['playlist-shuffle']: true,
      ['playlist-unshuffle']: true,
      ['stop']: true,
      // After the input prefixes, which mpv skips.
      ['no-osd', 'playlist-remove', 'current']: true,
      ['osd-msg', 'async', 'playlist-clear']: true,
      // mpv reads `_` in a command name as `-`.
      ['playlist_remove', '0']: true,
      // A load without flags replaces, as do replace and insert.
      ['loadfile', 'a.flac']: true,
      ['loadfile', 'a.flac', 'replace']: true,
      ['loadfile', 'a.flac', 'insert-at', '1']: true,
      ['loadfile', 'a.flac', 'insert-next']: true,
      ['loadlist', 'a.m3u', 'replace']: true,
      // Appends leave every index where it is.
      ['loadfile', 'a.flac', 'append']: false,
      ['loadfile', 'a.flac', 'append-play']: false,
      ['loadfile', 'a.flac', 'append', '-1', 'start=1']: false,
      ['loadlist', 'a.m3u', 'append']: false,
      ['no-osd', 'loadfile', 'a.flac', 'append']: false,
      // Commands that read or move the current entry only.
      ['playlist-next', 'weak']: false,
      ['playlist-play-index', '2']: false,
      ['seek', '10']: false,
      // Nothing to run.
      <String>[]: false,
      ['no-osd']: false,
    };
    for (final MapEntry(key: args, value: shifts) in cases.entries) {
      test('${args.isEmpty ? '(empty)' : args.join(' ')}: $shifts', () {
        expect(CoreCalls.shiftsPlaylist(args), shifts);
      });
    }

    test('every way of sending a command counts its shift', () async {
      await calls.command(['playlist-remove', '0']);
      await calls.commandResult(['loadfile', 'a.flac']);
      await calls.commandChecked(['playlist-clear']);
      await calls.navigate(['playlist-next', 'weak']);
      await calls.command(['loadfile', 'b.flac', 'append']);
      expect(calls.playlistShifts, 3);
    });

    test('a refused command still counts: mpv may have run part of it', () {
      // Counted when sent, as before the reply: the read that follows it
      // must not trust an older playlist.
      mpv.commandReply = (_) => (MpvError.mpvErrorCommand, null);
      calls.command(['playlist-remove', '9']).ignore();
      expect(calls.playlistShifts, 1);
    });
  });

  test('a call sends its request before any await', () {
    // CoreCalls adds no hop: requests leave in program order, as the
    // player sent them before the wrappers moved here.
    mpv.hold();
    calls.prop('volume', '50').ignore();
    calls.command(['seek', '1']).ignore();
    calls.get('time-pos', MpvFormat.mpvFormatDouble).ignore();
    calls.commandChecked(['stop']).ignore();
    calls.navigate(['playlist-next', 'weak']).ignore();
    calls.setChapterList(const []).ignore();
    expect(mpv.requests, [
      'set volume',
      'command seek 1',
      'get time-pos',
      'command stop',
      'command playlist-next weak',
      'node chapter-list',
    ]);
    mpv.release();
  });

  group('refusals', () {
    test('prop throws with the name, the code and mpv\'s message', () async {
      mpv.writeRc = (_, _) => MpvError.mpvErrorPropertyFormat;
      mpv.errorMessages[MpvError.mpvErrorPropertyFormat] =
          'unsupported format for accessing property';
      await expectLater(
        calls.prop('volume', 'loud'),
        throwsA(
          isA<MpvCommandException>()
              .having((e) => e.name, 'name', 'volume')
              .having((e) => e.code, 'code', MpvError.mpvErrorPropertyFormat)
              .having(
                (e) => e.message,
                'message',
                'unsupported format for accessing property',
              ),
        ),
      );
      expect(mpv.properties, isEmpty);
    });

    test('propRc gives the rc instead of throwing', () async {
      mpv.writeRc = (_, _) => MpvError.mpvErrorPropertyUnavailable;
      expect(
        await calls.propRc('volume', '50'),
        MpvError.mpvErrorPropertyUnavailable,
      );
    });

    test('navigate: moved, nowhere to go, or an error', () async {
      expect(await calls.navigate(['playlist-next', 'weak']), isTrue);

      mpv.commandReply = (_) => (MpvError.mpvErrorCommand, null);
      expect(await calls.navigate(['playlist-next', 'weak']), isFalse);

      mpv.commandReply = (_) => (MpvError.mpvErrorInvalidParameter, null);
      await expectLater(
        calls.navigate(['playlist-prev', 'weak']),
        throwsA(
          isA<MpvCommandException>()
              .having((e) => e.name, 'name', 'playlist-prev')
              .having((e) => e.code, 'code', MpvError.mpvErrorInvalidParameter)
              .having(
                (e) => e.message,
                'message',
                'error ${MpvError.mpvErrorInvalidParameter}',
              ),
        ),
      );
    });

    test('commandChecked names the command, or <empty> for none', () async {
      mpv.commandReply = (_) => (MpvError.mpvErrorCommand, null);
      await expectLater(
        calls.commandChecked(['seek', '10']),
        throwsA(
          isA<MpvCommandException>().having((e) => e.name, 'name', 'seek'),
        ),
      );
      await expectLater(
        calls.commandChecked(const []),
        throwsA(
          isA<MpvCommandException>()
              .having((e) => e.name, 'name', '<empty>')
              .having((e) => e.code, 'code', MpvError.mpvErrorCommand),
        ),
      );
    });

    test('command and commandResult give the rc and the result', () async {
      mpv.commandReply = (_) => (0, {'playlist_entry_id': 7});
      expect(await calls.command(['loadfile', 'a.flac', 'append']), 0);
      final (rc, result) = await calls.commandResult([
        'loadfile',
        'b.flac',
        'append',
      ]);
      expect(rc, 0);
      expect(result, {'playlist_entry_id': 7});
    });
  });

  group('writeBundle', () {
    final writes = [
      ('cache-secs', '20.000000', '10.000000'),
      ('cache-pause', 'no', 'yes'),
      ('cache-pause-wait', '2.000000', '1.000000'),
    ];

    test('the state takes the new value before the first write', () async {
      final put = <String>[];
      mpv.hold();
      final done = calls.writeBundle(writes, put.add, 'next', 'previous');
      expect(put, ['next']);
      expect(mpv.requests, ['set cache-secs']);
      mpv.release();
      await done;
      expect(put, ['next']);
      expect(mpv.properties, {
        'cache-secs': '20.000000',
        'cache-pause': 'no',
        'cache-pause-wait': '2.000000',
      });
    });

    test('a refused write puts back what went in, then the state', () async {
      final put = <String>[];
      mpv.writeRc = (name, value) =>
          name == 'cache-pause-wait' && value == '2.000000'
          ? MpvError.mpvErrorPropertyFormat
          : MpvError.mpvErrorSuccess;
      await expectLater(
        calls.writeBundle(writes, put.add, 'next', 'previous'),
        throwsA(
          isA<MpvCommandException>().having(
            (e) => e.name,
            'name',
            'cache-pause-wait',
          ),
        ),
      );
      expect(mpv.requests, [
        'set cache-secs',
        'set cache-pause',
        'set cache-pause-wait',
        // The written ones go back, the last one first.
        'set cache-pause',
        'set cache-secs',
      ]);
      expect(mpv.properties, {'cache-secs': '10.000000', 'cache-pause': 'yes'});
      expect(put, ['next', 'previous']);
    });
  });

  group('chapter-list', () {
    test('an array of title and time maps, in seconds', () async {
      expect(
        await calls.setChapterList(const [
          Chapter(time: Duration.zero, title: 'Intro'),
          Chapter(time: Duration(milliseconds: 61500)),
        ]),
        MpvError.mpvErrorSuccess,
      );
      expect(mpv.nodes['chapter-list'], [
        {'title': 'Intro', 'time': 0.0},
        // A chapter without a title goes out with an empty one.
        {'title': '', 'time': 61.5},
      ]);
    });

    test('an empty list clears the chapters', () async {
      await calls.setChapterList(const []);
      expect(mpv.nodes['chapter-list'], isEmpty);
      expect(mpv.nodes['chapter-list'], isA<List<Object?>>());
    });

    test('resolves with mpv\'s rc, without throwing', () async {
      mpv.writeRc = (_, _) => MpvError.mpvErrorPropertyError;
      expect(
        await calls.setChapterList(const []),
        MpvError.mpvErrorPropertyError,
      );
    });
  });

  test('hook continues and the log level go to the client', () {
    calls.hookContinue(42);
    calls.requestLogMessages(LogLevel.warn);
    calls.requestLogMessages(LogLevel.off);
    expect(mpv.continued, [42]);
    expect(mpv.logLevels, ['warn', 'no']);
  });

  test('settleWrites waits for the writes on the wire', () async {
    mpv.hold();
    calls.prop('volume', '50').ignore();
    var settled = false;
    final settle = calls.settleWrites().then((_) => settled = true);
    await pumpEventQueue();
    expect(settled, isFalse);
    mpv.release();
    await settle;
    expect(settled, isTrue);
  });
}
