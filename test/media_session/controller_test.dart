// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
//
// Dart-side unit tests for `MediaSessionController`. The OS play/pause
// state is driven by the `playWhenReady` (user intent) axis, which is
// stable across seeks — so no seek-transient masking is needed and the
// scrub-bar button never flickers. These tests pin that wiring: intent
// changes propagate, seek landings re-sync position, and a `core-idle`
// transient (which the controller does not observe) cannot reach the
// OS.
//
// The native publish (composing `MPNowPlayingInfoCenter`) is covered by
// the real-framework suite under `test/media_session/darwin/`, and the
// full Dart→native→OS path by `test_app/integration_test/`. These run
// on any host under `flutter test`; they touch neither libmpv nor a
// platform channel.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/media_session/artwork_fetcher.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_channel.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_controller.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_inputs.dart';

/// Records every call made to the [MediaSessionChannel] surface and
/// exposes a controllable [commandStream]. The controller-under-test
/// sees this as the real channel; production wires the real platform
/// channel here instead.
class _RecordingChannel extends MediaSessionChannel {
  final List<_Call> calls = [];
  final StreamController<MediaSessionCommand> _commands =
      StreamController<MediaSessionCommand>.broadcast();

  @override
  Stream<MediaSessionCommand> get commandStream => _commands.stream;

  final StreamController<void> resets = StreamController<void>.broadcast();

  @override
  Stream<void> get audioOutputResets => resets.stream;

  @override
  Future<void> enable({
    required MediaSession session,
    required MediaSessionMetadataSnapshot metadata,
    required MediaSessionPlaybackSnapshot playback,
  }) async {
    calls.add(_Call('enable', {'playing': playback.playing}));
  }

  @override
  Future<void> updateConfig(MediaSession session) async {
    calls.add(_Call('updateConfig', {'session': session}));
  }

  @override
  Future<void> updateMetadata(MediaSessionMetadataSnapshot metadata) async {
    calls.add(_Call('updateMetadata', {'metadata': metadata}));
  }

  @override
  Future<void> updatePlayback(MediaSessionPlaybackSnapshot playback) async {
    calls.add(_Call('updatePlayback', {
      'playing': playback.playing,
      'positionMs': playback.position.inMilliseconds,
      'rate': playback.rate,
      'completed': playback.completed,
      'snapshot': playback,
    }),);
  }

  @override
  Future<void> disable() async {
    calls.add(const _Call('disable', {}));
  }

  Future<void> close() async {
    await _commands.close();
    await resets.close();
  }

  List<_Call> callsOfType(String method) =>
      calls.where((c) => c.method == method).toList();
}

class _Call {
  final String method;
  final Map<String, Object?> args;
  const _Call(this.method, this.args);
  @override
  String toString() => '$method($args)';
}

/// Bundle of per-test stream controllers + a mutable [PlayerState]
/// used to fabricate the [MediaSessionInputs] the controller consumes.
/// The streams are only triggers — the controller reads truth from
/// [state] at push time, so tests drive behaviour by mutating [state]
/// then firing the matching stream.
class _Rig {
  final playWhenReady = StreamController<bool>.broadcast();
  final playing = StreamController<bool>.broadcast();
  final buffering = StreamController<bool>.broadcast();
  final rate = StreamController<double>.broadcast();
  final seekCompleted = StreamController<void>.broadcast();
  final seekable = StreamController<bool>.broadcast();
  final loop = StreamController<Loop>.broadcast();
  final shuffle = StreamController<bool>.broadcast();
  final duration = StreamController<Duration>.broadcast();
  final metadata = StreamController<Map<String, String>>.broadcast();
  final coverArt = StreamController<CoverArt?>.broadcast();
  final mediaTitle = StreamController<String>.broadcast();
  final mediaSession = StreamController<MediaSession?>.broadcast();

  PlayerState state = const PlayerState(mediaSession: MediaSession());

  MediaSessionInputs get inputs => MediaSessionInputs(
        playWhenReady: playWhenReady.stream,
        playing: playing.stream,
        buffering: buffering.stream,
        rate: rate.stream,
        seekCompleted: seekCompleted.stream,
        seekable: seekable.stream,
        loop: loop.stream,
        shuffle: shuffle.stream,
        duration: duration.stream,
        metadata: metadata.stream,
        coverArt: coverArt.stream,
        mediaTitle: mediaTitle.stream,
        mediaSession: mediaSession.stream,
      );

  Future<void> dispose() async {
    await playWhenReady.close();
    await playing.close();
    await buffering.close();
    await rate.close();
    await seekCompleted.close();
    await seekable.close();
    await loop.close();
    await shuffle.close();
    await duration.close();
    await metadata.close();
    await coverArt.close();
    await mediaTitle.close();
    await mediaSession.close();
  }
}

Future<MediaSessionController> _buildController({
  required _Rig rig,
  required _RecordingChannel channel,
  void Function(MediaSessionCommand)? onCommand,
  void Function()? onAudioOutputReset,
  ArtworkFetcher? artworkFetcher,
}) =>
    MediaSessionController.create(
      stateSnapshot: () => rig.state,
      inputs: rig.inputs,
      onCommand: onCommand ?? (_) {},
      onAudioOutputReset: onAudioOutputReset,
      channel: channel,
      artworkFetcher: artworkFetcher,
    );

/// Pumps the Dart event loop until microtasks and any pending `await`
/// resumes have settled. Required after firing a stream event before
/// asserting on side effects.
Future<void> _settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Silence MissingPluginException from the real channel when the
  // controller is built — we only assert on the recording channel.
  setUpAll(() {
    const ch = MethodChannel('mpv_audio_kit/media_session');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, (call) async => null);
  });

  group('MediaSessionController — intent axis (no seek flicker)', () {
    test('an intent change is published with the new value', () async {
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);
      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);
      ch.calls.clear();

      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        playWhenReady: true,
      );
      rig.playWhenReady.add(true);
      await _settle();

      final updates = ch.callsOfType('updatePlayback');
      expect(updates.length, 1);
      expect(updates.single.args['playing'], true);
    });

    test('the published play state tracks playWhenReady, NOT core-idle',
        () async {
      // The whole point: while seeking, mpv flips core-idle (→
      // state.playing) but leaves intent (playWhenReady) alone. The
      // controller doesn't observe `playing` at all, so even a state
      // where playing=false but the user intends play publishes
      // playing=true. This is what keeps the OS button from flickering.
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);
      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);
      ch.calls.clear();

      // Mid-seek snapshot: core-idle has driven playing=false, but the
      // user still intends to play, and a seek is in flight.
      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        playWhenReady: true,
        seeking: true,
      );
      // A seek landing re-syncs position; intent is unchanged.
      rig.seekCompleted.add(null);
      await _settle();

      final updates = ch.callsOfType('updatePlayback');
      expect(updates.length, 1);
      expect(updates.single.args['playing'], true,
          reason: 'intent (playWhenReady) drives the button, not core-idle',);
    });

    test('seekCompleted re-syncs the landed position', () async {
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);
      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);
      ch.calls.clear();

      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        playWhenReady: true,
        position: Duration(seconds: 60),
      );
      rig.seekCompleted.add(null);
      await _settle();

      final updates = ch.callsOfType('updatePlayback');
      expect(updates.length, 1);
      expect(updates.single.args['positionMs'], 60000);
      expect(updates.single.args['playing'], true);
      final snap =
          updates.single.args['snapshot'] as MediaSessionPlaybackSnapshot;
      expect(snap.seek, true,
          reason: 'a seek landing must flag seek=true so MPRIS emits Seeked',);
    });

    test('a non-seek push (intent change) carries seek=false', () async {
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);
      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);
      ch.calls.clear();

      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        playWhenReady: true,
      );
      rig.playWhenReady.add(true);
      await _settle();

      final snap = ch.callsOfType('updatePlayback').single.args['snapshot']
          as MediaSessionPlaybackSnapshot;
      expect(snap.seek, false,
          reason: 'only seek landings flag seek; a play/pause must not',);
    });

    test('end-of-content carries completed=true on the playback snapshot',
        () async {
      // At true EOF the eof-reached hook releases playWhenReady (→ false) and
      // sets state.completed. That playWhenReady flip drives the playback push,
      // so the completed flag must ride that same snapshot — the native side
      // maps it to STATE_ENDED (Android) / Stopped+empty Metadata (Linux).
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);
      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);
      ch.calls.clear();

      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        position: Duration(seconds: 30),
        completed: true,
      );
      rig.playWhenReady.add(false);
      await _settle();

      final updates = ch.callsOfType('updatePlayback');
      expect(updates.length, 1);
      expect(updates.single.args['playing'], false);
      expect(updates.single.args['completed'], true,
          reason: 'completed must reach native so it can render a terminal state',);

      // Falling edge: seeking back in clears completed and re-syncs.
      ch.calls.clear();
      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        playWhenReady: true,
        position: Duration(seconds: 5),
      );
      rig.seekCompleted.add(null);
      await _settle();
      expect(ch.callsOfType('updatePlayback').single.args['completed'], false,
          reason: 'seeking back in clears the terminal flag',);
    });

    test('a genuine pause (intent=false) propagates immediately', () async {
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);
      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        playWhenReady: true,
      );
      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);
      ch.calls.clear();

      // User pauses: intent flips false, even while seeking.
      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        seeking: true,
      );
      rig.playWhenReady.add(false);
      await _settle();

      final updates = ch.callsOfType('updatePlayback');
      expect(updates.length, 1);
      expect(updates.single.args['playing'], false,
          reason: 'a real pause must reach the OS even during a seek',);
    });
  });

  group('MediaSessionController — lifecycle', () {
    test('create() calls enable() with the initial state', () async {
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);

      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);

      expect(ch.callsOfType('enable').length, 1);
    });

    test('if mediaSession is null in state, no enable() is dispatched',
        () async {
      final rig = _Rig();
      rig.state = const PlayerState(); // mediaSession defaults to null
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);

      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);

      expect(ch.callsOfType('enable'), isEmpty);
    });

    test('a new MediaSession on the mediaSession stream triggers updateConfig',
        () async {
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);

      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);

      ch.calls.clear(); // ignore initial enable()
      rig.mediaSession.add(const MediaSession(title: 'changed'));
      await _settle();

      expect(ch.callsOfType('updateConfig').length, 1);
    });

    test(
        'changing a metadata override re-pushes metadata (not just config) '
        'so the override reaches the OS', () async {
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);
      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);
      ch.calls.clear(); // ignore initial enable()

      // setMediaSession(copyWith(title: 'X')) updates state synchronously
      // then emits on the mediaSession stream. The override lives in the
      // METADATA snapshot (not the config map), so an updateMetadata
      // carrying the new title must be pushed — regression guard: a
      // config-only push would leave the override invisible to the OS.
      const session = MediaSession(title: 'Custom Title');
      rig.state = const PlayerState(mediaSession: session);
      rig.mediaSession.add(session);
      await _settle();

      expect(ch.callsOfType('updateConfig').length, 1);
      final metaCalls = ch.callsOfType('updateMetadata');
      expect(metaCalls.length, 1,
          reason: 'an override change must push a fresh metadata snapshot',);
      final snap =
          metaCalls.single.args['metadata'] as MediaSessionMetadataSnapshot;
      expect(snap.title, 'Custom Title');
    });
  });

  group('MediaSessionController — playback signal fan-in', () {
    test('playWhenReady change triggers updatePlayback', () async {
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);
      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);
      ch.calls.clear();

      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        playWhenReady: true,
      );
      rig.playWhenReady.add(true);
      await _settle();

      expect(ch.callsOfType('updatePlayback').length, 1);
    });

    test('seekable/loop/shuffle changes in one turn coalesce into one push',
        () async {
      // Several playback signals fired in the same microtask turn collapse
      // into a single updatePlayback (the OS only needs the resolved snapshot).
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);
      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);
      ch.calls.clear();

      rig.seekable.add(false);
      rig.loop.add(Loop.file);
      rig.shuffle.add(true);
      await _settle();

      expect(ch.callsOfType('updatePlayback').length, 1,
          reason: 'same-turn playback signals coalesce',);
    });

    test('metadata signals in one turn coalesce into one updateMetadata',
        () async {
      // A file-load fans out across duration/metadata/coverArt/mediaTitle
      // in one turn — they collapse into a single push so the cover art ships
      // once, not 4×.
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);
      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);
      ch.calls.clear();

      // A genuine state change so the dedup doesn't suppress the push.
      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        duration: Duration(seconds: 30),
        metadata: {'title': 'X'},
      );
      rig.duration.add(const Duration(seconds: 30));
      rig.metadata.add(const {'title': 'X'});
      rig.coverArt.add(null);
      rig.mediaTitle.add('X');
      await _settle();

      expect(ch.callsOfType('updateMetadata').length, 1,
          reason: 'same-turn metadata signals coalesce into one push',);
    });

    test('actualPlaying + buffering ride the playback snapshot', () async {
      // The OS button binds to intent (playing=playWhenReady), but the native
      // side needs the actual-output axis to gate scrub extrapolation and show
      // a loading state — those travel as actualPlaying / buffering.
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);
      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);
      ch.calls.clear();

      // Intending to play, but no actual output yet and buffering: button stays
      // "play" (intent), but the snapshot reflects the stall.
      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        playWhenReady: true,
        buffering: true,
      );
      rig.buffering.add(true);
      await _settle();

      final snap = ch.callsOfType('updatePlayback').last.args['snapshot']
          as MediaSessionPlaybackSnapshot;
      expect(snap.playing, true, reason: 'intent axis stays true');
      expect(snap.actualPlaying, false, reason: 'no actual output during stall');
      expect(snap.buffering, true);
    });

    test('hasNext/hasPrevious reflect playlist bounds, loop, and single-item',
        () async {
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);
      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);

      const media = [
        Media('a'),
        Media('b'),
        Media('c'),
      ];

      // Middle of a multi-item playlist → both available.
      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        playlist: Playlist(media, index: 1),
      );
      rig.playWhenReady.add(true);
      await _settle();
      var snap = ch.callsOfType('updatePlayback').last.args['snapshot']
          as MediaSessionPlaybackSnapshot;
      expect(snap.hasPrevious, true);
      expect(snap.hasNext, true);

      // Last item, loop off → no next.
      ch.calls.clear();
      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        playlist: Playlist(media, index: 2),
      );
      rig.playWhenReady.add(true);
      await _settle();
      snap = ch.callsOfType('updatePlayback').last.args['snapshot']
          as MediaSessionPlaybackSnapshot;
      expect(snap.hasNext, false, reason: 'last item, no loop');
      expect(snap.hasPrevious, true);

      // Last item but loop=playlist → next wraps.
      ch.calls.clear();
      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        playlist: Playlist(media, index: 2),
        loop: Loop.playlist,
      );
      rig.loop.add(Loop.playlist);
      await _settle();
      snap = ch.callsOfType('updatePlayback').last.args['snapshot']
          as MediaSessionPlaybackSnapshot;
      expect(snap.hasNext, true, reason: 'loop=playlist wraps');

      // Single item → stays navigable (external queue can drive it).
      ch.calls.clear();
      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        playlist: Playlist([Media('only')]),
      );
      rig.playWhenReady.add(true);
      await _settle();
      snap = ch.callsOfType('updatePlayback').last.args['snapshot']
          as MediaSessionPlaybackSnapshot;
      expect(snap.hasNext, true, reason: 'single item stays navigable');
      expect(snap.hasPrevious, true);
    });

    test('an unchanged metadata snapshot is not re-pushed (dedup)', () async {
      // Re-firing a metadata signal that resolves to the same snapshot
      // (same title/artist/album/duration/cover identity) must not re-ship.
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);
      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        metadata: {'title': 'Steady'},
      );
      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);
      ch.calls.clear(); // ignore the initial enable

      // Nothing in state changed — a bare signal must not produce a push.
      rig.metadata.add(const {'title': 'Steady'});
      await _settle();

      expect(ch.callsOfType('updateMetadata'), isEmpty,
          reason: 'identical snapshot must be deduped',);
    });
  });

  group('MediaSessionController — rich metadata', () {
    test('track/disc/albumArtist/genre/url are derived from mpv tags',
        () async {
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);
      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);
      ch.calls.clear();

      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        metadata: {
          'title': 'Song',
          'album_artist': 'The Band',
          'genre': 'Metal',
          'track': '3/12', // leading int parsed
          'disc': '1',
        },
        playlist: Playlist([Media('file:///music/song.flac')]),
      );
      rig.metadata.add(const {'title': 'Song'});
      await _settle();

      final snap = ch.callsOfType('updateMetadata').last.args['metadata']
          as MediaSessionMetadataSnapshot;
      expect(snap.trackNumber, 3);
      expect(snap.discNumber, 1);
      expect(snap.albumArtist, 'The Band');
      expect(snap.genre, 'Metal');
      expect(snap.url, 'file:///music/song.flac');
    });
  });

  group('MediaSessionController — metadata & queue resolution', () {
    test('artwork override resolves none / embedded / custom', () async {
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);

      final embedded = CoverArt(
          bytes: Uint8List.fromList(const [1, 2, 3]), mimeType: 'image/png',);
      final custom = CoverArt(
          bytes: Uint8List.fromList(const [9, 9]), mimeType: 'image/jpeg',);

      // Neutral baseline so each phase below is a genuine snapshot change
      // (distinct titles defeat the dedup between phases).
      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);
      ch.calls.clear();

      // none → null even when an embedded cover is present.
      rig.state = PlayerState(
        mediaSession: const MediaSession(artwork: MediaSessionArtwork.none),
        coverArt: embedded,
        metadata: const {'title': 'p1'},
      );
      rig.metadata.add(const {'title': 'p1'});
      await _settle();
      var snap = ch.callsOfType('updateMetadata').last.args['metadata']
          as MediaSessionMetadataSnapshot;
      expect(snap.artwork, isNull, reason: 'none suppresses artwork');

      // embedded → the file's cover.
      rig.state = PlayerState(
        mediaSession: const MediaSession(),
        coverArt: embedded,
        metadata: const {'title': 'p2'},
      );
      rig.metadata.add(const {'title': 'p2'});
      await _settle();
      snap = ch.callsOfType('updateMetadata').last.args['metadata']
          as MediaSessionMetadataSnapshot;
      expect(snap.artwork, embedded);

      // custom → the supplied image, ignoring the embedded cover.
      rig.state = PlayerState(
        mediaSession: MediaSession(artwork: MediaSessionArtwork.custom(custom)),
        coverArt: embedded,
        metadata: const {'title': 'p3'},
      );
      rig.metadata.add(const {'title': 'p3'});
      await _settle();
      snap = ch.callsOfType('updateMetadata').last.args['metadata']
          as MediaSessionMetadataSnapshot;
      expect(snap.artwork, custom);
    });

    test('uri override and extras[art] fallback resolve to artworkUri',
        () async {
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);

      final embedded = CoverArt(
          bytes: Uint8List.fromList(const [1, 2, 3]), mimeType: 'image/png',);

      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);
      ch.calls.clear();

      // Explicit uri override → artworkUri, no bytes on the wire.
      rig.state = PlayerState(
        mediaSession: MediaSession(
            artwork: MediaSessionArtwork.uri(Uri.parse('https://art/1.jpg')),),
        metadata: const {'title': 'p1'},
      );
      rig.metadata.add(const {'title': 'p1'});
      await _settle();
      var snap = ch.callsOfType('updateMetadata').last.args['metadata']
          as MediaSessionMetadataSnapshot;
      expect(snap.artwork, isNull);
      expect(snap.artworkUri, 'https://art/1.jpg');

      // Default (embedded) with no embedded cover → fall back to the queue
      // item's extras['art'] (the transcoded-stream case).
      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        metadata: {'title': 'p2'},
        playlist: Playlist([
          Media('https://server/stream',
              extras: {'art': 'https://art/2.png'},),
        ]),
      );
      rig.metadata.add(const {'title': 'p2'});
      await _settle();
      snap = ch.callsOfType('updateMetadata').last.args['metadata']
          as MediaSessionMetadataSnapshot;
      expect(snap.artwork, isNull);
      expect(snap.artworkUri, 'https://art/2.png',
          reason: 'no embedded cover falls back to extras[art]',);

      // An embedded cover still wins over extras['art'].
      rig.state = PlayerState(
        mediaSession: const MediaSession(),
        coverArt: embedded,
        metadata: const {'title': 'p3'},
        playlist: const Playlist([
          Media('https://server/stream',
              extras: {'art': 'https://art/3.png'},),
        ]),
      );
      rig.metadata.add(const {'title': 'p3'});
      await _settle();
      snap = ch.callsOfType('updateMetadata').last.args['metadata']
          as MediaSessionMetadataSnapshot;
      expect(snap.artwork, embedded);
      expect(snap.artworkUri, isNull, reason: 'embedded cover wins');
    });

    test('title/artist/album fall back to queue-item extras for tag-less streams',
        () async {
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);

      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);
      ch.calls.clear();

      // A transcoded stream: no mpv tags, and media-title is the raw URL.
      // The consumer-attached extras supply the real text.
      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        mediaTitle: 'https://server/stream',
        playlist: Playlist([
          Media('https://server/stream', extras: {
            'title': 'Real Title',
            'artist': 'Real Artist',
            'album': 'Real Album',
          },),
        ]),
      );
      rig.mediaTitle.add('https://server/stream');
      await _settle();
      final snap = ch.callsOfType('updateMetadata').last.args['metadata']
          as MediaSessionMetadataSnapshot;
      expect(snap.title, 'Real Title',
          reason: 'extras title beats the URL media-title',);
      expect(snap.artist, 'Real Artist');
      expect(snap.album, 'Real Album');
      expect(snap.albumArtist, 'Real Artist',
          reason: 'album-artist line falls back to extras artist',);
    });
  });
  group('MediaSessionController — network URL privacy', () {
    MediaSessionMetadataSnapshot lastSnap(_RecordingChannel ch) =>
        ch.callsOfType('updateMetadata').last.args['metadata']
            as MediaSessionMetadataSnapshot;

    test('a network item URI is not published as url', () async {
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);
      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);
      ch.calls.clear();

      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        metadata: {'title': 'Song'},
        playlist: Playlist([
          Media('https://nd.example/rest/stream.view?id=1&u=me&t=tok&s=salt'),
        ]),
      );
      rig.metadata.add(const {'title': 'Song'});
      await _settle();
      expect(lastSnap(ch).url, isNull);

      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        metadata: {'title': 'Song'},
        playlist: Playlist([Media('/music/song.flac')]),
      );
      rig.metadata.add(const {'title': 'Song'});
      await _settle();
      expect(lastSnap(ch).url, '/music/song.flac',
          reason: 'plain local paths are still published',);
    });

    test('a URL-derived media-title loses its query and userinfo', () async {
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);
      final controller = await _buildController(rig: rig, channel: ch);
      addTearDown(controller.dispose);
      ch.calls.clear();

      Future<String?> titleFor(String uri, String mediaTitle) async {
        rig.state = PlayerState(
          mediaSession: const MediaSession(),
          mediaTitle: mediaTitle,
          playlist: Playlist([Media(uri)]),
        );
        rig.mediaTitle.add(mediaTitle);
        await _settle();
        return lastSnap(ch).title;
      }

      const stream = 'https://nd.example/rest/stream.view?id=1&u=me&t=tok&s=s';
      expect(await titleFor(stream, 'stream.view?id=1&u=me&t=tok&s=s'),
          'stream.view',);
      expect(
        await titleFor(
          'https://me:pw@radio.example/',
          'https://me:pw@radio.example/',
        ),
        'https://radio.example/',
      );
      expect(await titleFor(stream, 'Who Are You?'), 'Who Are You?',
          reason: 'a real title with a question mark is kept',);
      expect(await titleFor('/music/a?b=c.flac', 'a?b=c.flac'), 'a?b=c.flac',
          reason: 'local file names are never rewritten',);
    });

    test('with a fetcher, remote artwork is downloaded, never passed as a URL',
        () async {
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);

      final cover = CoverArt(
          bytes: Uint8List.fromList(const [7, 7]), mimeType: 'image/jpeg',);
      final pending = Completer<CoverArt?>();
      final fetched = <Uri>[];
      final controller = await _buildController(
        rig: rig,
        channel: ch,
        artworkFetcher: (uri) {
          fetched.add(uri);
          return pending.future;
        },
      );
      addTearDown(controller.dispose);
      ch.calls.clear();

      const artUrl = 'https://nd.example/rest/getCoverArt.view?t=tok';
      rig.state = const PlayerState(
        mediaSession: MediaSession(),
        metadata: {'title': 'Song'},
        playlist: Playlist([
          Media('https://nd.example/rest/stream.view?id=1',
              extras: {'art': artUrl},),
        ]),
      );
      rig.metadata.add(const {'title': 'Song'});
      await _settle();
      var snap = lastSnap(ch);
      expect(snap.artworkUri, isNull);
      expect(snap.artwork, isNull, reason: 'no art while downloading');
      expect(fetched, [Uri.parse(artUrl)]);

      pending.complete(cover);
      await _settle();
      snap = lastSnap(ch);
      expect(snap.artworkUri, isNull);
      expect(snap.artwork, cover);

      // Another metadata tick reuses the download.
      rig.metadata.add(const {'title': 'Song'});
      await _settle();
      expect(fetched, hasLength(1));
    });
  });
  group('MediaSessionController — audio output resets', () {
    test('a reset from the OS reaches the player until dispose', () async {
      final rig = _Rig();
      final ch = _RecordingChannel();
      addTearDown(rig.dispose);
      addTearDown(ch.close);
      var resets = 0;
      final controller = await _buildController(
        rig: rig,
        channel: ch,
        onAudioOutputReset: () => resets++,
      );

      ch.resets.add(null);
      await _settle();
      expect(resets, 1);

      await controller.dispose();
      ch.resets.add(null);
      await _settle();
      expect(resets, 1, reason: 'no callback after dispose');
    });
  });
}
