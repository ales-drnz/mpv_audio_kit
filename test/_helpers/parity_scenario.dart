// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// One scenario the native and the web backends run alike, recording what
// the player emits in an order both must share (test/web/parity_trace.txt).
// Plain Dart over the public API, so it compiles for the VM and the
// browser: each platform hands it the URIs of the fixtures.
//
// The trace holds what the event pump orders, not the timing of the core:
// - the milestones, one merged list: start (buffering on, START_FILE),
//   loaded (buffering off, FILE_LOADED, with the entry and the cover the
//   state then holds), restart (PLAYBACK_RESTART), end (END_FILE, with the
//   entry and the duration it carries), completed (the end of content);
// - per stream, the distinct values of duration and audio params that
//   mpv reported available, whose order against the milestones depends on
//   when mpv samples them. The unavailable value between two files is left
//   out: mpv can coalesce it away when the pump is busy at the change,
//   natively as on the web.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

/// The URIs of the scenario's fixtures, as one platform opens them.
final class ParityFixtures {
  /// The fixtures: [long] is test/fixtures/sine_5s.flac (5 s, seekable),
  /// [first] sine_stereo_1s.flac, [second] sine_440hz_1s.wav, [cover]
  /// sine_with_cover.flac.
  const ParityFixtures({
    required this.long,
    required this.first,
    required this.second,
    required this.cover,
  });

  /// sine_5s.flac.
  final String long;

  /// sine_stereo_1s.flac.
  final String first;

  /// sine_440hz_1s.wav.
  final String second;

  /// sine_with_cover.flac.
  final String cover;

  String _label(String? uri) => switch (uri) {
    _ when uri == long => 'long',
    _ when uri == first => 'first',
    _ when uri == second => 'second',
    _ when uri == cover => 'cover',
    'mak-test://cover' => 'resolved',
    _ => '?',
  };
}

/// Where the scenario says which step it is at; silent by default.
void Function(String step) parityLog = (_) {};

/// [call], failing after [timeout] with the name of the [step].
Future<T> _step<T>(String step, Future<T> call) {
  parityLog(step);
  return call.timeout(
    const Duration(seconds: 20),
    onTimeout: () => throw TimeoutException('$step did not complete'),
  );
}

String _seconds(Duration? d) =>
    d == null ? 'none' : (d.inMilliseconds / 1000).toStringAsFixed(1);

/// Waits until [condition] holds, polling.
Future<void> waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 20),
  String what = 'condition',
}) async {
  parityLog('wait $what');
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('$what not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

/// Runs the scenario on a new player and returns the trace, after checking
/// the values that differ by nature between runs (positions) in bounds.
Future<List<String>> runParityScenario(ParityFixtures f) async {
  final player = Player();
  final milestones = <String>[];
  // Not in the trace: `playing` follows `core-idle`, which mpv samples
  // when the client reads, so a seek's brief idle shows on one pump and
  // not the other (the native one reads it before PLAYBACK_RESTART, the
  // web one gets the change coalesced while it reads). Checked at rest.
  final playing = <String>[];
  final durations = <String>[];
  final params = <String>[];
  var af = '';
  var positionsInBounds = true;
  final subs = <StreamSubscription<Object?>>[];
  void distinct(List<String> list, String value) {
    if (list.isEmpty || list.last != value) list.add(value);
  }

  try {
    await _step('ready', player.ready);
    await _step('ao', player.setRawProperty('ao', 'null'));
    // buffering goes true at START_FILE and false at FILE_LOADED, whose
    // handler has already put the new entry and its cover in the state.
    String loaded() {
      final list = player.state.playlist;
      final index = list.index;
      final uri = index >= 0 && index < list.items.length
          ? list.items[index].uri
          : null;
      return 'loaded ${f._label(uri)} $index/${list.items.length} '
          'cover=${player.state.coverArt?.mimeType ?? 'none'}';
    }

    subs
      ..add(
        player.stream.buffering.listen(
          (b) => milestones.add(b ? 'start' : loaded()),
        ),
      )
      ..add(
        player.stream.completed.listen((c) => milestones.add('completed $c')),
      )
      ..add(
        player.stream.endFile.listen((e) {
          // The entry that ended and its duration, as mpv reported them;
          // the position depends on the output buffer, so it is checked in
          // bounds, not traced.
          final position = e.position;
          final duration = e.duration;
          if (position != null && duration != null) {
            positionsInBounds &=
                position >= Duration.zero &&
                position <= duration + const Duration(milliseconds: 200);
          }
          milestones.add(
            'end ${e.reason.name} ${f._label(e.media?.uri)} '
            'duration=${_seconds(duration)} '
            'position=${position == null ? 'none' : 'set'}',
          );
        }),
      )
      ..add(
        // `core-idle` is read again and forwarded ahead of each restart, so
        // the state has `playing` for the file that restarts.
        player.stream.seekCompleted.listen(
          (_) => milestones.add('restart playing=${player.state.playing}'),
        ),
      )
      ..add(player.stream.playing.listen((p) => playing.add('$p')))
      ..add(
        player.stream.duration.listen((d) {
          if (d == Duration.zero) return;
          distinct(durations, (d.inMilliseconds / 1000).toStringAsFixed(1));
        }),
      )
      ..add(
        player.stream.audioParams.listen((a) {
          if (a.sampleRate == null) return;
          distinct(params, '${a.sampleRate}/${a.channels}');
        }),
      );

    // A file opened paused, then played, sought and paused.
    await _step('open long', player.open(Media(f.long), play: false));
    await waitUntil(
      () =>
          milestones.any((m) => m.startsWith('restart')) &&
          player.state.duration > Duration.zero,
      what: 'the long file loaded',
    );
    await _step('play', player.play());
    await waitUntil(() => player.state.playing, what: 'playing');
    final restarts = milestones.where((m) => m.startsWith('restart')).length;
    await _step('seek', player.seek(const Duration(seconds: 2)));
    await waitUntil(
      () => milestones.where((m) => m.startsWith('restart')).length > restarts,
      what: 'the seek landed',
    );
    expect(player.state.position.inMilliseconds, inInclusiveRange(1900, 2600));
    await waitUntil(() => player.state.playing, what: 'playing after the seek');
    await _step('pause', player.pause());
    await waitUntil(() => !player.state.playing, what: 'paused');

    // An effect: the chain mpv reports back.
    await _step(
      'effects',
      player.setAudioEffects(const [EqualizerEffect(frequency: 1000, gain: 3)]),
    );
    af = (await _step('af', player.getRawProperty('af')))!;

    // Two entries played through: the first advances to the second, the
    // second parks at its end.
    await _step(
      'openAll',
      player.openAll([Media(f.first), Media(f.second)], play: true),
    );
    await waitUntil(() => player.state.completed, what: 'the playlist ended');

    // A URI only the source resolver knows, through the on_load hook.
    final requests = <String>[];
    await _step(
      'resolver',
      player.setSourceResolver((request) {
        requests.add('${request.uri} ${request.media.extras}');
        return request.uri == 'mak-test://cover' ? f.cover : null;
      }),
    );
    await _step(
      'open resolved',
      player.open(
        const Media('mak-test://cover', extras: {'k': 'v'}),
        play: false,
      ),
    );
    await waitUntil(
      () => milestones.any((m) => m.startsWith('loaded resolved')),
      what: 'the resolved file loaded',
    );
    expect(requests, ['mak-test://cover {k: v}']);
    expect(positionsInBounds, isTrue, reason: 'an end position past its file');
    await _step('no resolver', player.setSourceResolver(null));
  } finally {
    for (final sub in subs) {
      await sub.cancel();
    }
    parityLog('dispose');
    await player.dispose();
  }
  return [
    for (final m in milestones) 'milestone $m',
    'af $af',
    'playing ${playing.isEmpty ? '-' : playing.first} to ${playing.isEmpty ? '-' : playing.last}',
    for (final d in durations) 'duration $d',
    for (final a in params) 'params $a',
  ];
}
