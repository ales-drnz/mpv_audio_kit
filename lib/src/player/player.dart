// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart' show RootIsolateToken;
import 'package:meta/meta.dart';

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
import '../internals/debug_log.dart';
import '../internals/duration_seconds.dart';
import '../internals/event_isolate.dart';
import '../internals/held_sources.dart';
import '../internals/hook_table.dart';
import '../internals/libmpv_release.dart';
import '../internals/library_loader.dart';
import '../internals/mpv_client.dart';
import '../internals/mpv_float.dart';
import '../internals/orphan_handle_tracker.dart';
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
import '../mpv_bindings.dart' hide MpvEndFileReason;
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

export '../events/mpv_hook_event.dart';
export '../events/mpv_log_entry.dart';
export '../generated/audio_effects.dart';
export '../generated/audio_effects_settings.dart'
    hide
        audioEffectLabel,
        audioEffectLabels,
        audioEffectsChain,
        audioEffectsDiff;
export '../models/audio_params.dart';
export '../models/cover_art.dart';
export '../models/device.dart';
export '../models/loudness.dart';
export '../models/media.dart';
export '../models/media_session.dart';
export '../models/playlist.dart';
export '../models/source_resolve_request.dart';
export '../pcm/pcm_format.dart';
export '../pcm/pcm_source.dart' show PcmSource, PcmSourceState;
export '../types/enums/format.dart';
export '../types/enums/interruption_policy.dart';
export '../types/enums/loop.dart';
export '../types/enums/media_action.dart';
export '../types/sealed/channels.dart';
export '../types/sealed/media_session_artwork.dart';
export '../types/sealed/media_session_command.dart';
export '../types/sealed/track.dart';
export '../types/settings/spectrum_settings.dart';
export 'player_configuration.dart';
export 'player_state.dart';
export 'player_stream.dart';

part 'mixins/player_audio.part.dart';
part 'mixins/player_dispatch.part.dart';
part 'mixins/player_ffi.part.dart';
part 'mixins/player_hooks.part.dart';
part 'mixins/player_init.part.dart';
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

  /// Single-instance guard for the OS media session. A static, so it
  /// holds per isolate, and so per Flutter engine: the players of two
  /// engines do not see each other's.
  /// SMTC (Windows) and MPNowPlayingInfoCenter (Apple) are
  /// single-instance per process: enabling on a second [Player]
  /// would silently steal the first one's lockscreen entry. Linux
  /// MPRIS could support multiple instances via `instance<PID>`
  /// suffixing, but we ban it universally for cross-OS consistency.
  /// Cleared on `dispose()` and on `setMediaSession(null)`.
  static Player? _mediaSessionOwner;

  /// The media-session work of every [Player] in this isolate, one call
  /// after the other. See [_MediaSessionModule._queueMediaSessionSync].
  static Future<void> _mediaSessionQueue = Future<void>.value();

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
      _trackLoad(() => _open(media, play));

  Future<void> _open(Media media, bool? play) async {
    _checkNotDisposed();
    _validateLoadOptions(media);
    final load = _claimLoad();
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
    final intent = _claimIntent(shouldPlay);
    _mediaCache.clear();
    _mediaCache[media.uri] = media;
    final ResolvedUri resolved;
    try {
      resolved = _hold(await resolveUri(media.uri));
    } catch (_) {
      // Nothing was loaded: the intent goes back to what still plays.
      _restoreIntent(load, intent, previousIntent);
      rethrow;
    }
    if (load.superseded) {
      await resolved.dispose?.call();
      return;
    }
    _mediaCache[resolved.uri] = media;
    await _forgetFdResume(resolved);
    // Execute in-flight transport writes (e.g. an un-awaited seek) before
    // the replace below, so they apply to the OLD file; see [_settleWrites].
    await _settleWrites();
    if (load.superseded) {
      await resolved.dispose?.call();
      return;
    }
    // Captured BEFORE the pause write: when true, mpv is parked paused on
    // the last frame (`keep-open`), and the pre-loadfile `pause=no` below
    // does not survive: unpausing at EOF makes the playloop hit EOF again
    // and `keep-open-pause` re-pauses the core before the loadfile (queued
    // behind this write's async reply round-trip) is ever processed. The
    // corrective write after the replace is what actually sticks.
    final parkedAtEof = await _parkedAtEof();
    if (load.superseded) {
      await resolved.dispose?.call();
      return;
    }
    final playNow = _intendedPlay(intent, shouldPlay);
    await _prop('pause', playNow ? 'no' : 'yes');
    final opts = _buildLoadfileOptions(media);
    try {
      if (opts.isEmpty) {
        await _loadfile(['loadfile', resolved.uri, 'replace'], media);
      } else {
        // Per-Media `httpHeaders` and `httpChunkSize` ride along as the 4th
        // `loadfile` arg (mpv 0.38+: index must be `-1` when options are
        // present), so mpv scopes them as file-local for this exact playlist
        // entry, never writing the global `http-header-fields` or
        // `stream-lavf-o`.
        await _loadfile([
          'loadfile',
          resolved.uri,
          'replace',
          '-1',
          opts,
        ], media);
      }
    } catch (_) {
      // mpv refused the entry and kept what it had: nothing will ever read
      // the source, and the track there goes on with its own intent and
      // pause, as after a failed [openPlaylistFile].
      await resolved.dispose?.call();
      if (_restoreIntent(load, intent, previousIntent) &&
          playNow != previousIntent) {
        await _propRc('pause', previousIntent ? 'no' : 'yes');
      }
      rethrow;
    }
    // Asked again, not reused: a pause() called while the loadfile was in
    // flight has the last word.
    if (parkedAtEof && _intendedPlay(intent, shouldPlay)) {
      await _prop('pause', 'no');
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
      _trackLoad(() => _openAll(medias, play, index));

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
    final load = _claimLoad();
    await _gate();
    if (load.superseded) return;
    final clampedIndex = index.clamp(0, medias.length - 1);
    final shouldPlay = play ?? configuration.autoPlay;
    // Optimistic intent written at the call point, before the resolve and tls
    // awaits below; see [open] for the rationale.
    final previousIntent = _state.playWhenReady;
    final intent = _claimIntent(shouldPlay);
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
    // FD, doing it twice would leak one FD per track.
    final resolved = <ResolvedUri>[];
    try {
      for (final m in medias) {
        _mediaCache[m.uri] = m;
        final r = _hold(await resolveUri(m.uri));
        if (load.superseded) {
          await r.dispose?.call();
          for (final prior in resolved) {
            await prior.dispose?.call();
          }
          return;
        }
        _mediaCache[r.uri] = m;
        resolved.add(r);
        await _forgetFdResume(r);
      }
    } catch (_) {
      // Mid-loop failure: dispose the partially-resolved entries to
      // avoid leaking content:// file descriptors and asset cache files,
      // then rethrow so the caller observes the original error.
      for (final prior in resolved) {
        await prior.dispose?.call();
      }
      _restoreIntent(load, intent, previousIntent);
      rethrow;
    }
    // Execute in-flight transport writes before the replace: see
    // [_settleWrites].
    await _settleWrites();
    if (load.superseded) {
      for (final prior in resolved) {
        await prior.dispose?.call();
      }
      return;
    }
    // ── Phase 1: clear the outgoing playlist ──────────────────────────
    // `playlist-clear` keeps ONLY the current entry (mpv's
    // playlist_clear_except_current), so the outgoing track keeps
    // playing while the new entries build up: no idle gap, no silence.
    // The flow is decided from mpv's own properties AFTER the clear
    // (`playlist-count`, `eof-reached`), not from the Dart-side state
    // snapshot: state can lag the core by an event round-trip, and a
    // wrong guess here would offset every append target below.
    Future<void> bailDisposing() async {
      for (final prior in resolved) {
        await prior.dispose?.call();
      }
    }

    await _command(['playlist-clear']);
    if (load.superseded) return bailDisposing();
    final retainedCount =
        int.tryParse(await getRawProperty('playlist-count') ?? '') ?? 0;
    if (load.superseded) return bailDisposing();
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
      if (load.superseded) return bailDisposing();
      if (parkedAtEof) {
        await _command(['playlist-remove', '0']);
        if (load.superseded) return bailDisposing();
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
          if (load.superseded) return bailDisposing();
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        if (load.superseded) return bailDisposing();
      }
    }
    // Whether an old entry is still occupying position 0 (the playing
    // flow): the append targets shift by one until the post-jump remove
    // drops it.
    final retainedOld = retainedCount > 0 && !parkedAtEof;

    // ── Phase 2: append every entry; playback never starts here ──────
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
    // By index, not by id: an accepted append can reply without an id.
    final refused = <int>[];
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
          _loadfileEntry(switch (_buildLoadfileOptions(medias[i])) {
            '' => ['loadfile', resolved[i].uri, 'append'],
            final opts => ['loadfile', resolved[i].uri, 'append', '-1', opts],
          }, medias[i])..ignore(),
      ];
      for (var j = 0; j < window.length; j++) {
        try {
          final id = await window[j];
          if (id != null) appended.add(id);
        } catch (e, st) {
          refused.add(sent + j);
          failure ??= (e, st);
        }
      }
      sent = end;
    }
    if (appended.isNotEmpty) _remapReported(appended);
    // mpv never had the refused entries, nor the ones not sent after a
    // refusal or a later load: nothing reads their sources.
    for (final i in [
      ...refused,
      for (var i = sent; i < medias.length; i++) i,
    ]) {
      await resolved[i].dispose?.call();
    }
    if (failure != null) {
      // mpv turns an append down only when its reply queue is full.
      // The call fails as a whole: the entries that went in come out
      // again. `playlist-clear` keeps only the current entry, the track
      // that still plays (none at the park, removed above). The pause was
      // not written yet, so only the intent goes back. A later load owns
      // the playlist instead, and the entries mpv took stay with
      // [_heldSources] until they leave.
      if (!load.superseded) {
        _restoreIntent(load, intent, previousIntent);
        await _command(['playlist-clear']);
      }
      Error.throwWithStackTrace(failure.$1, failure.$2);
    }
    // From here on mpv has the entries, and may read them again until it
    // leaves them (a previous, a loop, a prefetch): their sources stay with
    // [_heldSources], which releases each one once it left the playlist and
    // mpv moved on. Released now, an Android descriptor would go to the
    // next file the app opens while mpv still lists its number.
    if (load.superseded) return;

    // ── Phase 3: intent, then one direct jump to the target ───────────
    // The pause write cannot be fought by keep-open here: the parked
    // flow already left EOF (idle after the remove above), and the
    // playing flow is mid-track. `playlist-play-index` sets
    // playlist->current straight to the target entry (mp_set_playlist_
    // entry): entries before it are never loaded or made current.
    await _prop('pause', _intendedPlay(intent, shouldPlay) ? 'no' : 'yes');
    final target = (retainedOld ? 1 : 0) + clampedIndex;
    // The parked flow went through idle, which does not spend the intent
    // while this call runs: see the idle-active observer.
    await _commandChecked(['playlist-play-index', target.toString()]);

    // ── Phase 4: drop the retained old entry ──────────────────────────
    // Non-current by now (the jump moved current to the target), so the
    // removal is pure bookkeeping; indices shift down to their final
    // positions. Tolerant `_command`: a concurrent surgery that already
    // emptied position 0 must not surface as an openAll error.
    if (retainedOld) {
      // The target plays from its source now: see the check after phase 2.
      if (load.superseded) return;
      await _command(['playlist-remove', '0']);
    }
    // Clear per-track state AFTER the jump's reply; see [open] for why
    // the placement (post-reply) is what makes the clear the last word
    // over trailing OLD-file PROPERTY_CHANGE events.
    _clearPerFileState();
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
      _trackLoad(() => _openPlaylistFile(playlist, play));

  Future<void> _openPlaylistFile(Media playlist, bool? play) async {
    _checkNotDisposed();
    _rejectPcm(playlist, 'playlist');
    _validateLoadOptions(playlist);
    // Claim the load epoch synchronously; see [open].
    final load = _claimLoad();
    await _gate();
    if (load.superseded) return;
    final shouldPlay = play ?? configuration.autoPlay;
    // Optimistic intent written at the call point: same rationale as [open].
    final previousIntent = _state.playWhenReady;
    final intent = _claimIntent(shouldPlay);
    _mediaCache.clear();
    final ResolvedUri resolved;
    try {
      resolved = await resolveUri(playlist.uri);
    } catch (_) {
      _restoreIntent(load, intent, previousIntent);
      rethrow;
    }
    if (load.superseded) {
      await resolved.dispose?.call();
      return;
    }
    // Execute in-flight transport writes before the replace: see
    // [_settleWrites].
    await _settleWrites();
    if (load.superseded) {
      await resolved.dispose?.call();
      return;
    }
    // See [open]: parked at EOF the pre-loadlist unpause doesn't survive
    // mpv's keep-open re-pause; a corrective write after the replace does.
    final parkedAtEof = await _parkedAtEof();
    if (load.superseded) {
      await resolved.dispose?.call();
      return;
    }
    final playNow = _intendedPlay(intent, shouldPlay);
    await _prop('pause', playNow ? 'no' : 'yes');
    try {
      await _commandChecked(['loadlist', resolved.uri, 'replace']);
    } catch (_) {
      // mpv keeps the playlist it had when the list cannot be read, and the
      // track there goes on: the intent and the pause written above go back
      // to what they were, unless a later call took them over. Tolerant
      // write, so the error the caller sees is the loadlist one.
      if (_restoreIntent(load, intent, previousIntent) &&
          playNow != previousIntent) {
        await _propRc('pause', previousIntent ? 'no' : 'yes');
      }
      rethrow;
    } finally {
      // mpv reads the list inside the command; its entries are the
      // playlist, so nothing reads the list itself again.
      await resolved.dispose?.call();
    }
    // See [open]: asked again, a pause() during the loadlist wins.
    if (parkedAtEof && _intendedPlay(intent, shouldPlay)) {
      await _prop('pause', 'no');
    }
    // Clear per-track state AFTER the replace's reply; see [open].
    _clearPerFileState();
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
      _lib.mpvHookContinue(_handle, mpvId);
    }
    // Before the quit: an ended source wakes a reader blocked on it.
    _endPcmSources();
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
/// - the FFI handle and event-isolate plumbing,
/// - the [PropertyRegistry] for the ~90 simple mpv properties,
/// - the small set of standalone [ReactiveProperty]s and [StreamController]s
///   that back state fields not directly mirrored by an mpv property
///   (lifecycle: `buffering`/`completed`; complex node parses: `playlist`,
///   `metadata`, `audioDevices`, `bufferingPercentage`; pure events: log,
///   error, hook, end-of-file, seek-completed).
abstract class _PlayerBase {
  /// The configuration captured at construction time.
  final PlayerConfiguration configuration;

  late final MpvLibrary _lib;
  late final Pointer<MpvHandle> _handle;
  // Eagerly instantiated so `dispose()` is safe even when invoked
  // synchronously after construction. The actual mpv init runs
  // inside the isolate, driven by `_ready`.
  final MpvEventIsolate _eventIsolate = MpvEventIsolate();
  bool _disposed = false;

  // Latched true on the first MPV_EVENT_START_FILE. Gates the idle-active
  // intent reset and [_settleEndOfContent]: the initial observe burst
  // delivers `idle-active=true` (the player starts idle) BEFORE any file
  // load is attempted, and that stale value must not clear a
  // `playWhenReady` intent set by an open(play: true) that is still
  // settling. Port delivery is FIFO, so the
  // startup idle-active always precedes the first START_FILE. Latching on
  // START_FILE (which fires even for a load that fails to open) rather than
  // FILE_LOADED means a failed first open() still arms the reset, so its
  // intent doesn't stick true.
  bool _hasLoadedFile = false;

  // The registered hooks and the pending hook events, with the ids the
  // library hands out and the deadlines.
  late final _hooks = HookTable(
    onTimeout: (id, name, timeout, mpvId) {
      _internalLog(
        'Hook "$name" (id=$id) timed out after ${timeout.inSeconds}s, '
        'auto-continuing to unblock mpv',
        level: LogLevel.warn,
      );
      if (!_disposed) _lib.mpvHookContinue(_handle, mpvId);
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

  // From START_FILE to the FILE_LOADED or END_FILE of that load. An
  // `on_load` outside it is the prefetch of the next entry, which mpv runs
  // while the current file plays, with no START_FILE.
  bool _loadingEntry = false;

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

  /// The live PCM source of each playlist entry that plays one, by mpv's
  /// `playlist_entry_id`: held while the entry is in the playlist and the
  /// source not done, so the app need not keep a reference.
  final Map<int, PcmSource> _pcmByEntry = {};

  /// The entries of [_pcmByEntry] a playlist node has shown.
  final Set<int> _pcmSeen = {};

  /// See `_PcmModule` (player_pcm.part.dart).
  void _holdPcm(int? entryId, Media media);
  void _prunePcm(Set<int> live);

  /// The [Media] of each playlist entry this player loaded, by mpv's
  /// `playlist_entry_id`. Unlike [_mediaCache], two entries with the same
  /// URI keep their own `extras`. Pruned to the live entries on every
  /// playlist change.
  final Map<int, Media> _mediaByEntry = {};

  /// The highest entry id a playlist node has listed so far.
  int _maxListedEntryId = -1;

  /// The descriptors behind the `fd://` entries (Android `content://`),
  /// released once mpv can no longer read them.
  final HeldSources _heldSources = HeldSources();

  /// Hands the platform resource of [resolved] to [_heldSources]. Its
  /// dispose still releases it at once, for a load that aborts before
  /// mpv lists the entry.
  ResolvedUri _hold(ResolvedUri resolved) {
    final dispose = resolved.dispose;
    if (dispose == null) return resolved;
    return ResolvedUri(resolved.uri, _heldSources.hold(resolved.uri, dispose));
  }

  /// Deletes a resume point saved under the descriptor number of an
  /// `fd://` [resolved] source, before its load. mpv keys the point by
  /// that number, which the system hands out again to the next file
  /// opened, so a point saved for one file (0.5.1 and earlier wrote them)
  /// started another at its position. mpv reads the point as the entry
  /// loads, before any option of the entry applies, so no option can turn
  /// it off for one entry.
  Future<void> _forgetFdResume(ResolvedUri resolved) async {
    if (!isFdUri(resolved.uri)) return;
    await _command(['delete-watch-later-config', resolved.uri]);
  }

  /// Releases the held resources mpv has stopped reading.
  void _releaseSettledSources() {
    if (_heldSources.isEmpty) return;
    for (final release in _heldSources.takeSettled()) {
      unawaited(release());
    }
  }

  /// The last `playlist` node, parsed again when a `loadfile` reply
  /// registers an entry id after mpv already reported the entry.
  Object? _lastPlaylistNode;

  // Monotonic generation counter for content-replacing transport calls.
  // Bumped synchronously at the head of open(), openAll(),
  // openPlaylistFile(), stop() and clearPlaylist(); every load path
  // re-checks it after each await and aborts when stale. Without it,
  // per-scheme resolve latencies (asset:// does real I/O, a plain path
  // resolves in one microtask) let an EARLIER call issue its loadfile
  // AFTER a later one: the superseded media would win, and an in-flight
  // open() could resume past a stop() and restart playback.
  int _loadEpoch = 0;

  /// Claims the load epoch for a content-replacing call: every earlier
  /// load in flight is superseded from now on.
  _LoadTicket _claimLoad() => _LoadTicket(this, ++_loadEpoch);

  /// Snapshots the load epoch for a call that adds to the content (an
  /// append): superseded if a content-replacing call lands meanwhile.
  _LoadTicket _snapshotLoad() => _LoadTicket(this, _loadEpoch);

  /// How many open(), openAll() and openPlaylistFile() calls are running.
  /// While one is, an idle core is about to get content, so [Player.play]
  /// and the idle-active observer keep the intent.
  int _loadsInFlight = 0;

  /// mpv went idle while a load was running (openAll steps through idle
  /// at the end of the queue), and the intent reset that idle makes waits
  /// for the loads to end. Cleared when mpv leaves idle.
  bool _idleResetPending = false;

  /// Runs a content-replacing load, counted in [_loadsInFlight].
  Future<void> _trackLoad(Future<void> Function() load) async {
    _loadsInFlight++;
    try {
      await load();
    } finally {
      _loadsInFlight--;
      if (_loadsInFlight == 0 && _idleResetPending) await _settleIdleReset();
    }
  }

  /// The intent reset left to the end of the loads: still idle with no
  /// load running (one failed, or a later call cleared the playlist),
  /// nothing will play. Read from the core, since the notification that
  /// mpv left idle can come after the loads end.
  Future<void> _settleIdleReset() async {
    if (_disposed) return;
    final (rc, idle) = await _getAsync(
      'idle-active',
      MpvFormat.mpvFormatString,
    );
    if (!_idleResetPending || _loadsInFlight > 0 || _disposed) return;
    _idleResetPending = false;
    if (rc >= 0 && idle == 'yes') _writeIntent(false);
  }

  /// Bumped by every public call that sets the play-pause intent, so a
  /// call that corrects the intent after an await can tell whether a later
  /// call set it meanwhile (and then leaves it alone).
  int _intentEpoch = 0;

  /// Sets the play-pause intent for a public call and returns the epoch
  /// that call owns.
  int _claimIntent(bool value) {
    _writeIntent(value);
    return ++_intentEpoch;
  }

  /// Whether a load that claimed [intent] for [shouldPlay] starts playing:
  /// a play() or pause() called after it, while it resolved, has the last
  /// word, so its pause write must not undo theirs.
  bool _intendedPlay(int intent, bool shouldPlay) =>
      intent == _intentEpoch ? shouldPlay : _state.playWhenReady;

  /// Writes the play-pause intent ([PlayerState.playWhenReady]).
  void _writeIntent(bool value) => _updateField(
    (s) => s.copyWith(playWhenReady: value),
    _reactives.playWhenReady,
    value,
  );

  /// Puts back the intent a failed load replaced, unless a later call took
  /// over the load or the intent. Returns whether it did.
  bool _restoreIntent(_LoadTicket load, int intent, bool previous) {
    if (load.superseded || intent != _intentEpoch) return false;
    _writeIntent(previous);
    return true;
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

  /// Test-only; `null` outside [Player.testInstrumented].
  final int? _wakeupCounterAddress;

  // ── Cross-mixin surface ──────────────────────────────────────────────────
  // These members live in the `.part` mixins below but are declared here
  // (abstract) so `_PlayerBase`'s constructor, `dispose` and the sibling
  // domain mixins can call across part boundaries: `on _PlayerBase` only
  // exposes what `_PlayerBase` itself declares.

  /// See `_FfiModule` (player_ffi.part.dart). All writes ride the async
  /// client API (`mpv_*_async`): the call enqueues on the core's dispatch
  /// and the returned future completes when the event isolate forwards the
  /// reply, so the main isolate never waits for the playloop (which can be
  /// stalled for seconds inside audio-output init). Most setters update the
  /// state once that reply confirms the write; the play-pause intent and
  /// the settings bundles ([_writeBundle]) update it before the write.
  Future<void> _prop(String name, String value);
  Future<int> _propRc(String name, String value);
  Future<int> _command(List<String> args);
  Future<void> _loadfile(List<String> args, Media media);
  void _updatePlaylistFromNode(dynamic raw);
  Future<void> _commandChecked(List<String> args);
  Future<bool> _navigate(List<String> args);
  void _applyLogLevel(LogLevel level);
  Future<void> _writeBundle<T>(
    List<(String, String, String)> writes,
    ReactiveProperty<T> reactive,
    PlayerState Function(PlayerState state, T value) put,
    T next,
    T previous,
  );
  Future<int?> _checkPlaylistIndex(int index, String name);
  Future<int> _setChapterListNode(List<Chapter> chapters);

  /// Async property read (see `_FfiModule`): enqueues
  /// `mpv_get_property_async` and resolves with `(error, decodedValue)`
  /// once the event isolate forwards the reply.
  Future<(int, dynamic)> _getAsync(String name, int format);
  String _errorString(int code);

  /// The async request and reply channel to libmpv, created at bring-up
  /// together with [_lib] and [_handle].
  late final MpvClient _client;

  /// In-flight `registerHook` runs. `mpv_hook_add` locks the core and has no
  /// async variant, so it executes in a throwaway `Isolate.run` against the
  /// shared handle; dispose must await any outstanding one BEFORE
  /// `mpv_terminate_destroy` frees the handle, or the throwaway isolate would
  /// dereference freed memory (`lock_core(ctx)`).
  final Set<Future<void>> _pendingHookAdds = {};

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

  /// mpv reset the filters and rebuilt them from their stored arguments
  /// (a file load or a seek): see `_AudioModule`.
  void _onAfChainReset();

  /// mpv loaded a file, after applying the resume point it may hold: see
  /// `_AudioModule`.
  void _reassertAfChain();

  /// The MPV_EVENT_START_FILE events seen so far. A reply that arrives
  /// after a newer one may describe the file that load opened.
  int _fileStarts = 0;

  /// mpv sent AUDIO_RECONFIG: see `_AudioModule`.
  void _onAudioReconfig();

  /// See `_InitModule` (player_init.part.dart): called by the constructor.
  Future<void> _bringUpInIsolate();

  /// See `_DispatchModule` (player_dispatch.part.dart): wired as the event
  /// isolate's `onEvent` during bring-up.
  void _handleEvent(MpvIsolateEvent event);

  /// See `_DispatchModule`: `setAudioDevice` reuses it to optimistically
  /// resolve the device description from the parsed `audio-device-list`.
  void _updateActiveAudioDevice(String name);

  _PlayerBase({
    this.configuration = const PlayerConfiguration(),
    int? wakeupCounterAddress,
  }) : _wakeupCounterAddress = wakeupCounterAddress {
    // Pure-Dart setup runs on the main isolate (microseconds).
    _reactives = DefaultPropertyReactives();
    _registry = PropertyRegistry()
      ..registerAll(
        buildDefaultSpecs(
          _reactives,
          onIdleActive: (idle) {
            if (idle) {
              _updateLifecycle(playing: false, buffering: false);
              // mpv has entered its idle loop (nothing loaded) → the
              // play-pause intent is spent; settle the OS button on "play".
              // Gated on [_hasLoadedFile] so the startup idle-active burst
              // can't clear a fresh open(play: true) intent. mpv reaches idle
              // after a `stop`, or after a load that ends with no next entry
              // and is NOT held by keep-open (e.g. a failed first open). The
              // natural end of playable content under the shipped
              // `keep-open: yes` does NOT fire idle-active; that path is
              // handled by [_settleEndOfContent] instead. A mid-playlist
              // advance also doesn't fire idle-active. While a load runs
              // the idle is its own step (openAll at the end of the queue
              // removes the parked entry before its appends), so the reset
              // waits for the loads to end ([_settleIdleReset]): made
              // now, it flickered the OS button and undid a play() called
              // during the load.
              if (_hasLoadedFile) {
                if (_loadsInFlight > 0) {
                  _idleResetPending = true;
                } else {
                  _writeIntent(false);
                }
                // No file is loaded any more (stop, a cleared playlist, a
                // failed load): nothing of the last one should linger.
                _clearFinishedFile();
              }
            } else {
              _idleResetPending = false;
            }
          },
          onAudioOutputState: (state) {
            final err = buildAudioOutputError(state);
            if (err != null) _errorCtrl.add(err);
            if (state == AudioOutputState.active) {
              unawaited(_reportNullFallback());
            }
          },
        ),
      );

    // Streams that don't need _lib or _handle can be wired immediately:
    // a consumer subscribing right after `Player()` sees no events
    // until init completes, which is the correct semantics.
    //
    // The fft and pcm bridges into the spectrum pipeline are listener-gated:
    // the pipeline arms its 30fps `pcm-tap-frame` poll as soon as its own
    // streams have a listener, so bridging unconditionally would keep the
    // poll running for the player's whole lifetime with zero consumers.
    // Subscribers that land before bring-up are reconciled once the
    // pipeline exists (see `_bringUpInIsolate`).
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
    // consumer is subscribed. The pipeline is built during isolate
    // bring-up; a subscriber that lands before then is reconciled
    // once bring-up finishes (see `_bringUpInIsolate`).
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

    // Build the recipe and hand it to the event isolate. All heavy
    // FFI runs there; the main isolate stays free. A failed init reaches
    // every call that awaits it; a player nobody uses yet must not report
    // it as an unhandled error.
    _ready = _bringUpInIsolate()..ignore();
  }

  /// Test-only: allows tests to await the post-`Player()` init that
  /// now runs in the background isolate. Public methods already
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

  /// Shared prologue for every public method that touches the FFI handle:
  /// fail fast when already disposed, await bring-up, then verify bring-up
  /// actually assigned the FFI fields. A dispose() that lands while the
  /// caller is parked on [_ready] aborts bring-up early: [_ready] still
  /// completes normally, but `_lib` and `_handle` were never assigned, so
  /// resuming into an FFI call would throw [LateInitializationError]
  /// instead of the [PlayerDisposedException] the API contract promises.
  Future<void> _gate() async {
    _checkNotDisposed();
    await _ready;
    if (!_bringUpCompleted) {
      throw const PlayerDisposedException();
    }
  }

  /// Completes when every write currently on the wire has been executed
  /// (its reply forwarded, or settled by the dispose drain). Snapshot
  /// semantics: writes enqueued after this call are not waited on.
  ///
  /// The synchronous client API implicitly guaranteed "previous request
  /// EXECUTED before the next public call's request is issued"; with the
  /// async API two requests can coalesce into one core dispatch drain and
  /// interact: e.g. an un-awaited `seek` surviving a replace `loadfile`
  /// (its `queue_seek` entry rides into the NEW file) instead of being
  /// aborted by it. Content-replacing and playlist-navigation methods call
  /// this right before their first write so earlier in-flight transport
  /// commands are executed first, restoring the old inter-call semantics
  /// while the main isolate stays free: under a stalled core the FUTURES
  /// queue up, not the UI thread.
  Future<void> _settleWrites() => _client.settleWrites();

  /// Whether mpv reached the end of the current file, parked by
  /// `keep-open` or about to park, read from the core's own `eof-reached`
  /// rather than from `state.completed`. That flag comes from the event
  /// isolate's [MpvEventEndOfContent] reads, which reach the main isolate
  /// behind the events still queued ahead of them: right after a short
  /// last entry parks, `completed` can still be false. The calls that
  /// replace or jump need the core's answer at the call: an unpause
  /// written while mpv is about to park does not survive the park, so
  /// they write it again after the load.
  Future<bool> _parkedAtEof() async =>
      await getRawProperty('eof-reached') == 'yes';

  /// Whether mpv is parked: at the end of the file and paused, which
  /// keep-open does only once the output buffer has played out. In the
  /// last buffer before that, `eof-reached` is already true while the
  /// audio still plays.
  Future<bool> _parkedPaused() async =>
      await _parkedAtEof() && await getRawProperty('pause') == 'yes';

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

  /// Clears the per-track fields a consumer is likely to read
  /// synchronously on a track-change boundary (the public open()
  /// path returns before the new file's MPV_EVENT_FILE_LOADED
  /// fires).
  ///
  /// Restricted to fields where mpv re-emits the new value reliably
  /// after the load. mpv's own observer (see
  /// `player/client.c::send_client_property_changes`) dedupes on
  /// `equal_mpv_value(prop->value, val)`, so any property whose new
  /// value happens to match the previously-observed value (same
  /// `duration` across two tracks; same `embedded-cover-art-data`
  /// for same-album files; same `chapter-list`) would NOT fire
  /// PROPERTY_CHANGE. Wrapper-side reset to defaults on those would
  /// strand the cell at the default until the next genuinely-new
  /// value arrives. `position` is safe because `time-pos` re-emits
  /// at ~30Hz during playback. The remaining fields are handled by
  /// custom paths that do not depend on mpv's observer dedup.
  void _clearPerFileState() {
    final r = _reactives;
    r.position.update(Duration.zero);
    r.currentChapter.update(null);
    r.chapters.update(const <Chapter>[]);
    _state = _state.copyWith(
      position: Duration.zero,
      coverArt: null,
      currentChapter: null,
      chapters: const <Chapter>[],
    );
    _coverArtCtrl.add(null);
  }

  /// Clears what [_clearPerFileState] clears plus the file's waveform and
  /// loudness scan, once mpv is idle with no file loaded: it reports path,
  /// title and duration unavailable then, and these would otherwise keep
  /// showing the file that ended. The end of content under `keep-open`
  /// keeps the file loaded, and its cover with it.
  void _clearFinishedFile() {
    if (_disposed) return;
    _clearPerFileState();
    _waveformPipeline.clear();
    _loudnessScanPipeline.clear();
  }

  /// Updates the lifecycle triple (playing, buffering, completed) and
  /// emits per-reactive only for fields that actually changed. Used
  /// for compound transitions (start-file, file-loaded, end-file,
  /// end of content, shutdown, idle-active). The pure diff lives in
  /// [computeLifecycle].
  void _updateLifecycle({bool? playing, bool? buffering, bool? completed}) {
    final result = computeLifecycle(
      prev: _state,
      playing: playing,
      buffering: buffering,
      completed: completed,
    );
    _state = result.newState;
    if (result.playingDidChange) _reactives.playing.update(playing!);
    if (result.bufferingDidChange) _buffering.update(buffering!);
    if (result.completedDidChange) _completed.update(completed!);
  }

  /// Settles `completed` from where the core stands against the end of
  /// content, as the event isolate read it ([MpvEventEndOfContent]): the
  /// current file is parked at its end ([parked]) and is the last playlist
  /// entry ([lastEntry]), with no loop that will restart it. `keep-open:
  /// yes` (shipped pre-init option) makes mpv park paused on the last frame
  /// there and withhold both MPV_EVENT_END_FILE and idle-active, so the two
  /// writers that otherwise settle the transport (the END_FILE completed
  /// flag and the idle-active intent reset) never fire for the last entry.
  /// The park, not `eof-reached`, is the end: with gapless audio mpv
  /// reports EOF once the decoder is done, an output buffer before the end
  /// is heard, and pauses only after that buffer has played.
  ///
  /// It is a level, read again at every load, restart, `eof-reached`,
  /// `pause` and `loop-*` notification, not the observed `eof-reached` edge
  /// matched against `state.playlist`: mpv samples observed properties once
  /// per playloop iteration, so an entry that reaches EOF as soon as it
  /// loads can go from the previous entry's EOF to its own without a change
  /// being reported, and the state's playlist position can lag or lead the
  /// entry an edge belonged to. That raised `completed` at a track
  /// change, cleared by the next load, and missed the real end.
  ///
  /// A live PCM entry ([live]) has no restart either: from libmpv-r18 it
  /// plays once and parks under [Loop.file] too (F225).
  void _settleEndOfContent({
    required bool parked,
    required bool lastEntry,
    required bool live,
  }) {
    if (!_hasLoadedFile) return;
    final loop = _state.loop;
    final end =
        parked &&
        lastEntry &&
        (loop == Loop.off || (live && loop == Loop.file));
    if (end == _state.completed) return;
    _updateLifecycle(completed: end);
    // The play-pause intent is spent at the end of content; leaving the
    // end (a seek back, a new file) keeps it. Only on the edge: a jump or
    // a replace issued at the park can see one more parked read before
    // its load starts, and must keep its intent.
    if (end) _writeIntent(false);
  }

  /// The output just opened. With `audio-fallback-to-null` (pre-init
  /// options) mpv opens the null driver when no device can be opened: the
  /// state says `active` and the position runs, but nothing is heard.
  /// Reported on [PlayerStream.error] once for each opening, unless the
  /// app chose the null driver itself. Read from the core, not the state:
  /// `current-ao` is reported after `audio-output-state`.
  Future<void> _reportNullFallback() async {
    if (!_bringUpCompleted || _disposed) return;
    final (rc, current) = await _getAsync(
      'current-ao',
      MpvFormat.mpvFormatString,
    );
    if (rc < 0 || current != 'null' || _disposed) return;
    final (aoRc, ao) = await _getAsync('ao', MpvFormat.mpvFormatString);
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
  /// 2. **Await bring-up**, then **drop the [OrphanHandleTracker] entry**
  ///    so a hot-restart that fires before the destroy completes doesn't
  ///    try to clean up a handle we're already cleaning up, and **dispose
  ///    the DSP pipelines** (each turns off what it armed).
  /// 3. **Send the `quit` command** to mpv. mpv processes it
  ///    asynchronously and fires `MPV_EVENT_SHUTDOWN` inside its own
  ///    event queue.
  /// 4. **`requestStop` (stop flag + `mpv_wakeup`)** so the event loop
  ///    unwinds deterministically even if `quit` was dropped or
  ///    `MPV_EVENT_SHUTDOWN` is delayed by a stalled hook. Then dispose
  ///    the filter taps, whose streams the app listens to directly.
  /// 5. **Await `_eventIsolate.stop()`**, which returns `true` only once
  ///    the isolate has ACTUALLY exited, so it is provably off
  ///    `mpv_wait_event`. Then wait (bounded) for any `registerHook` still
  ///    running `mpv_hook_add`, and **close the client**, which settles
  ///    every in-flight call.
  /// 6. **`mpvTerminateDestroy(_handle)`** ONLY when the exit and the hook
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
      OrphanHandleTracker.instance.remove(_handle);
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
      unawaited(_command(['quit']));
      _eventIsolate.requestStop(_lib, _handle);
      // The taps after the quit: their streams are the app's own, and
      // nothing a listener does may keep mpv alive. The analyzer-taps write
      // still reaches the core, which serves it before the destroy below.
      await _filterTapPipeline.dispose();
      final exited = await _eventIsolate.stop();
      // A registerHook may still be running mpv_hook_add in a throwaway
      // isolate against this handle: it MUST finish before the handle is
      // freed below. quit + the stop above have driven the core toward a
      // dispatch point, so the core-locked hook_add is granted and returns.
      // Bounded: if it doesn't settle (a pathologically stuck playloop), skip
      // the destroy and leak the handle rather than free it under the running
      // isolate (same trade-off as an unconfirmed event-isolate exit).
      // Re-read the set until it is empty: Future.wait takes a snapshot, and
      // a setSourceResolver suspended between its two registrations could
      // start the second one after it.
      var hooksSettled = true;
      final hooksDeadline = DateTime.now().add(const Duration(seconds: 2));
      while (hooksSettled && _pendingHookAdds.isNotEmpty) {
        final left = hooksDeadline.difference(DateTime.now());
        try {
          await Future.wait(_pendingHookAdds.toList()).timeout(left);
        } on TimeoutException {
          hooksSettled = false;
        } catch (_) {}
      }
      // From here no FFI may touch the handle, and no reply can arrive:
      // closing the client resolves every in-flight call, so an
      // `await player.setX(...)` racing dispose never hangs, and turns the
      // continuations that resumes (a setter suspended between writes)
      // into no-ops, while the destroy below frees the handle.
      _client.close();
      if (exited && hooksSettled) {
        // Off the main isolate: the destroy waits for the core to shut down.
        await terminateDestroyOffMain(_handle);
        // mpv is gone: nothing reads the descriptors any more.
        for (final release in _heldSources.takeAll()) {
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
        await _eventIsolate.stop();
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

/// A load-path call's view of the load epoch, taken with
/// [_PlayerBase._claimLoad] or [_PlayerBase._snapshotLoad].
final class _LoadTicket {
  _LoadTicket(this._player, this._epoch);

  final _PlayerBase _player;
  final int _epoch;

  /// Whether the player was disposed, or a later content-replacing call
  /// took over, since the ticket was taken. Re-check after every await.
  bool get superseded => _player._disposed || _player._loadEpoch != _epoch;
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
