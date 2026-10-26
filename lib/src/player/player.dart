// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, listEquals;
import 'package:flutter/services.dart' show RootIsolateToken;
import 'package:meta/meta.dart';

import '../backend/backend.dart';
import '../dsp/filter_tap_pipeline.dart';
import '../dsp/loudness_meter_pipeline.dart';
import '../dsp/loudness_scan_pipeline.dart';
import '../dsp/spectrum_pipeline.dart';
import '../dsp/waveform_pipeline.dart';
import '../events/mpv_hook_event.dart';
import '../events/mpv_log_entry.dart';
import '../events/player_error.dart';
import '../events/player_exception.dart';
import '../generated/audio_effects_settings.dart';
import '../internals/audio_effects_validation.dart';
import '../internals/core_calls.dart';
import '../internals/core_events.dart';
import '../internals/debug_log.dart';
import '../internals/duration_seconds.dart';
import '../internals/entry_table.dart';
import '../internals/hook_table.dart';
import '../internals/libmpv_requirements.dart';
import '../internals/mpv_audio_kit.dart';
import '../internals/mpv_float.dart';
import '../internals/owned_source.dart';
import '../internals/uri_resolver.dart';
import '../media_session/media_session_controller.dart';
import '../media_session/media_session_inputs.dart';
import '../models/chapter.dart';
import '../models/cover_art.dart';
import '../models/demuxer_cache_state.dart';
import '../models/device.dart';
import '../models/fft_frame.dart';
import '../models/loudness.dart';
import '../models/loudness_scan.dart';
import '../models/media.dart';
import '../models/media_session.dart';
import '../models/pcm_frame.dart';
import '../models/playlist.dart';
import '../models/source_resolve_request.dart';
import '../models/waveform_data.dart';
import '../mpv_constants.dart' hide MpvEndFileReason;
import '../pcm/pcm_format.dart';
import '../pcm/pcm_source.dart';
import '../reactive/default_reactives.dart';
import '../reactive/default_specs.dart';
import '../reactive/node_parsers.dart';
import '../reactive/property_registry.dart';
import '../reactive/reactive_property.dart';
import '../types/enums/cover.dart';
import '../types/enums/format.dart';
import '../types/enums/gapless.dart';
import '../types/enums/hls_bitrate.dart';
import '../types/enums/hook.dart';
import '../types/enums/log_level.dart';
import '../types/enums/loop.dart';
import '../types/enums/spdif.dart';
import '../types/enums/tap_side.dart';
import '../types/sealed/channels.dart';
import '../types/sealed/media_session_command.dart';
import '../types/sealed/track.dart';
import '../types/settings/cache_settings.dart';
import '../types/settings/demuxer_settings.dart';
import '../types/settings/replay_gain_settings.dart';
import '../types/settings/spectrum_settings.dart';
import '../types/state/audio_output_state.dart';
import 'audio_output_error.dart';
import 'lifecycle_transitions.dart';
import 'player_api.dart';
import 'player_configuration.dart';
import 'player_state.dart';
import 'player_stream.dart';
import 'playlist_nav_gate.dart';

part 'mixins/player_audio.part.dart';
part 'mixins/player_dispatch.part.dart';
part 'mixins/player_ffi.part.dart';
part 'mixins/player_hooks.part.dart';
part 'mixins/player_init.part.dart';
part 'mixins/player_intent.part.dart';
part 'mixins/player_lifecycle.part.dart';
part 'mixins/player_load_validation.part.dart';
part 'mixins/player_media_session.part.dart';
part 'mixins/player_network.part.dart';
part 'mixins/player_pcm.part.dart';
part 'mixins/player_playback.part.dart';
part 'mixins/player_playlist.part.dart';

/// A high-performance audio player powered by libmpv.
///
/// Implements [PlayerApi] so test code can mock the player without
/// dragging in the FFI handle and event isolate
/// (`class MockPlayer extends Mock implements PlayerApi {}`).
class Player extends _PlayerBase
    with
        _FfiModule,
        _LoadValidationModule,
        _InitModule,
        _DispatchModule,
        _PlaybackModule,
        _PlaylistModule,
        _AudioModule,
        _NetworkModule,
        _PcmModule,
        _HooksModule,
        _MediaSessionModule
    implements PlayerApi {
  /// Creates a [Player] instance with optional [configuration].
  Player({super.configuration});

  /// Test-only. The event isolate writes to [wakeupCounterAddress] on
  /// every wakeup: a bogus value corrupts process memory.
  @visibleForTesting
  Player.testInstrumented({
    super.configuration,
    required int super.wakeupCounterAddress,
  });

  // --- Public Specialized API ---

  /// Opens a [Media] and optionally starts playback immediately.
  ///
  /// `pause` is set as a global property before `loadfile` so the
  /// property observer always fires on the first-load transition
  /// (a per-file option can skip the `PROPERTY_CHANGE` emit).
  /// Rapid back-to-back `open()` calls don't race: each call claims the
  /// load epoch synchronously and aborts at its next await once a later
  /// content-replacing call (open, openAll, openPlaylistFile, stop,
  /// clearPlaylist) has claimed a newer one, so the call that is LAST
  /// in program order wins, regardless of per-URI resolve latency.
  @override
  Future<void> open(Media media, {bool? play}) =>
      _transport.trackLoad(() => _open(media, play));

  Future<void> _open(Media media, bool? play) async {
    _checkNotDisposed();
    _validateLoadOptions(media);
    final load = _transport.claimLoad();
    await _gate();
    if (load.superseded) return;
    final shouldPlay = play ?? configuration.autoPlay;
    // Optimistic intent (the play-pause axis), written at the call point,
    // BEFORE the `resolveUri` and trust-bundle awaits below, so a play() or
    // pause() issued right after open() (without awaiting it) wins by call
    // order instead of racing this write past the I/O hops. mpv leaves
    // `pause` at `no` and fires no PROPERTY_CHANGE on the first autoplay
    // load, so the observer alone would never surface this intent.
    final previousIntent = _state.playWhenReady;
    final intent = _transport.claimIntent(shouldPlay);
    _mediaCache.clear();
    _mediaCache[media.uri] = media;
    final OwnedSource source;
    try {
      source = OwnedSource(await resolveUri(media.uri));
    } catch (_) {
      // Nothing was loaded: the intent goes back to what still plays.
      _transport.restoreIntent(load, intent, previousIntent);
      rethrow;
    }
    // Released on every way out unless mpv took the entry: a later load,
    // an error, a refusal.
    try {
      if (load.superseded) return;
      _mediaCache[source.uri] = media;
      await _forgetFdResume(source.uri);
      // Execute in-flight transport writes (e.g. an un-awaited seek) before
      // the replace below, so they apply to the OLD file; see
      // [CoreCalls.settleWrites].
      await _calls.settleWrites();
      if (load.superseded) return;
      // Captured BEFORE the pause write: when true, mpv is parked paused on
      // the last frame (`keep-open`), and the pre-loadfile `pause=no` below
      // does not survive: unpausing at EOF makes the playloop hit EOF again
      // and `keep-open-pause` re-pauses the core before the loadfile (queued
      // behind this write's async reply round-trip) is ever processed. The
      // corrective write after the replace is what actually sticks.
      final parkedAtEof = await _parkedAtEof();
      if (load.superseded) return;
      final playNow = _transport.intendedPlay(intent, shouldPlay);
      await _calls.prop('pause', playNow ? 'no' : 'yes');
      final opts = _buildLoadfileOptions(media);
      try {
        if (opts.isEmpty) {
          await _loadfile(['loadfile', source.uri, 'replace'], media, source);
        } else {
          // Per-Media `httpHeaders` and `httpChunkSize` ride along as the 4th
          // `loadfile` arg (mpv 0.38+: index must be `-1` when options are
          // present), so mpv scopes them as file-local for this exact
          // playlist entry, never writing the global `http-header-fields` or
          // `stream-lavf-o`.
          await _loadfile(
            ['loadfile', source.uri, 'replace', '-1', opts],
            media,
            source,
          );
        }
      } catch (_) {
        // mpv refused the entry and kept what it had: nothing will ever read
        // the source, and the track there goes on with its own intent and
        // pause, as after a failed [openPlaylistFile].
        if (_transport.restoreIntent(load, intent, previousIntent) &&
            playNow != previousIntent) {
          await _calls.propRc('pause', previousIntent ? 'no' : 'yes');
        }
        rethrow;
      }
      // Asked again, not reused: a pause() called while the loadfile was in
      // flight has the last word.
      if (parkedAtEof && _transport.intendedPlay(intent, shouldPlay)) {
        await _calls.prop('pause', 'no');
      }
      // Drop visible per-track state (cover art, chapter list and current
      // chapter index) so a UI that reads the state immediately after
      // `open()` returns doesn't render the previous track's data. Placed
      // AFTER the loadfile reply (not before): the async writes above
      // suspend, and by FIFO port delivery every still-queued OLD-file
      // PROPERTY_CHANGE (e.g. a trailing `chapter-list`) has been received
      // and applied by the time that reply lands: clearing here is the last
      // word before return, so none of those stale events survive into the
      // post-`open()` snapshot. The NEW file's FILE_LOADED arrives later and
      // repopulates.
      _clearPerFileState();
    } finally {
      await source.release();
    }
  }

  /// Opens a list of [Media] items as the new playlist, optionally starting at [index].
  ///
  /// Multi-media counterpart of [open]. [index] is clamped to
  /// `[0, medias.length - 1]`.
  ///
  /// Entries are appended on the core WITHOUT starting playback (mpv's
  /// `loadfile append` never autostarts), then a single
  /// `playlist-play-index` starts directly at [index]. The entry at
  /// position 0 is never loaded, played, or reported as current unless
  /// it IS the requested index, so a UI bound to
  /// [PlayerState.playlist]'s `index` never flashes track 1 before the
  /// selected track, and no audio from track 1 leaks out. During the
  /// transition the outgoing track keeps playing (or stays parked) until
  /// the jump; while entries build up on an idle core the playlist
  /// `index` reports `-1` (see [Playlist.index]).
  ///
  /// The call succeeds or fails as a whole. When mpv refuses an entry it
  /// throws [MpvCommandException], the entries it already added leave the
  /// playlist, the track that was playing keeps playing (parked at the
  /// end, the playlist is left empty), and the play intent goes back to
  /// what it was.
  @override
  Future<void> openAll(List<Media> medias, {bool? play, int index = 0}) =>
      _transport.trackLoad(() => _openAll(medias, play, index));

  Future<void> _openAll(List<Media> medias, bool? play, int index) async {
    _checkNotDisposed();
    if (medias.isEmpty) {
      return;
    }
    // Validate the full batch before any side-effect, so a bad header
    // on entry N can't leave entries 0..N-1 half-loaded.
    for (final m in medias) {
      _validateLoadOptions(m);
    }
    // Claim the load epoch synchronously; see [open].
    final load = _transport.claimLoad();
    await _gate();
    if (load.superseded) return;
    final clampedIndex = index.clamp(0, medias.length - 1);
    final shouldPlay = play ?? configuration.autoPlay;
    // Optimistic intent written at the call point, before the resolve and tls
    // awaits below; see [open] for the rationale.
    final previousIntent = _state.playWhenReady;
    final intent = _transport.claimIntent(shouldPlay);
    // Snapshot the outgoing current entry's Media so it keeps its
    // metadata while still visible in playlist events during the
    // transition (retained until the post-jump remove below).
    final oldPlaylist = _state.playlist;
    final oldCurrent =
        oldPlaylist.items.isNotEmpty &&
            oldPlaylist.index >= 0 &&
            oldPlaylist.index < oldPlaylist.items.length
        ? oldPlaylist.items[oldPlaylist.index]
        : null;
    _mediaCache.clear();
    if (oldCurrent != null) _mediaCache[oldCurrent.uri] = oldCurrent;
    // Resolve once per media: content:// resolutions detach a JVM-side
    // FD, doing it twice would leak one FD per track. Each source is
    // released on every way out unless mpv took its entry.
    final sources = <OwnedSource>[];
    try {
      try {
        for (final m in medias) {
          _mediaCache[m.uri] = m;
          final source = OwnedSource(await resolveUri(m.uri));
          sources.add(source);
          if (load.superseded) return;
          _mediaCache[source.uri] = m;
          await _forgetFdResume(source.uri);
        }
      } catch (_) {
        // Mid-loop failure: the caller observes the original error, and the
        // sources resolved so far are released on the way out.
        _transport.restoreIntent(load, intent, previousIntent);
        rethrow;
      }
      // Execute in-flight transport writes before the replace: see
      // [CoreCalls.settleWrites].
      await _calls.settleWrites();
      if (load.superseded) return;
      // ── Phase 1: clear the outgoing playlist ──────────────────────────
      final retainedOld = await _openAllClear(load);
      if (retainedOld == null) return;

      // ── Phase 2: append every entry; playback never starts here ──────
      final failure = await _openAllAppend(medias, sources, load);
      // mpv never had the refused entries, nor the ones not sent after a
      // refusal or a later load: their sources are released on the way out.
      if (failure != null) {
        // mpv turns an append down only when its reply queue is full.
        // The call fails as a whole: the entries that went in come out
        // again. `playlist-clear` keeps only the current entry, the track
        // that still plays (none at the park, removed above). The pause was
        // not written yet, so only the intent goes back. A later load owns
        // the playlist instead, and the entries mpv took stay with
        // [_entries] until they leave.
        if (!load.superseded) {
          _transport.restoreIntent(load, intent, previousIntent);
          await _calls.command(['playlist-clear']);
        }
        Error.throwWithStackTrace(failure.$1, failure.$2);
      }
      // From here on mpv has the entries, and may read them again until it
      // leaves them (a previous, a loop, a prefetch): their sources stay with
      // [_entries], which releases each one once it left the playlist and
      // mpv moved on. Released now, an Android descriptor would go to the
      // next file the app opens while mpv still lists its number.
      if (load.superseded) return;

      // ── Phase 3: intent, then one direct jump to the target ───────────
      // The pause write cannot be fought by keep-open here: the parked
      // flow already left EOF (idle after the remove above), and the
      // playing flow is mid-track. `playlist-play-index` sets
      // playlist->current straight to the target entry (mp_set_playlist_
      // entry): entries before it are never loaded or made current.
      await _calls.prop(
        'pause',
        _transport.intendedPlay(intent, shouldPlay) ? 'no' : 'yes',
      );
      final target = (retainedOld ? 1 : 0) + clampedIndex;
      // The parked flow went through idle, which does not spend the intent
      // while this call runs: see the idle-active observer.
      await _calls.commandChecked(['playlist-play-index', target.toString()]);

      // ── Phase 4: drop the retained old entry ──────────────────────────
      // Non-current by now (the jump moved current to the target), so the
      // removal is pure bookkeeping; indices shift down to their final
      // positions. Tolerant [CoreCalls.command]: a concurrent surgery that
      // already emptied position 0 must not surface as an openAll error.
      if (retainedOld) {
        // The target plays from its source now: see the check after phase 2.
        if (load.superseded) return;
        await _calls.command(['playlist-remove', '0']);
      }
      // Clear per-track state AFTER the jump's reply; see [open] for why
      // the placement (post-reply) is what makes the clear the last word
      // over trailing OLD-file PROPERTY_CHANGE events.
      _clearPerFileState();
    } finally {
      for (final source in sources) {
        await source.release();
      }
    }
  }

  /// Phase 1 of [openAll]: clears the outgoing playlist. Returns whether an
  /// old entry still occupies position 0 (the playing flow): the append
  /// targets shift by one until the post-jump remove drops it. `null` once
  /// a later load took over.
  Future<bool?> _openAllClear(_LoadTicket load) async {
    // `playlist-clear` keeps ONLY the current entry (mpv's
    // playlist_clear_except_current), so the outgoing track keeps
    // playing while the new entries build up: no idle gap, no silence.
    // The flow is decided from mpv's own properties AFTER the clear
    // (`playlist-count`, `eof-reached`), not from the Dart-side state
    // snapshot: state can lag the core by an event round-trip, and a
    // wrong guess here would offset every append target below.
    await _calls.command(['playlist-clear']);
    if (load.superseded) return null;
    final retainedCount =
        int.tryParse(await getRawProperty('playlist-count') ?? '') ?? 0;
    if (load.superseded) return null;
    var parkedAtEof = false;
    if (retainedCount > 0) {
      // A retained entry parked at EOF cannot survive the appends:
      // `keep-open` holds the park only while no next entry exists (mpv's
      // handle_keep_open), so the first append would create a "next" and
      // mpv would auto-advance into the new album's entry 0,
      // resurrecting the exact transient this flow eliminates. Remove it
      // NOW instead: the playlist is single-entry after the clear, so
      // PT_NEXT_ENTRY finds nothing and the core goes idle, where
      // appends provably never autostart.
      parkedAtEof = await _parkedAtEof();
      if (load.superseded) return null;
      if (parkedAtEof) {
        await _calls.command(['playlist-remove', '0']);
        if (load.superseded) return null;
        // Barrier: wait for the core to actually reach idle before any
        // append. The remove's playback teardown runs asynchronously on
        // the playloop, and an append landing before it completes gets
        // picked up by the end-of-file advancement (playlist_get_next
        // from a NULL current with the playlist not started returns
        // entry 0), which would start the incoming album's first track:
        // the exact transient this flow eliminates. Idle lands within a
        // playloop iteration; the bound only guards a wedged core.
        for (var i = 0; i < 100; i++) {
          if (await getRawProperty('idle-active') == 'yes') break;
          if (load.superseded) return null;
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        if (load.superseded) return null;
      }
    }
    return retainedCount > 0 && !parkedAtEof;
  }

  /// Phase 2 of [openAll]: appends [medias] from their [sources]. Returns
  /// the first refusal, `null` when mpv took every entry sent; sending
  /// stops at a refusal or once a later load took over.
  Future<(Object, StackTrace)?> _openAllAppend(
    List<Media> medias,
    List<OwnedSource> sources,
    _LoadTicket load,
  ) async {
    // mpv's `loadfile append` is play=false unconditionally (unlike
    // append-play), even on an idle core. Per-Media `httpHeaders` ride
    // along as the 4th `loadfile` arg, so mpv scopes them as file-local
    // without ever writing the global `http-header-fields` option.
    // The appends go out in windows of [_kAppendWindow], each sent at once:
    // mpv runs them in order, and the playlist changes they cause fold into
    // a few notifications. Awaited one by one, every append made mpv report
    // the whole playlist again, which grew with the square of the album
    // size. Each append holds one of the 1000 reply slots mpv keeps per
    // client until its reply is read, and a full queue refuses the next
    // request: a window waits for its replies before the next goes out.
    final appended = <int>{};
    (Object, StackTrace)? failure;
    var sent = 0;
    while (sent < medias.length && failure == null && !load.superseded) {
      final end = sent + _kAppendWindow < medias.length
          ? sent + _kAppendWindow
          : medias.length;
      // A refused append fails at once, before the loop below awaits it:
      // marked handled here, so its error reaches that loop instead of
      // surfacing as unhandled.
      final window = <Future<int?>>[
        for (var i = sent; i < end; i++)
          _loadfileEntry(
            switch (_buildLoadfileOptions(medias[i])) {
              '' => ['loadfile', sources[i].uri, 'append'],
              final opts => ['loadfile', sources[i].uri, 'append', '-1', opts],
            },
            medias[i],
            sources[i],
          )..ignore(),
      ];
      for (var j = 0; j < window.length; j++) {
        try {
          final id = await window[j];
          if (id != null) appended.add(id);
        } catch (e, st) {
          failure ??= (e, st);
        }
      }
      sent = end;
    }
    if (appended.isNotEmpty) _remapReported(appended);
    return failure;
  }

  /// Loads a playlist FILE or URL (`.m3u`, `.m3u8`, `.pls` or `.cue`) and
  /// optionally starts playback. Unlike [open], which loads [playlist] as a
  /// single entry, this parses it with mpv's `loadlist`, so its entries
  /// become the playlist. This is the path for internet-radio station lists
  /// and remote `.m3u` playlists.
  ///
  /// [PlayerStream.playlist] and [PlayerState.playlist] reflect the parsed
  /// entries once mpv expands them. When [play] is null the configuration's
  /// autoplay value decides. Replaces any currently loaded file or playlist.
  ///
  /// Per-[Media] options (`httpHeaders`, `demuxerLavfOptions`, `httpChunkSize`,
  /// `start`, `end`) are validated but NOT applied to the playlist fetch:
  /// `loadlist` has no file-local options slot. Entries parsed out of the playlist inherit the
  /// global network and demuxer settings.
  @override
  Future<void> openPlaylistFile(Media playlist, {bool? play}) =>
      _transport.trackLoad(() => _openPlaylistFile(playlist, play));

  Future<void> _openPlaylistFile(Media playlist, bool? play) async {
    _checkNotDisposed();
    _rejectPcm(playlist, 'playlist');
    _validateLoadOptions(playlist);
    // Claim the load epoch synchronously; see [open].
    final load = _transport.claimLoad();
    await _gate();
    if (load.superseded) return;
    final shouldPlay = play ?? configuration.autoPlay;
    // Optimistic intent written at the call point: same rationale as [open].
    final previousIntent = _state.playWhenReady;
    final intent = _transport.claimIntent(shouldPlay);
    _mediaCache.clear();
    final OwnedSource source;
    try {
      source = OwnedSource(await resolveUri(playlist.uri));
    } catch (_) {
      _transport.restoreIntent(load, intent, previousIntent);
      rethrow;
    }
    // Never handed over: mpv reads the list inside the command, and its
    // entries are the playlist, so nothing reads the list itself again.
    // Released on every way out.
    try {
      if (load.superseded) return;
      // Execute in-flight transport writes before the replace: see
      // [CoreCalls.settleWrites].
      await _calls.settleWrites();
      if (load.superseded) return;
      // See [open]: parked at EOF the pre-loadlist unpause doesn't survive
      // mpv's keep-open re-pause; a corrective write after the replace does.
      final parkedAtEof = await _parkedAtEof();
      if (load.superseded) return;
      final playNow = _transport.intendedPlay(intent, shouldPlay);
      await _calls.prop('pause', playNow ? 'no' : 'yes');
      try {
        await _calls.commandChecked(['loadlist', source.uri, 'replace']);
      } catch (_) {
        // mpv keeps the playlist it had when the list cannot be read, and
        // the track there goes on: the intent and the pause written above
        // go back to what they were, unless a later call took them over.
        // Tolerant write, so the error the caller sees is the loadlist one.
        if (_transport.restoreIntent(load, intent, previousIntent) &&
            playNow != previousIntent) {
          await _calls.propRc('pause', previousIntent ? 'no' : 'yes');
        }
        rethrow;
      }
      // See [open]: asked again, a pause() during the loadlist wins.
      if (parkedAtEof && _transport.intendedPlay(intent, shouldPlay)) {
        await _calls.prop('pause', 'no');
      }
      // Clear per-track state AFTER the replace's reply; see [open].
      _clearPerFileState();
    } finally {
      await source.release();
    }
  }

  @override
  Future<void> _disposeImpl() async {
    // New calls are refused from the first line, as the teardown order
    // in [_PlayerBase.dispose] says.
    _disposed = true;
    // Before the first await: a hook timer firing during the session
    // release would drop its id without continuing it (it skips the FFI
    // call once disposed), and mpv would wait on that hook at shutdown.
    // Every pending hook continues now, so the `quit` that follows finds
    // no operation held by this client. (The event isolate exits anyway,
    // on its stop flag, and mpv_terminate_destroy completes the hooks of
    // the removed client; the continue keeps the core from waiting on them
    // meanwhile.) An event is pending only once bring-up delivered it, so
    // the handle exists here.
    for (final mpvId in _hooks.takeAll()) {
      _calls.hookContinue(mpvId);
    }
    // Before the quit: an ended source wakes a reader blocked on it.
    _entries.endLive();
    // Release the OS media session BEFORE tearing libmpv down. After
    // the base teardown the FFI handle is gone: leaving the native
    // session published would surface a stale lockscreen entry
    // pointing at a dead Player, and incoming commands (play from
    // the lockscreen) would land on disposed state.
    try {
      await _releaseMediaSession();
    } catch (_) {
      // Best effort: session teardown must never block disposal.
    }
    await super._disposeImpl();
  }
}

/// Base class for [Player] containing shared state and native communication
/// logic.
///
/// Owns:
/// - the session to the core (the backend's event pump and client),
/// - the [PropertyRegistry] for the ~90 simple mpv properties,
/// - the small set of standalone [ReactiveProperty]s and [StreamController]s
///   that back state fields not directly mirrored by an mpv property
///   (lifecycle: `buffering`/`completed`; complex node parses: `playlist`,
///   `metadata`, `audioDevices`, `bufferingPercentage`; pure events: log,
///   error, hook, end-of-file, seek-completed).
abstract class _PlayerBase {
  /// The configuration captured at construction time.
  final PlayerConfiguration configuration;

  // The core and the client to it, through the backend of the platform
  // (an event isolate over FFI, or the module in WebAssembly on the web).
  // Created with the player so `dispose()` is safe even when invoked
  // synchronously after construction; the core starts in bring-up, driven
  // by `_ready`.
  final MpvSession _session;
  bool _disposed = false;

  /// The transport axis: the load epoch, the loads in flight, the
  /// play-pause intent and the file starts.
  late final _Transport _transport = _Transport(this);

  // The registered hooks and the pending hook events, with the ids the
  // library hands out and the deadlines.
  late final _hooks = HookTable(
    onTimeout: (id, name, timeout, mpvId) {
      _internalLog(
        'Hook "$name" (id=$id) timed out after ${timeout.inSeconds}s, '
        'auto-continuing to unblock mpv',
        level: LogLevel.warn,
      );
      if (!_disposed) _calls.hookContinue(mpvId);
    },
  );

  // The installed [SourceResolver]; null = feature off. Set by
  // [Player.setSourceResolver], consulted by `_routeHookEvent` on every
  // `on_load` or `on_load_fail` event.
  SourceResolver? _sourceResolver;

  // Latched when the resolver services an `on_load_fail` for the current
  // load attempt, cleared on the next START_FILE only (not on `on_load`,
  // which mpv re-enters for the same attempt after the retry). Caps the
  // resolver-driven retry at ONE per load: a resolver that keeps minting
  // fresh-but-broken URLs (e.g. a timestamped query string) would
  // otherwise put mpv in an infinite open-fail-reopen loop.
  bool _resolverRetried = false;

  // What the resolver gave for the prefetch of the next entry: the URL mpv
  // was about to open, the one it opened instead, and the load epoch then.
  // The load of that URL in the same epoch takes it once (F10).
  (String, String, _LoadTicket)? _prefetchResolved;

  PlayerState _state = const PlayerState();

  /// Reused `commit` callback for every registry dispatch: tearing off (or
  /// closing over) per event would be one piece of garbage per property
  /// change, so the tear-off is captured once.
  late final void Function(PlayerState) _commitState = _assignState;

  void _assignState(PlayerState s) => _state = s;

  final Map<String, Media> _mediaCache = {};

  /// The playlist entries this player loaded, by mpv's `playlist_entry_id`:
  /// their [Media] (unlike [_mediaCache], two entries with the same URI keep
  /// their own `extras`), and the live PCM sources and `fd://` descriptors
  /// they hold until mpv can no longer read them, so the app need not keep
  /// a reference.
  late final EntryTable _entries = EntryTable(readPlaylist: _readPlaylist);

  /// mpv's playlist, read now; `null` when the read failed or the player
  /// was disposed meanwhile.
  Future<List<Object?>?> _readPlaylist() async {
    final (rc, node) = await _calls.get('playlist', MpvFormat.mpvFormatNode);
    return rc < 0 || node is! List || _disposed ? null : node;
  }

  /// Deletes a resume point saved under the descriptor number of an
  /// `fd://` source [uri], before its load. mpv keys the point by
  /// that number, which the system hands out again to the next file
  /// opened, so a point saved for one file (0.5.1 and earlier wrote them)
  /// started another at its position. mpv reads the point as the entry
  /// loads, before any option of the entry applies, so no option can turn
  /// it off for one entry.
  Future<void> _forgetFdResume(String uri) async {
    if (!isFdUri(uri)) return;
    await _calls.command(['delete-watch-later-config', uri]);
  }

  // ── Property registry (the bulk of state: one spec per mpv property) ──
  late final DefaultPropertyReactives _reactives;
  late final PropertyRegistry _registry;

  // ── Standalone reactive properties (no 1:1 mpv property backing) ───────
  // Lifecycle flags driven by file-boundary events, not by a single property.
  final ReactiveProperty<bool> _buffering = ReactiveProperty<bool>(false);
  final ReactiveProperty<bool> _completed = ReactiveProperty<bool>(false);
  // Derived from node properties that need access to player-side context.
  final ReactiveProperty<Playlist> _playlist = ReactiveProperty<Playlist>(
    Playlist.empty,
  );
  final ReactiveProperty<Loop> _loop = ReactiveProperty<Loop>(Loop.off);
  final ReactiveProperty<List<Device>> _audioDevices =
      ReactiveProperty<List<Device>>(const [
        Device(name: 'auto', description: 'Auto'),
      ]);
  final ReactiveProperty<Map<String, String>> _metadata =
      ReactiveProperty<Map<String, String>>(const <String, String>{});
  final ReactiveProperty<double> _bufferingPercentage =
      ReactiveProperty<double>(0.0);
  final ReactiveProperty<DemuxerCacheState> _demuxerCacheState =
      ReactiveProperty<DemuxerCacheState>(DemuxerCacheState.empty);
  // OS media-session config + metadata override. Null = disabled.
  // Updated synchronously by [_MediaSessionModule.setMediaSession].
  final ReactiveProperty<MediaSession?> _mediaSession =
      ReactiveProperty<MediaSession?>(null);

  // Dart-side orchestrator that ferries state from `PlayerStream` to
  // the native media-session channel and routes inbound OS commands
  // back. Null while the session is disabled; lazily allocated on
  // first `setMediaSession(non-null)` and torn down on disable or
  // on `dispose()`.
  MediaSessionController? _mediaSessionController;

  // ── Pure event streams (no current value) ───────────────────────────────
  final StreamController<MpvFileEndedEvent> _endFileCtrl =
      StreamController<MpvFileEndedEvent>.broadcast();
  final StreamController<PlayerError> _errorCtrl =
      StreamController<PlayerError>.broadcast();
  // Log stream from the mpv engine itself (codec, demux, ao and so on).
  final StreamController<MpvLogEntry> _logCtrl =
      StreamController<MpvLogEntry>.broadcast();
  // Log stream from the Dart layer itself: node parse warnings, hook
  // timeouts, etc. Kept disjoint from `_logCtrl` so library-side noise
  // can be filtered from genuine engine messages without inspecting
  // the prefix.
  final StreamController<MpvLogEntry> _internalLogCtrl =
      StreamController<MpvLogEntry>.broadcast();
  final StreamController<MpvHookEvent> _hookCtrl =
      StreamController<MpvHookEvent>.broadcast();
  final StreamController<void> _seekCompletedCtrl =
      StreamController<void>.broadcast();
  // Nullable payload: each file-loaded transition emits exactly once,
  // with `null` when the new file has no embedded cover. This lets a
  // UI clear or reset on every track change without having to compare
  // against a separate file-transition signal.
  final StreamController<CoverArt?> _coverArtCtrl =
      StreamController<CoverArt?>.broadcast();
  // Incoming commands from the OS media session (lockscreen, BT
  // headset, Siri, Assistant), routed back from the per-platform
  // native implementation.
  final StreamController<MediaSessionCommand> _mediaSessionCommandsCtrl =
      StreamController<MediaSessionCommand>.broadcast();

  // Real-time FFT + raw PCM pipeline. Lazy: the poll loop starts only
  // when something subscribes to `stream.spectrum` or `stream.pcm`.
  late final SpectrumPipeline _spectrumPipeline;

  // Static waveform analyzer. Listener-gated: arms the native
  // analyzer and polls only while `stream.waveform` has a listener.
  late final WaveformPipeline _waveformPipeline;

  // Per-filter pre and post audio tap. Lazy: arms the analyzer-taps
  // property only when at least one [PlayerStream.tap] stream has a
  // listener.
  late final FilterTapPipeline _filterTapPipeline;

  // Live EBU R128 meter. Listener-gated: polls `af-metadata` only while
  // `stream.loudnessMeter` has a listener (the `ebur128` effect itself
  // is a stage the consumer puts in the effects chain).
  late final LoudnessMeterPipeline _loudnessMeterPipeline;

  // Offline loudness scan. Listener-gated: arms the native whole-file
  // scan and polls only while `stream.loudnessScan` has a listener.
  late final LoudnessScanPipeline _loudnessScanPipeline;

  /// Synchronous snapshot of the player's complete state. Updated on
  /// every observed property change before the corresponding stream
  /// emits.
  PlayerState get state => _state;

  /// Typed event streams for individual state fields and transient
  /// events.
  late final PlayerStream stream;

  // ── Cross-mixin surface ──────────────────────────────────────────────────
  // These members live in the `.part` mixins below but are declared here
  // (abstract) so `_PlayerBase`'s constructor, `dispose` and the sibling
  // domain mixins can call across part boundaries: `on _PlayerBase` only
  // exposes what `_PlayerBase` itself declares.

  /// See `_FfiModule` (player_ffi.part.dart).
  Future<void> _loadfile(List<String> args, Media media, OwnedSource source);

  /// See `_DispatchModule` (player_dispatch.part.dart).
  void _updatePlaylistFromNode(dynamic raw);

  /// Every call to libmpv once the player runs, on top of [_session]. All
  /// of them ride the async client API (`mpv_*_async`): the main isolate
  /// never waits for the playloop. Most setters update the state once the
  /// reply confirms the write; the play-pause intent and the settings
  /// bundles ([CoreCalls.writeBundle]) update it before the write.
  late final CoreCalls _calls;

  /// See `_LoadValidationModule` (player_load_validation.part.dart).
  String _buildLoadfileOptions(Media media);
  void _validateLoadOptions(Media media);
  void _rejectPcm(Media media, String name);

  /// See `_FfiModule`: the raw property escape hatches, redeclared here
  /// so the source-resolver driver in `_HooksModule` can read and rewrite
  /// `stream-open-filename` across the part boundary.
  Future<String?> getRawProperty(String name);
  Future<void> setRawProperty(String name, String value);

  /// See `_HooksModule` (player_hooks.part.dart): called by the dispatch
  /// layer for every MPV_EVENT_HOOK: runs the source resolver when one is
  /// installed, then either surfaces the event on [PlayerStream.hook]
  /// (user-registered hook) or continues it internally.
  Future<void> _routeHookEvent(int id, Hook hook, String name);

  /// mpv loaded a file, after applying the resume point it may hold: see
  /// `_AudioModule`.
  void _reassertAfChain();

  /// See `_InitModule` (player_init.part.dart): called by the constructor.
  Future<void> _bringUp();

  /// See `_DispatchModule` (player_dispatch.part.dart): wired as the event
  /// pump's `onEvent` during bring-up.
  void _handleEvent(MpvIsolateEvent event);

  /// See `_DispatchModule`: `setAudioDevice` reuses it to optimistically
  /// resolve the device description from the parsed `audio-device-list`.
  void _updateActiveAudioDevice(String name);

  _PlayerBase({
    this.configuration = const PlayerConfiguration(),
    int? wakeupCounterAddress,
  }) : _session = createMpvSession(wakeupCounterAddress: wakeupCounterAddress) {
    // Pure-Dart setup runs on the main isolate (microseconds).
    _reactives = DefaultPropertyReactives();
    _registry = PropertyRegistry()
      ..registerAll(
        buildDefaultSpecs(
          _reactives,
          onIdleActive: _transport.onIdle,
          onAudioOutputState: _onAudioOutputState,
        ),
      );

    // Streams that don't need the core can be wired immediately:
    // a consumer subscribing right after `Player()` sees no events
    // until init completes, which is the correct semantics.
    _wireAnalysisControllers();
    stream = PlayerStream.fromInternals(
      reactives: _reactives,
      buffering: _buffering,
      completed: _completed,
      playlist: _playlist,
      loop: _loop,
      audioDevices: _audioDevices,
      metadata: _metadata,
      bufferingPercentage: _bufferingPercentage,
      demuxerCacheState: _demuxerCacheState,
      audioEffects: _reactives.audioEffects,
      mediaSession: _mediaSession,
      endFile: _endFileCtrl.stream,
      error: _errorCtrl.stream,
      log: _logCtrl.stream,
      internalLog: _internalLogCtrl.stream,
      hook: _hookCtrl.stream,
      seekCompleted: _seekCompletedCtrl.stream,
      coverArt: replayStream(() => _state.coverArt, _coverArtCtrl.stream),
      fft: _fftCtrl.stream,
      pcm: _pcmStreamCtrl.stream,
      spectrum: _reactives.spectrum.stream,
      waveform: replayStream(() => _lastWaveform, _waveformCtrl.stream),
      loudnessMeter: _loudnessMeterCtrl.stream,
      loudnessScan: replayStream(
        () => _lastLoudnessScan,
        _loudnessScanCtrl.stream,
      ),
      tap: (filter, {instance = 0, required side}) => switch (side) {
        TapSide.pre => _filterTapPipeline.tapPre(
          audioEffectLabel(filter.filterName, instance),
        ),
        TapSide.post => _filterTapPipeline.tapPost(
          audioEffectLabel(filter.filterName, instance),
        ),
      },
      mediaSessionCommands: _mediaSessionCommandsCtrl.stream,
    );

    // Build the recipe and hand it to the session, which starts the core
    // off the UI thread's way. A failed init reaches every call that awaits
    // it; a player nobody uses yet must not report it as an unhandled
    // error.
    _ready = _bringUp()..ignore();
  }

  /// The controllers of the analysis streams (fft, pcm, waveform, loudness
  /// meter and scan), whose listeners arm the pipelines built at bring-up.
  void _wireAnalysisControllers() {
    // The fft and pcm bridges into the spectrum pipeline are listener-gated:
    // the pipeline arms its 30fps `pcm-tap-frame` poll as soon as its own
    // streams have a listener, so bridging unconditionally would keep the
    // poll running for the player's whole lifetime with zero consumers.
    // Subscribers that land before bring-up are reconciled once the
    // pipeline exists (see `_bringUp`).
    _fftCtrl = StreamController<FftFrame>.broadcast(
      onListen: () {
        if (_bringUpCompleted) {
          _fftPipeSub ??= _spectrumPipeline.fftStream.listen(_fftCtrl.add);
        }
      },
      onCancel: () {
        final sub = _fftPipeSub;
        _fftPipeSub = null;
        if (sub != null) unawaited(sub.cancel());
      },
    );
    _pcmStreamCtrl = StreamController<PcmFrame>.broadcast(
      onListen: () {
        if (_bringUpCompleted) {
          _pcmPipeSub ??= _spectrumPipeline.pcmStream.listen(
            _pcmStreamCtrl.add,
          );
        }
      },
      onCancel: () {
        final sub = _pcmPipeSub;
        _pcmPipeSub = null;
        if (sub != null) unawaited(sub.cancel());
      },
    );
    // Listener-gated: the native waveform analyzer arms only while a
    // consumer is subscribed. The pipeline is built during bring-up; a
    // subscriber that lands before then is reconciled once bring-up
    // finishes (see `_bringUp`).
    _waveformCtrl = StreamController<WaveformData?>.broadcast(
      onListen: () {
        if (_bringUpCompleted) _waveformPipeline.setEnabled(true);
      },
      onCancel: () {
        if (!_bringUpCompleted) return;
        _waveformPipeline.setEnabled(false);
      },
    );
    // Same listener-gating as the waveform: the af-metadata poll runs
    // only while someone is subscribed to `stream.loudnessMeter`.
    _loudnessMeterCtrl = StreamController<Loudness>.broadcast(
      onListen: () {
        if (_bringUpCompleted) _loudnessMeterPipeline.setEnabled(true);
      },
      onCancel: () {
        if (_bringUpCompleted) _loudnessMeterPipeline.setEnabled(false);
      },
    );
    // Listener-gated like the waveform: the native whole-file scan runs
    // only while someone is subscribed to `stream.loudnessScan`.
    _loudnessScanCtrl = StreamController<LoudnessScan?>.broadcast(
      onListen: () {
        if (_bringUpCompleted) _loudnessScanPipeline.setEnabled(true);
      },
      onCancel: () {
        if (_bringUpCompleted) _loudnessScanPipeline.setEnabled(false);
      },
    );
  }

  /// Test-only: allows tests to await the post-`Player()` init that
  /// runs in the background. Public methods already
  /// `await _ready` internally so consumers don't normally need this.
  @visibleForTesting
  Future<void> get ready => _ready;

  late final Future<void> _ready;
  bool _bringUpCompleted = false;

  /// The level of the last [setLogLevel] call, applied at the end of
  /// bring-up when the call came before it.
  LogLevel? _pendingLogLevel;

  late final StreamController<FftFrame> _fftCtrl;
  late final StreamController<PcmFrame> _pcmStreamCtrl;
  // Lazy bridges into the spectrum pipeline: non-null exactly while the
  // matching public stream has a listener (they keep the pipeline's
  // listener-gated poll loop armed; see the controllers' onListen).
  StreamSubscription<FftFrame>? _fftPipeSub;
  StreamSubscription<PcmFrame>? _pcmPipeSub;
  late final StreamController<WaveformData?> _waveformCtrl;
  // The last envelope and scan result, replayed to a new subscriber of
  // `stream.waveform` and `stream.loudnessScan`.
  WaveformData? _lastWaveform;
  LoudnessScan? _lastLoudnessScan;
  late final StreamController<Loudness> _loudnessMeterCtrl;
  late final StreamController<LoudnessScan?> _loudnessScanCtrl;

  void _checkNotDisposed() {
    if (_disposed) {
      throw const PlayerDisposedException();
    }
  }

  /// Shared prologue for every public method that touches the core: fail
  /// fast when already disposed, await bring-up, then verify bring-up
  /// actually completed. A dispose() that lands while the caller is parked
  /// on [_ready] aborts bring-up early: [_ready] still completes normally,
  /// but [_calls] was never assigned, so resuming into a call would throw
  /// [LateInitializationError] instead of the [PlayerDisposedException]
  /// the API contract promises.
  Future<void> _gate() async {
    _checkNotDisposed();
    await _ready;
    if (!_bringUpCompleted) {
      throw const PlayerDisposedException();
    }
  }

  /// Rejects NaN, +Inf and -Inf before they reach `toStringAsFixed`,
  /// which would emit the literal `'NaN'` or `'Infinity'` and have mpv
  /// reject the property write at the FFI boundary. Catching it on the
  /// wrapper side gives the caller a precise [ArgumentError] naming the
  /// parameter, instead of an opaque [MpvCommandException] from libmpv.
  /// Throws [RangeError] unless [value] is finite and within
  /// `[min, max]`, the range mpv accepts for the option behind it.
  void _checkRange(double value, double min, double max, String paramName) {
    _checkFinite(value, paramName);
    if (value < min || value > max) {
      throw RangeError.value(
        value,
        paramName,
        max == double.maxFinite ? 'must be >= $min' : 'must be in [$min, $max]',
      );
    }
  }

  void _checkFinite(double value, String paramName) {
    if (!value.isFinite) {
      throw ArgumentError.value(
        value,
        paramName,
        'Expected a finite double (got NaN/Infinity)',
      );
    }
  }

  // --- Internal State Pipeline ---

  /// Optimistic state update used by every typed setter after pushing
  /// a value to mpv. Writes [value] into [reactive] (which dedups, so
  /// equal writes are silent on the stream) and folds it into [_state]
  /// via [updater]. Short-circuits on dedup to skip a redundant
  /// [PlayerState] allocation.
  void _updateField<T>(
    PlayerState Function(PlayerState) updater,
    ReactiveProperty<T> reactive,
    T value,
  ) {
    if (!reactive.update(value)) return;
    _state = updater(_state);
  }

  /// mpv reported the output [state]: an output that failed is an error on
  /// [PlayerStream.error], and one that opened may be the null driver.
  void _onAudioOutputState(AudioOutputState state) {
    final err = buildAudioOutputError(state);
    if (err != null) _errorCtrl.add(err);
    if (state == AudioOutputState.active) {
      unawaited(_reportNullFallback());
    }
  }

  /// The output just opened. With `audio-fallback-to-null` (pre-init
  /// options) mpv opens the null driver when no device can be opened: the
  /// state says `active` and the position runs, but nothing is heard.
  /// Reported on [PlayerStream.error] once for each opening, unless the
  /// app chose the null driver itself. Read from the core, not the state:
  /// `current-ao` is reported after `audio-output-state`.
  Future<void> _reportNullFallback() async {
    if (!_bringUpCompleted || _disposed) return;
    final (rc, current) = await _calls.get(
      'current-ao',
      MpvFormat.mpvFormatString,
    );
    if (rc < 0 || current != 'null' || _disposed) return;
    final (aoRc, ao) = await _calls.get('ao', MpvFormat.mpvFormatString);
    if (aoRc < 0 || ao is! String || aoListHasNull(ao) || _disposed) return;
    _errorCtrl.add(nullOutputError);
  }

  /// Internal log helper: emits on the library-side log channel
  /// ([PlayerStream.internalLog]), kept separate from mpv's engine log
  /// stream ([PlayerStream.log]). Dropped once dispose closed the channel:
  /// an async path (a source resolver failing late) can still log then.
  void _internalLog(String message, {LogLevel level = LogLevel.info}) {
    if (_internalLogCtrl.isClosed) return;
    _internalLogCtrl.add(
      MpvLogEntry(prefix: 'mpv_audio_kit', level: level, text: message),
    );
  }

  /// Tears down the player.
  ///
  /// The teardown order is load-bearing. The sequence is:
  ///
  /// 1. **Flip `_disposed`** so any subsequent setter or public-API call
  ///    fails fast via `_checkNotDisposed()`. Before any await, continue
  ///    the pending hooks and end the live PCM sources (a reader blocked
  ///    on one wakes up), then release the OS media session.
  /// 2. **Await bring-up**, then **drop the core from the Hot Restart
  ///    cleanup** ([MpvSession.untrack]) so a hot-restart that fires before
  ///    the destroy completes doesn't try to clean up a handle we're
  ///    already cleaning up, and **dispose the DSP pipelines** (each turns
  ///    off what it armed).
  /// 3. **Send the `quit` command** to mpv. mpv processes it
  ///    asynchronously and fires `MPV_EVENT_SHUTDOWN` inside its own
  ///    event queue.
  /// 4. **`requestStop` (stop flag + `mpv_wakeup` natively)** so the event loop
  ///    unwinds deterministically even if `quit` was dropped or
  ///    `MPV_EVENT_SHUTDOWN` is delayed by a stalled hook. Then dispose
  ///    the filter taps, whose streams the app listens to directly.
  /// 5. **Await [MpvSession.stop]**, which returns `true` only once the
  ///    event pump has ACTUALLY stopped (natively, the isolate exited), so
  ///    it is provably off `mpv_wait_event`. Then wait (bounded) for any
  ///    `registerHook` still running `mpv_hook_add`, and **close the
  ///    client**, which settles every in-flight call.
  /// 6. **[MpvSession.terminateDestroy]** ONLY when the exit and the hook
  ///    registrations are confirmed, in a throwaway isolate and awaited
  ///    (it waits for the core to shut down and the output to close),
  ///    then release the held `content://` descriptors. Destroying the
  ///    handle while the isolate is still inside `mpv_wait_event` would
  ///    race the event-loop thread and crash libmpv when the handle is
  ///    freed mid-syscall; on an unconfirmed exit we skip destroy and let
  ///    the OS reclaim the handle.
  /// 7. **Close all reactive properties + controllers**. Order within
  ///    this group does not matter for correctness (they tolerate
  ///    `close()` while a listener is attached); grouping by ownership
  ///    is for auditability. The closes are not awaited: an active
  ///    listener gets `done` right after dispose completes, a paused one
  ///    when it resumes.
  ///
  /// Idempotent AND await-safe: every call, including concurrent ones,
  /// returns the same teardown future, so a second `await dispose()`
  /// completes only when the teardown has actually finished (a bare
  /// `_disposed` early-return would let the second caller proceed while
  /// native resources are still being released).
  Future<void> dispose() => _disposeFuture ??= _disposeImpl();

  Future<void>? _disposeFuture;

  Future<void> _disposeImpl() async {
    // `_disposed` is already set: [Player._disposeImpl] sets it on its
    // first line, before its own steps.

    // Wait for init to settle. The handle, lib and native-resources
    // fields are only assigned when bring-up reaches the very end of
    // its body, so `_bringUpCompleted` is the authoritative gate for
    // touching them, even if `_ready` resolved without throwing it
    // may have early-returned because dispose flipped during init.
    try {
      await _ready;
    } catch (_) {}

    if (_bringUpCompleted) {
      _session.untrack();
      await _waveformPipeline.dispose();
      await _spectrumPipeline.dispose();
      await _loudnessMeterPipeline.dispose();
      await _loudnessScanPipeline.dispose();
      // Cooperative quit: mpv fires MPV_EVENT_SHUTDOWN and the isolate's
      // mpv_wait_event returns. requestStop (stop flag + mpv_wakeup) unblocks
      // the loop deterministically even if `quit` was dropped or SHUTDOWN is
      // delayed by a stalled hook. mpv_terminate_destroy runs only AFTER the
      // confirmed exit below: destroying mid-syscall would crash libmpv.
      // Fire-and-forget: quit's reply may never be forwarded (the isolate is
      // about to stop): the drain below settles the dangling future.
      unawaited(_calls.command(['quit']));
      _session.requestStop();
      // The taps after the quit: their streams are the app's own, and
      // nothing a listener does may keep mpv alive. The analyzer-taps write
      // still reaches the core, which serves it before the destroy below.
      await _filterTapPipeline.dispose();
      final exited = await _session.stop();
      // A registerHook may still be running mpv_hook_add against this
      // handle: it MUST finish before the handle is freed below. quit + the
      // stop above have driven the core toward a dispatch point, so the
      // core-locked hook_add is granted and returns. Bounded: if it doesn't
      // settle (a pathologically stuck playloop), skip the destroy and leak
      // the handle rather than free it under the running call (same
      // trade-off as an unconfirmed event-isolate exit).
      final hooksSettled = await _session.settleHookAdds(
        const Duration(seconds: 2),
      );
      // From here no FFI may touch the handle, and no reply can arrive:
      // closing the client resolves every in-flight call, so an
      // `await player.setX(...)` racing dispose never hangs, and turns the
      // continuations that resumes (a setter suspended between writes)
      // into no-ops, while the destroy below frees the handle.
      _session.close();
      if (exited && hooksSettled) {
        // Off the main isolate: the destroy waits for the core to shut down.
        await _session.terminateDestroy();
        // mpv is gone: nothing reads the descriptors any more.
        for (final release in _entries.takeAll()) {
          await release();
        }
      } else {
        // The worker did not confirm it left mpv_wait_event within the bound.
        // Skip mpv_terminate_destroy: freeing the handle while the isolate may
        // still be inside the syscall would SIGSEGV. The OS reclaims the handle
        // (and the leaked stop flag) at process exit.
        debugLog(
          'mpv_audio_kit: event isolate did not confirm exit; skipping '
          'mpv_terminate_destroy to avoid a parked-handle crash.',
        );
      }
    } else {
      // Bring-up never completed: either init failed, or this dispose
      // aborted it, in which case bring-up's early-return branch (the
      // only code that ever saw the handle) has already quit the core
      // and stopped the worker, and the `await _ready` above waited for
      // that teardown. The stop() here is a best-effort no-op backstop.
      try {
        await _session.stop();
      } catch (_) {}
    }

    // Tear down the media-session controller before closing the
    // backing reactives: its subscriptions need live streams to
    // cancel cleanly, and its final `disable()` call to native
    // needs the controller still wired. `Player._disposeImpl` already
    // calls `_releaseMediaSession()` (which tears the controller
    // down) before reaching here, but we double-check for safety in
    // case a future code path skips that step.
    final controller = _mediaSessionController;
    _mediaSessionController = null;
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {
        // Best effort: never block disposal on session teardown.
      }
    }

    await _closeStreams();
  }

  /// The last step of [dispose]: closes every reactive property and stream
  /// controller, so each stream of [stream] ends.
  Future<void> _closeStreams() async {
    // Close registry-backed reactives, then standalone ones, then
    // pure-event controllers. Order is for auditability: close() is
    // safe with attached listeners. None is awaited: a listener the app
    // keeps paused takes the done only when it resumes, so waiting would
    // hold dispose forever. An active listener gets it right after.
    unawaited(_registry.closeAll());
    unawaited(
      Future.wait<void>([
        _buffering.close(),
        _completed.close(),
        _playlist.close(),
        _loop.close(),
        _audioDevices.close(),
        _metadata.close(),
        _bufferingPercentage.close(),
        _demuxerCacheState.close(),
        _mediaSession.close(),
        // Reactives the player writes itself, outside the registry.
        _reactives.playWhenReady.close(),
        _reactives.audioDevice.close(),
        _reactives.audioEffects.close(),
        _reactives.tlsCaFile.close(),
        _reactives.spectrum.close(),
      ]),
    );
    // Drop the lazy spectrum bridges before closing their controllers:
    // a dispose with a live fft or pcm listener must not leave the pipeline's
    // poll loop armed against a torn-down handle.
    await _fftPipeSub?.cancel();
    _fftPipeSub = null;
    await _pcmPipeSub?.cancel();
    _pcmPipeSub = null;
    unawaited(
      Future.wait<void>([
        _endFileCtrl.close(),
        _errorCtrl.close(),
        _logCtrl.close(),
        _internalLogCtrl.close(),
        _hookCtrl.close(),
        _seekCompletedCtrl.close(),
        _coverArtCtrl.close(),
        _mediaSessionCommandsCtrl.close(),
        // Player-side DSP controllers: the pipelines close their own
        // internal streams, which completes the forwarding subscriptions
        // but does NOT propagate `done` to these: without an explicit
        // close, a consumer awaiting `stream.fft.first` (etc.) across a
        // dispose would hang forever.
        _fftCtrl.close(),
        _pcmStreamCtrl.close(),
        _waveformCtrl.close(),
        _loudnessMeterCtrl.close(),
        _loudnessScanCtrl.close(),
      ]),
    );
  }
}

/// How many `loadfile append` requests [Player.openAll] has in flight at
/// most: well under the 1000 replies mpv queues per client, so the appends
/// leave room for the events and the other calls.
const _kAppendWindow = 512;

/// The chain label of the first enabled [Ebur128Effect] in [effects] with
/// its `metadata` option on, the stage the live loudness meter reads;
/// `null` when none runs. A stage without metadata publishes nothing.
String? _meterLabel(List<AudioEffect> effects) {
  final labels = audioEffectLabels(effects);
  for (var i = 0; i < effects.length; i++) {
    final e = effects[i];
    if (e is Ebur128Effect && e.enabled && e.metadata) return labels[i];
  }
  return null;
}
