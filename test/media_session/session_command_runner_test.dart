// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// A media-session command runs its Player call un-awaited. `next` and
// `previous` return a `Future<bool>`: a `catchError` handler that returns
// nothing is rejected at runtime with an ArgumentError ("must return a
// value of the future's type"), which escapes the zone unhandled instead
// of being logged.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_controller.dart';

Future<(List<Object>, List<Object>)> _run(
  Future<Object?> Function() action,
) async {
  final logged = <Object>[];
  final uncaught = <Object>[];
  final done = Completer<void>();
  runZonedGuarded(() {
    // The action starts inside the zone, like a command handler call.
    runSessionCommand(action(), logged.add);
    // Let the failure and any secondary error surface.
    Timer(const Duration(milliseconds: 20), done.complete);
  }, (e, _) => uncaught.add(e));
  await done.future;
  return (logged, uncaught);
}

void main() {
  test(
    'a failing Future<bool> command is logged, not left unhandled',
    () async {
      final (logged, uncaught) = await _run(
        () => Future<bool>.error(const PlayerDisposedException()),
      );
      expect(uncaught, isEmpty);
      expect(logged, [isA<PlayerDisposedException>()]);
    },
  );

  test('a failing Future<void> command is logged', () async {
    final (logged, uncaught) = await _run(
      () => Future<void>.error(StateError('rejected')),
    );
    expect(uncaught, isEmpty);
    expect(logged, [isA<StateError>()]);
  });

  test('a successful command logs nothing', () async {
    final (logged, uncaught) = await _run(() => Future<bool>.value(true));
    expect(uncaught, isEmpty);
    expect(logged, isEmpty);
  });
}
