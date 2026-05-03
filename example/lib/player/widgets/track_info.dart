import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'info_chip.dart';

/// Title + artist text plus the wrap of audio-info chips
/// (codec / sample rate / format / bitrate, plus secondary
/// muted chips for cover-art metadata when one is present).
///
/// Receives the cover bytes + decoded dimensions from the parent
/// because the parent already owns the `coverArt` stream
/// subscription (also feeding [CoverArtwork] above).
class TrackInfo extends StatelessWidget {
  final Player player;
  final CoverArt? cover;
  final int? coverWidth;
  final int? coverHeight;
  final double availableHeight;

  const TrackInfo({
    super.key,
    required this.player,
    required this.cover,
    required this.coverWidth,
    required this.coverHeight,
    required this.availableHeight,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, String>>(
      stream: player.stream.metadata,
      initialData: player.state.metadata,
      builder: (context, metaSnap) {
        final metadata = metaSnap.data ?? const <String, String>{};
        final artist =
            metadata['artist'] ??
            metadata['ARTIST'] ??
            metadata['album_artist'];

        return Column(
          children: [
            // Title — paired with mpv's `media-title` (intelligent
            // display name with built-in fallback to the filename).
            StreamBuilder<String>(
              stream: player.stream.mediaTitle,
              initialData: player.state.mediaTitle,
              builder: (context, titleSnap) {
                final title = (titleSnap.data?.isNotEmpty ?? false)
                    ? titleSnap.data!
                    : 'Unknown';
                return Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: (availableHeight * 0.03).clamp(18.0, 24.0),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
            if (artist != null)
              Text(
                artist,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: (availableHeight * 0.02).clamp(14.0, 16.0),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            const SizedBox(height: 12),
            _AudioParamsChips(
              player: player,
              cover: cover,
              coverWidth: coverWidth,
              coverHeight: coverHeight,
            ),
          ],
        );
      },
    );
  }
}

class _AudioParamsChips extends StatelessWidget {
  final Player player;
  final CoverArt? cover;
  final int? coverWidth;
  final int? coverHeight;

  const _AudioParamsChips({
    required this.player,
    required this.cover,
    required this.coverWidth,
    required this.coverHeight,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AudioParams>(
      stream: player.stream.audioParams,
      initialData: player.state.audioParams,
      builder: (context, paramSnap) {
        final p = paramSnap.data ?? const AudioParams();
        final c = cover;
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            if (p.codec != null) InfoChip(label: p.codec!.toUpperCase()),
            if (p.sampleRate != null)
              InfoChip(
                label: '${(p.sampleRate! / 1000).toStringAsFixed(1)} kHz',
              ),
            if (p.format != null) InfoChip(label: p.format!.toUpperCase()),
            StreamBuilder<double?>(
              stream: player.stream.audioBitrate,
              builder: (_, bSnap) {
                final bps = bSnap.data;
                if (bps == null || bps <= 0) return const SizedBox.shrink();
                return InfoChip(label: '${(bps / 1000).round()} kbps');
              },
            ),
            // Cover-art info chips, in muted (grey) tone so they read
            // as secondary metadata next to the audio chips above.
            // Resolution shows `decoding…` while dart:ui finishes the
            // first frame of the new bytes (a few ms per track), then
            // snaps to the real pixel dimensions.
            if (c != null) ...[
              InfoChip(
                label: (coverWidth != null && coverHeight != null)
                    ? '$coverWidth × $coverHeight'
                    : 'decoding…',
                muted: true,
              ),
              InfoChip(
                // Strip the `image/` prefix and uppercase the subtype
                // to match the visual style of the audio chips above
                // (MP3 / FLAC / S16 / …).
                label: c.mimeType.split('/').last.toUpperCase(),
                muted: true,
              ),
              InfoChip(
                label: '${(c.bytes.length / 1024).toStringAsFixed(1)} KB',
                muted: true,
              ),
            ],
          ],
        );
      },
    );
  }
}
