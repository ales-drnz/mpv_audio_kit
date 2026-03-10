import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

class PlaybackTab extends StatefulWidget {
  final MpvPlayer player;

  const PlaybackTab({super.key, required this.player});

  @override
  State<PlaybackTab> createState() => _PlaybackTabState();
}

class _PlaybackTabState extends State<PlaybackTab> {
  String _loopFile = 'no';
  String _loopPlaylist = 'no';

  String _fmt(double seconds) {
    if (seconds.isNaN || seconds.isInfinite) return '00:00';
    final d = Duration(seconds: seconds.toInt());
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildNowPlayingCard(),
      ),
    );
  }

  Widget _buildNowPlayingCard() {
    return Card(
      elevation: 8,
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
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
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.music_note,
                size: 70,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            StreamBuilder<MediaInfo>(
              stream: widget.player.mediaInfoStream,
              builder: (_, snap) {
                final info = snap.data;
                final title = info?.title ?? 'Unknown';
                final artist = info?.artist ?? 'No Artist - No Album';
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
                    Text(
                      artist,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (info != null &&
                        (info.codec != null || info.bitrate != null)) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (info.codec != null)
                            _InfoChip(label: info.codec!.toUpperCase()),
                          if (info.sampleRate != null) ...[
                            const SizedBox(width: 8),
                            _InfoChip(
                              label:
                                  '${(info.sampleRate! / 1000).toStringAsFixed(1)} kHz',
                            ),
                          ],
                          if (info.bitrate != null && info.bitrate! > 0) ...[
                            const SizedBox(width: 8),
                            _InfoChip(
                              label: '${(info.bitrate! / 1000).round()} kbps',
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            StreamBuilder<double>(
              stream: widget.player.positionStream,
              initialData: 0,
              builder: (_, posSnap) {
                return StreamBuilder<double?>(
                  stream: widget.player.durationStream,
                  initialData: null,
                  builder: (_, durSnap) {
                    final pos = posSnap.data ?? 0;
                    final dur = durSnap.data;
                    final isValidDur = dur != null && dur > 0;
                    final progress = isValidDur
                        ? (pos / dur).clamp(0.0, 1.0)
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
                                    widget.player.seek(v * dur);
                                  }
                                : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fmt(pos),
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                _fmt(dur ?? 0),
                                style: const TextStyle(fontSize: 12),
                              ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 32,
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: widget.player.playlistPrev,
                ),
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  onPressed: () => widget.player.seek(-10, relative: true),
                ),
                StreamBuilder<PlayerState>(
                  stream: widget.player.stateStream,
                  initialData: widget.player.state,
                  builder: (_, snap) {
                    final playing = snap.data == PlayerState.playing;
                    final buffering = snap.data == PlayerState.buffering;
                    return Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 32,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        icon: buffering
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(playing ? Icons.pause : Icons.play_arrow),
                        onPressed: widget.player.playOrPause,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  onPressed: () => widget.player.seek(10, relative: true),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 32,
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: widget.player.playlistNext,
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<double>(
              stream: widget.player.volumeStream,
              initialData: widget.player.volume,
              builder: (_, snap) {
                final vol = snap.data ?? 100;
                return Row(
                  children: [
                    StreamBuilder<bool>(
                      stream: widget.player.muteStream,
                      initialData: widget.player.mute,
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
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilterChip(
                    label: const Text(
                      'Loop Track',
                      style: TextStyle(fontSize: 11),
                    ),
                    selected: _loopFile == 'inf',
                    onSelected: (v) {
                      final next = v ? 'inf' : 'no';
                      setState(() => _loopFile = next);
                      widget.player.setLoopFile(next);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text(
                      'Loop Queue',
                      style: TextStyle(fontSize: 11),
                    ),
                    selected: _loopPlaylist == 'inf',
                    onSelected: (v) {
                      final next = v ? 'inf' : 'no';
                      setState(() => _loopPlaylist = next);
                      widget.player.setLoopPlaylist(next);
                    },
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text(
                      'Clear Queue',
                      style: TextStyle(fontSize: 11),
                    ),
                    avatar: const Icon(Icons.clear_all, size: 16),
                    onPressed: widget.player.playlistClear,
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text(
                      'Devices',
                      style: TextStyle(fontSize: 11),
                    ),
                    avatar: const Icon(Icons.speaker, size: 16),
                    onPressed: () {
                      final devs = widget.player.getAudioDeviceList() ?? 'none';
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Audio Devices'),
                          content: SingleChildScrollView(child: Text(devs)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
        color: Theme.of(
          context,
        ).colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
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
