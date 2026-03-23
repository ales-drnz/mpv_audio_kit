import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

/// Bridges [Player] with the OS system media controls via audio_service.
///
/// Keeps [playbackState], [mediaItem], and [queue] in sync with the player
/// and delegates all control commands (play, pause, seek, skip) back to it.
class MpvAudioHandler extends BaseAudioHandler with SeekHandler, QueueHandler {
  final Player player;
  final List<StreamSubscription> _subs = [];

  MpvAudioHandler(this.player) {
    _bindStreams();
    // Populate initial state synchronously.
    _updatePlaybackState();
    _syncQueue(player.state.playlist);
  }

  void _bindStreams() {
    _subs.add(player.stream.playing.listen((_) => _updatePlaybackState()));
    _subs.add(player.stream.position.listen((_) => _updatePlaybackState()));
    _subs.add(player.stream.buffering.listen((_) => _updatePlaybackState()));
    _subs.add(player.stream.completed.listen((_) => _updatePlaybackState()));
    _subs.add(player.stream.rate.listen((_) => _updatePlaybackState()));
    _subs.add(player.stream.playlist.listen(_syncQueue));
    _subs.add(player.stream.metadata.listen((_) => _updateMediaItem()));
    _subs.add(player.stream.duration.listen((_) => _updateMediaItem()));
  }

  void _updatePlaybackState() {
    final s = player.state;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          s.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: s.buffering
            ? AudioProcessingState.buffering
            : s.completed
            ? AudioProcessingState.completed
            : AudioProcessingState.ready,
        playing: s.playing,
        updatePosition: s.position,
        bufferedPosition: s.buffer,
        speed: s.rate,
        queueIndex: s.playlist.index >= 0 ? s.playlist.index : null,
      ),
    );
  }

  void _updateMediaItem() {
    final s = player.state;
    final media = s.playlist.medias;
    final idx = s.playlist.index;
    if (media.isEmpty || idx < 0 || idx >= media.length) {
      mediaItem.add(null);
      return;
    }
    final current = media[idx];
    final meta = s.metadata;
    mediaItem.add(
      MediaItem(
        id: current.uri,
        title: meta['title'] ?? _titleFromUri(current.uri),
        artist: meta['artist'],
        album: meta['album'],
        duration: s.duration == Duration.zero ? null : s.duration,
      ),
    );
  }

  void _syncQueue(Playlist playlist) {
    queue.add(
      playlist.medias.map((m) {
        return MediaItem(id: m.uri, title: _titleFromUri(m.uri));
      }).toList(),
    );
    _updateMediaItem();
  }

  String _titleFromUri(String uri) {
    final name = uri.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  // --- Control commands ---

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToNext() => player.next();

  @override
  Future<void> skipToPrevious() => player.previous();

  @override
  Future<void> skipToQueueItem(int index) => player.jump(index);

  @override
  Future<void> stop() async {
    await player.pause();
    await player.seek(Duration.zero);
    playbackState.add(
      playbackState.value.copyWith(processingState: AudioProcessingState.idle),
    );
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
  }
}
