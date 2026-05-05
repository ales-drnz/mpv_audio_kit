import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'widgets/empty_queue_placeholder.dart';
import 'widgets/queue_action_button.dart';
import 'widgets/queue_item_card.dart';

/// Audio file extensions accepted from drag-and-drop. Derived from
/// `AUDIO_DECODERS` in `scripts/_audio_only.sh` — every extension here
/// maps to at least one decoder ffmpeg ships in our bundled build.
/// Tracker formats (mod/xm/s3m/it) and MIDI (mid/kar) need libopenmpt
/// and libfluidsynth respectively, neither of which is linked, so
/// they're out. The whitelist is intentional: a blocklist lets video
/// containers and unknown binaries through, and mpv then logs
/// `[cplayer] fatal: No video or audio streams selected.` for each.
const _audioExtensions = <String>{
  // MPEG / AAC family
  'mp1', 'mp2', 'mp3', 'aac', 'adts',
  'm4a', 'm4b', 'm4p', 'mp4', // mp4/m4a containers — audio-only files
  // Vorbis / Opus / Speex (Ogg containers)
  'ogg', 'oga', 'opus', 'spx',
  // AC3 / EAC3 / DTS / TrueHD / MLP (broadcast / surround)
  'ac3', 'eac3', 'ec3', 'dts', 'thd', 'truehd', 'mlp',
  // Lossless
  'flac', 'alac', 'ape', 'wv', 'tta', 'shn',
  // PCM containers
  'wav', 'wave', 'aif', 'aiff', 'aifc', 'au', 'snd', 'caf',
  // Matroska audio
  'mka',
  // WMA family (asf container)
  'wma', 'asf',
  // RealAudio
  'ra', 'rm', 'ram',
  // Musepack
  'mpc', 'mp+', 'mpp',
  // DSD / SACD
  'dsd', 'dsf', 'dff',
  // Sony ATRAC
  'at3', 'at9', 'aa3', 'oma',
  // Audible
  'aa', 'aax',
  // Speech / telephony
  'gsm', 'amr',
};

/// Recursively walks every dropped DropItem (file or directory) and
/// returns audio paths sorted alphabetically per directory so a
/// dropped album folder loads in track order. Filtering is a strict
/// extension whitelist — see [_audioExtensions] for the rationale.
Future<List<String>> _collectAudioPaths(List<DropItem> drops) async {
  final paths = <String>[];

  bool isAudio(String path) {
    final name = path.split(Platform.pathSeparator).last;
    if (name.startsWith('._')) return false; // Apple metadata sidecar
    if (name.startsWith('.')) return false;  // dotfiles (Thumbs.db, .DS_Store)
    final dot = name.lastIndexOf('.');
    if (dot < 0) return false;
    return _audioExtensions.contains(name.substring(dot + 1).toLowerCase());
  }

  for (final entry in drops) {
    final type = await FileSystemEntity.type(entry.path);
    if (type == FileSystemEntityType.directory) {
      final dir = Directory(entry.path);
      final found = <String>[];
      await for (final e in dir.list(recursive: true, followLinks: false)) {
        if (e is File && isAudio(e.path)) found.add(e.path);
      }
      found.sort();
      paths.addAll(found);
    } else if (type == FileSystemEntityType.file && isAudio(entry.path)) {
      paths.add(entry.path);
    }
  }

  return paths;
}

class QueuePage extends StatefulWidget {
  final Player player;

  const QueuePage({super.key, required this.player});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  bool _picking = false;
  bool _dragging = false;

  // Local list — updated optimistically on reorder to avoid StreamBuilder flash.
  List<Media> _list = [];
  int _currentIndex = 0;
  bool _trackLoaded =
      false; // true when a track is actually loaded (playing or paused)
  StreamSubscription<Playlist>? _playlistSub;
  StreamSubscription<Duration>? _durationSub;

  Player get player => widget.player;

  bool get _isDesktop =>
      Theme.of(context).platform == TargetPlatform.macOS ||
      Theme.of(context).platform == TargetPlatform.windows ||
      Theme.of(context).platform == TargetPlatform.linux;

  @override
  void initState() {
    super.initState();
    _applyPlaylist(player.state.playlist);
    _playlistSub = player.stream.playlist.listen(_applyPlaylist);
    _trackLoaded = player.state.duration > Duration.zero;
    _durationSub = player.stream.duration.listen((d) {
      if (mounted) setState(() => _trackLoaded = d > Duration.zero);
    });
  }

  void _applyPlaylist(Playlist p) {
    if (mounted) {
      setState(() {
        _list = List.from(p.items);
        _currentIndex = p.index;
      });
    }
  }

  @override
  void dispose() {
    _playlistSub?.cancel();
    _durationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Note: shuffle / repeat live next to the play/pause button
          // in the Player tab; prefetch lives in Settings → Network.
          // Live prefetch state is surfaced as a chip below the seek
          // slider in the Player tab.
          const SizedBox(height: 16),
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UP NEXT',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  QueueActionButton(
                    onPressed: () async {
                      if (_picking) return;
                      setState(() => _picking = true);
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: _audioExtensions.toList(),
                          allowMultiple: true,
                        );
                        if (result != null) {
                          final wasEmpty = player.state.playlist.items.isEmpty;
                          final medias = [
                            for (final file in result.files)
                              if (file.path != null) Media(file.path!),
                          ];
                          if (medias.isNotEmpty) {
                            if (wasEmpty) {
                              await player.openAll(medias, play: true);
                            } else {
                              for (final m in medias) {
                                await player.add(m);
                              }
                            }
                          }
                        }
                      } finally {
                        if (mounted) setState(() => _picking = false);
                      }
                    },
                    icon: Icons.folder_open_rounded,
                    label: 'Add File',
                  ),
                  const SizedBox(width: 8),
                  if (_list.isNotEmpty)
                    QueueActionButton(
                      onPressed: player.clearPlaylist,
                      icon: Icons.delete_outline_rounded,
                      label: 'Clear Queue',
                      isError: true,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Queue box
          Expanded(
            child: DropTarget(
              onDragEntered: (_) => setState(() => _dragging = true),
              onDragExited: (_) => setState(() => _dragging = false),
              onDragDone: (detail) async {
                setState(() => _dragging = false);
                if (detail.files.isEmpty) return;
                final paths = await _collectAudioPaths(detail.files);
                if (paths.isEmpty) return;
                final wasEmpty = player.state.playlist.items.isEmpty;
                final medias = [for (final p in paths) Media(p)];
                if (wasEmpty) {
                  await player.openAll(medias, play: true);
                } else {
                  for (final m in medias) {
                    await player.add(m);
                  }
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _dragging
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Material(
                  color: _dragging
                      ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: _list.isEmpty
                      ? EmptyQueuePlaceholder(
                          isDragging: _dragging,
                          isDesktop: _isDesktop,
                        )
                      : ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          padding: EdgeInsets.zero,
                          // Remove the default elevation rectangle on the dragged item.
                          proxyDecorator: (child, index, animation) => child,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              final adjusted = newIndex > oldIndex
                                  ? newIndex - 1
                                  : newIndex;
                              final item = _list.removeAt(oldIndex);
                              _list.insert(adjusted, item);
                              // Keep _currentIndex pointing to the same track.
                              if (_currentIndex == oldIndex) {
                                _currentIndex = adjusted;
                              } else if (oldIndex < _currentIndex &&
                                  adjusted >= _currentIndex) {
                                _currentIndex--;
                              } else if (oldIndex > _currentIndex &&
                                  adjusted <= _currentIndex) {
                                _currentIndex++;
                              }
                            });
                            player.move(oldIndex, newIndex);
                          },
                          itemCount: _list.length,
                          itemBuilder: (context, i) => QueueItemCard(
                            key: ValueKey(_list[i].uri),
                            media: _list[i],
                            index: i,
                            total: _list.length,
                            isCurrent: i == _currentIndex && _trackLoaded,
                            onTap: () => player.jump(i),
                            onRemove: () => player.remove(i),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
