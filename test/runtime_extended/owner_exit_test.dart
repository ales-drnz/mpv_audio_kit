// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/event_isolate.dart';
import 'package:mpv_audio_kit/src/internals/owner_watch.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart' as mpv;

import '../_helpers/libmpv_resolver.dart';
import '../_helpers/setter_test_helpers.dart';

typedef _CreateWeakNative =
    Pointer<mpv.MpvHandle> Function(Pointer<mpv.MpvHandle>, Pointer<Utf8>);
typedef _DestroyNative = Void Function(Pointer<mpv.MpvHandle>);
typedef _Destroy = void Function(Pointer<mpv.MpvHandle>);

/// The owner of a bare event isolate: hands the test its core, waits until
/// the test holds a client on it, and exits without stopping anything.
Future<void> _ownCore((SendPort, String) args) async {
  final (reply, libPath) = args;
  OwnerWatch.enabled = true;
  final handle = await MpvEventIsolate().start(
    libraryPath: libPath,
    preInitOptions: const {'ao': 'null', 'vo': 'null', 'idle': 'yes'},
    postInitOptions: const {},
    observes: const <MpvObserveSpec>[],
  );
  final held = ReceivePort();
  reply.send((handle, held.sendPort));
  await held.first;
  Isolate.exit();
}

/// The owner of a playing [Player], which exits without dispose, as the
/// root isolate of an Android engine does when the engine is destroyed.
Future<void> _ownPlayer((SendPort, String, int) args) async {
  final (reply, fixture, counter) = args;
  MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  OwnerWatch.enabled = true;
  final player = Player.testInstrumented(
    configuration: const PlayerConfiguration(logLevel: LogLevel.off),
    wakeupCounterAddress: counter,
  );
  await player.setRawProperty('ao', 'null');
  await player.setRawProperty('loop-file', 'inf');
  await player.open(Media(fixture), play: true);
  await player.stream.playing.firstWhere((playing) => playing);
  reply.send(null);
  Isolate.exit();
}

/// Whether [client] gets MPV_EVENT_SHUTDOWN within [limit].
Future<bool> _shutdownWithin(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> client,
  Duration limit,
) async {
  final deadline = DateTime.now().add(limit);
  while (DateTime.now().isBefore(deadline)) {
    final id = lib.mpvWaitEvent(client, 0).ref.eventId;
    if (id == mpv.MpvEventId.mpvEventShutdown) return true;
    if (id == mpv.MpvEventId.mpvEventNone) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }
  return false;
}

/// Whether [counter] stops moving within [limit]: the event loop that
/// bumps it on every wakeup has exited.
Future<bool> _settlesWithin(Pointer<Int64> counter, Duration limit) async {
  final deadline = DateTime.now().add(limit);
  while (DateTime.now().isBefore(deadline)) {
    final before = counter.value;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (counter.value == before) return true;
  }
  return false;
}

void main() {
  // On Android the process outlives the Flutter engine: Back on the root
  // route or a swipe from the recent apps destroys the engine and its root
  // isolate, and the players that isolate created kept playing with nobody
  // to stop them (F170). An isolate that exits here stands for that root.
  final fixturePath = defaultFixturePath();

  runtimeSuite(fixturePath: fixturePath, () {
    test('the core of an isolate that exits without dispose shuts '
        'down', () async {
      final libPath = resolveLibmpv()!;
      final lib = mpv.MpvLibrary.open(libPath);
      final native = DynamicLibrary.open(libPath);
      final createWeak = native
          .lookupFunction<_CreateWeakNative, _CreateWeakNative>(
            'mpv_create_weak_client',
          );
      final destroy = native.lookupFunction<_DestroyNative, _Destroy>(
        'mpv_destroy',
      );

      final ready = ReceivePort();
      await Isolate.spawn(_ownCore, (ready.sendPort, libPath));
      final (address, held) = await ready.first as (int, SendPort);
      // A weak client does not keep the core up, and sees its shutdown.
      final client = using(
        (arena) => createWeak(
          Pointer.fromAddress(address),
          'owner-exit-test'.toNativeUtf8(allocator: arena),
        ),
      );
      expect(client, isNot(nullptr));
      held.send(null);

      var down = false;
      try {
        down = await _shutdownWithin(lib, client, const Duration(seconds: 5));
        expect(
          down,
          isTrue,
          reason: 'nobody else is left to stop the core of the dead owner',
        );
      } finally {
        if (!down) {
          using(
            (arena) => lib.mpvCommandString(
              client,
              'quit'.toNativeUtf8(allocator: arena),
            ),
          );
        }
        // The release in the event isolate waits for this client to go.
        destroy(client);
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('a playing player whose isolate exits without dispose '
        'stops', () async {
      // Left allocated when the loop never settles: it still writes there.
      final counter = calloc<Int64>();
      final ready = ReceivePort();
      await Isolate.spawn(_ownPlayer, (
        ready.sendPort,
        fixturePath,
        counter.address,
      ));
      await ready.first.timeout(const Duration(seconds: 10));

      final settled = await _settlesWithin(counter, const Duration(seconds: 5));
      expect(
        settled,
        isTrue,
        reason: 'the event loop of the player still runs after its owner',
      );
      calloc.free(counter);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
