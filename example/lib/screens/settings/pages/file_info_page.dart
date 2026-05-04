import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../../shared/property_cards.dart';

/// Read-only surface for current-file metadata — title, format, paths
/// (request → resolved → opened), filename, size.
class FileInfoPage extends StatelessWidget {
  final Player player;
  const FileInfoPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Identity'),
        _stringRow(
          title: 'Media Title',
          mpv: 'media-title',
          stream: player.stream.mediaTitle,
          initial: player.state.mediaTitle,
          icon: Icons.label_rounded,
        ),
        _stringRow(
          title: 'File Format',
          mpv: 'file-format',
          stream: player.stream.fileFormat,
          initial: player.state.fileFormat,
          icon: Icons.description_rounded,
        ),
        _intRow(
          title: 'File Size',
          mpv: 'file-size',
          stream: player.stream.fileSize,
          initial: player.state.fileSize,
          icon: Icons.straighten_rounded,
          format: (bytes) {
            if (bytes == 0) return '—';
            final mib = bytes / (1024 * 1024);
            return mib >= 1 ? '${mib.toStringAsFixed(2)} MiB' : '$bytes B';
          },
        ),

        // The 3 path-shaped properties surface DIFFERENT moments of the
        // open pipeline: stream-path is the URI as originally requested,
        // path is what mpv resolved (post-protocol resolution),
        // stream-open-filename is what mpv actually opens after any
        // on_load hook rewrite.
        const PropertySectionHeader(title: 'Open Pipeline'),
        _stringRow(
          title: 'Requested',
          mpv: 'stream-path',
          stream: player.stream.streamPath,
          initial: player.state.streamPath,
          icon: Icons.flight_takeoff_rounded,
        ),
        _stringRow(
          title: 'Resolved',
          mpv: 'path',
          stream: player.stream.path,
          initial: player.state.path,
          icon: Icons.folder_rounded,
        ),
        _stringRow(
          title: 'Opened',
          mpv: 'stream-open-filename',
          stream: player.stream.streamOpenFilename,
          initial: player.state.streamOpenFilename,
          icon: Icons.link_rounded,
        ),
        _stringRow(
          title: 'Filename',
          mpv: 'filename',
          stream: player.stream.filename,
          initial: player.state.filename,
          icon: Icons.insert_drive_file_rounded,
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _stringRow({
    required String title,
    required String mpv,
    required Stream<String> stream,
    required String initial,
    required IconData icon,
  }) {
    return StreamBuilder<String>(
      stream: stream,
      initialData: initial,
      builder: (_, snap) {
        final raw = snap.data ?? '';
        return ReadOnlyPropertyCard(
          title: title,
          subtitle: '$mpv=${raw.isEmpty ? '' : raw}',
          icon: icon,
          value: raw.isEmpty ? '—' : raw,
        );
      },
    );
  }

  Widget _intRow({
    required String title,
    required String mpv,
    required Stream<int> stream,
    required int initial,
    required IconData icon,
    required String Function(int) format,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      initialData: initial,
      builder: (_, snap) {
        final raw = snap.data ?? 0;
        return ReadOnlyPropertyCard(
          title: title,
          subtitle: '$mpv=$raw',
          icon: icon,
          value: format(raw),
        );
      },
    );
  }
}
