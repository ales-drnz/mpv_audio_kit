import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

class PlaybackTab extends StatefulWidget {
  final Player player;

  const PlaybackTab({super.key, required this.player});

  @override
  State<PlaybackTab> createState() => _PlaybackTabState();
}

class _PlaybackTabState extends State<PlaybackTab> {
  double? _dragVolume;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableHeight = constraints.maxHeight;
        // Calculate a responsive size for the cover art (approx 35% of height, but capped)
        final double coverSize = (availableHeight * 0.35).clamp(160, 280);
        final double verticalPadding = (availableHeight * 0.05).clamp(8, 32);

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: verticalPadding,
          ),
          child: Column(
            children: [
              const Spacer(),
              // Cover Art & Metadata Section
              StreamBuilder<Playlist>(
                stream: widget.player.stream.playlist,
                initialData: widget.player.state.playlist,
                builder: (context, playlistSnap) {
                  final playlist = playlistSnap.data ?? const Playlist.empty();
                  final currentMedia = playlist.medias.isNotEmpty
                      ? playlist.medias[playlist.index]
                      : null;

                  final artBytes = currentMedia?.extras?['artBytes'];
                  final String? coverUrl =
                      currentMedia?.extras?['artUri']?.toString() ??
                      currentMedia?.extras?['cover']?.toString();

                  Widget? coverImage;

                  if (artBytes is Uint8List) {
                    coverImage = Image.memory(artBytes, fit: BoxFit.cover);
                  } else if (coverUrl != null) {
                    if (coverUrl.startsWith('http') ||
                        coverUrl.startsWith('data:')) {
                      coverImage = Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image, size: 80),
                      );
                    } else {
                      coverImage = Image.file(
                        File(coverUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image, size: 80),
                      );
                    }
                  }

                  return Center(
                    child: Container(
                      width: coverSize,
                      height: coverSize,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(coverSize * 0.1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          coverImage ??
                          Icon(
                            Icons.music_note_rounded,
                            size: coverSize * 0.4,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  );
                },
              ),
              const Spacer(),

              // Track title & audio info
              StreamBuilder<Map<String, String>>(
                stream: widget.player.stream.metadata,
                initialData: widget.player.state.metadata,
                builder: (context, metaSnap) {
                  final metadata = metaSnap.data ?? {};
                  final title =
                      metadata['title'] ??
                      metadata['TITLE'] ??
                      (widget.player.state.playlist.medias.isNotEmpty
                          ? widget
                                .player
                                .state
                                .playlist
                                .medias[widget.player.state.playlist.index]
                                .uri
                                .split('/')
                                .last
                          : 'Unknown');
                  final artist =
                      metadata['artist'] ??
                      metadata['ARTIST'] ??
                      metadata['album_artist'];

                  return Column(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: (availableHeight * 0.03).clamp(
                                18.0,
                                24.0,
                              ),
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (artist != null)
                        Text(
                          artist,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: (availableHeight * 0.02).clamp(
                                  14.0,
                                  16.0,
                                ),
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                      const SizedBox(height: 12),
                      StreamBuilder<AudioParams>(
                        stream: widget.player.stream.audioParams,
                        initialData: widget.player.state.audioParams,
                        builder: (context, paramSnap) {
                          final p = paramSnap.data ?? const AudioParams();
                          return Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.center,
                            children: [
                              if (p.codec != null)
                                _InfoChip(label: p.codec!.toUpperCase()),
                              if (p.sampleRate != null)
                                _InfoChip(
                                  label:
                                      '${(p.sampleRate! / 1000).toStringAsFixed(1)} kHz',
                                ),
                              if (p.format != null)
                                _InfoChip(label: p.format!.toUpperCase()),
                              StreamBuilder<double?>(
                                stream: widget.player.stream.audioBitrate,
                                builder: (_, bSnap) {
                                  final bps = bSnap.data;
                                  if (bps == null || bps <= 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return _InfoChip(
                                    label: '${(bps / 1000).round()} kbps',
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),

              // Seek slider
              _Seeker(player: widget.player),

              const Spacer(),

              // Transport controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: (availableHeight * 0.06).clamp(32.0, 40.0),
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: () => widget.player.previous(),
                    color: cs.primary,
                  ),
                  const SizedBox(width: 16),
                  StreamBuilder<bool>(
                    stream: widget.player.stream.playing,
                    initialData: widget.player.state.playing,
                    builder: (context, snap) {
                      final isPlaying = snap.data ?? false;
                      final iconSize = (availableHeight * 0.08).clamp(
                        48.0,
                        56.0,
                      );
                      return Container(
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          iconSize: iconSize.toDouble(),
                          color: cs.onPrimary,
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          onPressed: () => widget.player.playOrPause(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    iconSize: (availableHeight * 0.06).clamp(32.0, 40.0),
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: () => widget.player.next(),
                    color: cs.primary,
                  ),
                ],
              ),
              const Spacer(),

              // Volume slider
              StreamBuilder<double>(
                stream: widget.player.stream.volume,
                initialData: widget.player.state.volume,
                builder: (context, volSnap) {
                  final vol = volSnap.data ?? 100.0;
                  final displayVol = _dragVolume ?? vol;

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
                            value: displayVol.clamp(0.0, 100.0),
                            onChanged: (v) {
                              setState(() => _dragVolume = v);
                            },
                            onChangeEnd: (v) async {
                              widget.player.setVolume(v);
                              await Future.delayed(
                                const Duration(milliseconds: 500),
                              );
                              if (mounted) {
                                setState(() => _dragVolume = null);
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${displayVol.round()}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
            ],
          ),
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
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
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

class _Seeker extends StatefulWidget {
  final Player player;
  const _Seeker({required this.player});

  @override
  State<_Seeker> createState() => _SeekerState();
}

class _SeekerState extends State<_Seeker> {
  double? _dragValue;
  bool get _isDragging => _dragValue != null;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<Duration>(
      stream: widget.player.stream.position,
      initialData: widget.player.state.position,
      builder: (context, posSnap) {
        return StreamBuilder<Duration>(
          stream: widget.player.stream.duration,
          initialData: widget.player.state.duration,
          builder: (context, durSnap) {
            final pos = posSnap.data ?? Duration.zero;
            final dur = durSnap.data ?? Duration.zero;
            final isValidDur = dur > Duration.zero;

            double progress;
            if (_isDragging) {
              progress = _dragValue!;
            } else {
              progress = isValidDur
                  ? (pos.inMicroseconds / dur.inMicroseconds).clamp(0.0, 1.0)
                  : 0.0;
            }

            final displayPos = _isDragging
                ? Duration(
                    microseconds: (progress * dur.inMicroseconds).round(),
                  )
                : pos;

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
                    activeTrackColor: cs.primary,
                    inactiveTrackColor: cs.primary.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: progress,
                    onChangeStart: (v) {
                      setState(() => _dragValue = v);
                    },
                    onChanged: (v) {
                      setState(() => _dragValue = v);
                    },
                    onChangeEnd: (v) async {
                      final seekTo = Duration(
                        microseconds: (v * dur.inMicroseconds).round(),
                      );
                      widget.player.seek(seekTo);

                      await Future.delayed(const Duration(milliseconds: 500));
                      if (mounted) {
                        setState(() => _dragValue = null);
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _fmt(displayPos),
                        style: const TextStyle(fontSize: 12),
                      ),
                      StreamBuilder<Duration>(
                        stream: widget.player.stream.buffer,
                        builder: (context, snap) {
                          final bufferSecs =
                              (snap.data?.inMilliseconds ?? 0) / 1000.0;
                          if (bufferSecs <= 0) return const SizedBox.shrink();
                          return Text(
                            'Buffer: ${bufferSecs.toStringAsFixed(1)}s',
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.primary.withValues(alpha: 0.7),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          );
                        },
                      ),
                      Text(_fmt(dur), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
