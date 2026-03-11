import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

class PlaybackTab extends StatefulWidget {
  final Player player;

  const PlaybackTab({super.key, required this.player});

  @override
  State<PlaybackTab> createState() => _PlaybackTabState();
}

class _PlaybackTabState extends State<PlaybackTab> {
  /// Format [Duration] as `mm:ss`.
  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _cycleLoopMode(PlaylistMode current) {
    final next = switch (current) {
      PlaylistMode.none   => PlaylistMode.single,
      PlaylistMode.single => PlaylistMode.loop,
      PlaylistMode.loop   => PlaylistMode.none,
    };
    widget.player.setPlaylistMode(next);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildNowPlayingCard(),
        const SizedBox(height: 32),
        _buildQueueSection(),
      ],
    );
  }

  Widget _buildNowPlayingCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: -10,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // Album art placeholder
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.music_note, size: 70, color: Colors.white),
              ),
              const SizedBox(height: 24),

              // Track title & audio info
              StreamBuilder<AudioParams>(
                stream: widget.player.stream.audioParams,
                initialData: widget.player.state.audioParams,
                builder: (_, snap) {
                  final params = snap.data;
                  final playlist = widget.player.state.playlist;
                  final currentUri = playlist.medias.isNotEmpty
                      ? playlist.medias[playlist.index].uri
                      : null;
                  final title = currentUri?.split('/').last ?? 'Unknown';

                  return Column(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (params != null) ...[
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (params.format != null)
                                _InfoChip(label: params.format!.toUpperCase()),
                              if (params.sampleRate != null) ...[
                                const SizedBox(width: 8),
                                _InfoChip(
                                  label:
                                      '${(params.sampleRate! / 1000).toStringAsFixed(1)} kHz',
                                ),
                              ],
                              StreamBuilder<double?>(
                                stream: widget.player.stream.audioBitrate,
                                builder: (_, bSnap) {
                                  final bps = bSnap.data;
                                  if (bps == null || bps <= 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return Row(children: [
                                    const SizedBox(width: 8),
                                    _InfoChip(label: '${(bps / 1000).round()} kbps'),
                                  ]);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Seek slider
              StreamBuilder<Duration>(
                stream: widget.player.stream.position,
                initialData: widget.player.state.position,
                builder: (_, posSnap) {
                  return StreamBuilder<Duration>(
                    stream: widget.player.stream.duration,
                    initialData: widget.player.state.duration,
                    builder: (_, durSnap) {
                      final pos = posSnap.data ?? Duration.zero;
                      final dur = durSnap.data ?? Duration.zero;
                      final isValidDur = dur > Duration.zero;
                      final progress = isValidDur
                          ? (pos.inMicroseconds / dur.inMicroseconds).clamp(0.0, 1.0)
                          : 0.0;
                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                            ),
                            child: Slider(
                              value: progress,
                              onChanged: isValidDur
                                  ? (v) {
                                      final seekTo = Duration(
                                        microseconds:
                                            (v * dur.inMicroseconds).round(),
                                      );
                                      widget.player.seek(seekTo);
                                    }
                                  : null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_fmt(pos),
                                    style: const TextStyle(fontSize: 12)),
                                Text(_fmt(dur),
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),

              // Transport controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Shuffle
                  StreamBuilder<bool>(
                    stream: widget.player.stream.shuffle,
                    initialData: widget.player.state.shuffle,
                    builder: (context, snap) {
                      final isShuffle = snap.data ?? false;
                      return IconButton(
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: isShuffle
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.5),
                          size: 24,
                        ),
                        onPressed: () =>
                            widget.player.setShuffle(!isShuffle),
                      );
                    },
                  ),
                  // Previous
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    iconSize: 36,
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: widget.player.previous,
                  ),
                  // Play / Pause
                  StreamBuilder<bool>(
                    stream: widget.player.stream.playing,
                    initialData: widget.player.state.playing,
                    builder: (_, playSnap) {
                      return StreamBuilder<bool>(
                        stream: widget.player.stream.buffering,
                        initialData: widget.player.state.buffering,
                        builder: (_, bufSnap) {
                          final playing = playSnap.data ?? false;
                          final buffering = bufSnap.data ?? false;
                          return Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.tertiary,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: IconButton(
                              iconSize: 36,
                              color: Colors.white,
                              icon: buffering
                                  ? const SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded),
                              onPressed: widget.player.playOrPause,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  // Next
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    iconSize: 36,
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: widget.player.next,
                  ),
                  // Loop
                  StreamBuilder<PlaylistMode>(
                    stream: widget.player.stream.playlistMode,
                    initialData: widget.player.state.playlistMode,
                    builder: (context, snap) {
                      final mode = snap.data ?? PlaylistMode.none;
                      final (icon, active) = switch (mode) {
                        PlaylistMode.none => (Icons.repeat_rounded, false),
                        PlaylistMode.single => (Icons.repeat_one_rounded, true),
                        PlaylistMode.loop => (Icons.repeat_rounded, true),
                      };
                      return IconButton(
                        icon: Icon(
                          icon,
                          color: active
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.5),
                          size: 24,
                        ),
                        onPressed: () => _cycleLoopMode(mode),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Volume
              StreamBuilder<double>(
                stream: widget.player.stream.volume,
                initialData: widget.player.state.volume,
                builder: (_, snap) {
                  final vol = snap.data ?? 100;
                  return Row(
                    children: [
                      StreamBuilder<bool>(
                        stream: widget.player.stream.mute,
                        initialData: widget.player.state.mute,
                        builder: (context, muteSnap) {
                          final isMute = muteSnap.data ?? false;
                          return IconButton(
                            icon: Icon(
                              isMute ? Icons.volume_off : Icons.volume_down,
                              size: 20,
                            ),
                            onPressed: () =>
                                widget.player.setMute(!isMute),
                          );
                        },
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                          ),
                          child: Slider(
                            min: 0,
                            max: 100,
                            value: vol.clamp(0.0, 100.0),
                            onChanged: (v) => widget.player.setVolume(v),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${vol.round()}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueueSection() {
    return StreamBuilder<Playlist>(
      stream: widget.player.stream.playlist,
      initialData: widget.player.state.playlist,
      builder: (context, snap) {
        final playlist = snap.data ?? const Playlist.empty();
        final list = playlist.medias;
        if (list.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'UP NEXT',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.5),
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.player.clearPlaylist,
                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                  label: const Text('Clear Queue'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainer
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.2),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (context, i) => Divider(
                  height: 1,
                  indent: 60,
                  endIndent: 20,
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.1),
                ),
                itemBuilder: (context, i) {
                  final media = list[i];
                  final isCurrent = i == playlist.index;
                  final label = (media.extras?['title'] as String?) ??
                      media.uri.split('/').last;
                  return ListTile(
                    onTap: () => widget.player.jump(i),
                    contentPadding: const EdgeInsets.only(left: 16, right: 8),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isCurrent
                            ? Icons.play_arrow_rounded
                            : Icons.music_note_rounded,
                        color: isCurrent
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: isCurrent
                        ? Text(
                            'Now Playing',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => widget.player.remove(i),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .secondaryContainer
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
