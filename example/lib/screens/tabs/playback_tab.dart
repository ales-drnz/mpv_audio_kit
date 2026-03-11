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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(32),
          children: [
            _buildNowPlayingContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildNowPlayingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Album art placeholder
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.music_note,
              size: 100, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        const SizedBox(height: 32),

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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                if (params != null) ...[
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
        const SizedBox(height: 32),

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
                                  microseconds: (v * dur.inMicroseconds).round(),
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
                          Text(_fmt(pos), style: const TextStyle(fontSize: 12)),
                          Text(_fmt(dur), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),

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
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  onPressed: () => widget.player.setShuffle(!isShuffle),
                );
              },
            ),
            // Previous
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded),
              iconSize: 40,
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
                    return Ink(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 40,
                        color: Colors.white,
                        icon: buffering
                            ? const SizedBox(
                                width: 32,
                                height: 32,
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
              iconSize: 40,
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
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  onPressed: () => _cycleLoopMode(mode),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

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
                      onPressed: () => widget.player.setMute(!isMute),
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
                  width: 44,
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
      ],
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
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
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
