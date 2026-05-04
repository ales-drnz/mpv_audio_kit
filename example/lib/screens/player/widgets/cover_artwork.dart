import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

/// Pure rendering of the album cover artwork. Stateless: the parent
/// owns the [CoverArt] subscription so a sibling widget (e.g. the
/// track-info chip wrap) can read the same bytes without duplicating
/// the listener.
class CoverArtwork extends StatelessWidget {
  final CoverArt? cover;
  final double size;

  const CoverArtwork({super.key, required this.cover, required this.size});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(size * 0.1),
        ),
        clipBehavior: Clip.antiAlias,
        child: cover != null
            ? Image.memory(
                cover!.bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
            : Icon(
                Icons.music_note_rounded,
                size: size * 0.4,
                color: cs.onPrimaryContainer,
              ),
      ),
    );
  }
}
