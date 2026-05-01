import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../services/audio_handler.dart';
import 'widgets/cover_artwork.dart';
import 'widgets/seeker.dart';
import 'widgets/track_info.dart';
import 'widgets/transport_controls.dart';
import 'widgets/volume_control.dart';

/// Player tab — composes the cover artwork, track info chips, seek
/// slider, transport controls, and volume slider into the responsive
/// layout. Owns the [CoverArtRaw] subscription because two children
/// (`CoverArtwork` and `TrackInfo`) need to read the same bytes:
/// keeping the listener here avoids duplicating it.
class PlaybackTab extends StatefulWidget {
  final Player player;
  final MpvAudioHandler audioHandler;

  const PlaybackTab({
    super.key,
    required this.player,
    required this.audioHandler,
  });

  @override
  State<PlaybackTab> createState() => _PlaybackTabState();
}

class _PlaybackTabState extends State<PlaybackTab> {
  CoverArtRaw? _cover;
  // Pixel dimensions of the current cover, decoded asynchronously after
  // it arrives. `null` while the decode is in flight or if the bytes
  // were undecodable.
  int? _coverWidth;
  int? _coverHeight;
  StreamSubscription<CoverArtRaw?>? _coverSub;

  @override
  void initState() {
    super.initState();
    // Bootstrap from the audio handler: the mpv coverArtRaw stream is
    // broadcast (no replay), so without this the cover would disappear
    // every time this widget gets rebuilt mid-session — e.g. when the
    // player page swaps its layout between mobile and desktop.
    final bootstrap = widget.audioHandler.lastCover;
    if (bootstrap != null) {
      _cover = bootstrap;
      _decodeDimensions(bootstrap);
    }
    _coverSub = widget.player.stream.coverArtRaw.listen((raw) {
      if (!mounted) return;
      setState(() {
        _cover = raw;
        _coverWidth = null;
        _coverHeight = null;
      });
      // raw == null when the new track has no embedded artwork: clear
      // the displayed cover and skip decode.
      if (raw != null) _decodeDimensions(raw);
    });
  }

  Future<void> _decodeDimensions(CoverArtRaw raw) async {
    try {
      // ignore: deprecated_member_use
      final codec = await ui.instantiateImageCodec(raw.bytes);
      try {
        final frame = await codec.getNextFrame();
        try {
          // Skip if the user moved on to a new track while we decoded.
          if (!mounted || !identical(_cover, raw)) return;
          setState(() {
            _coverWidth = frame.image.width;
            _coverHeight = frame.image.height;
          });
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    } catch (_) {
      // Truncated / unsupported bytes — leave dims null. The cover
      // itself may still render via Image.memory's own decode.
    }
  }

  @override
  void dispose() {
    _coverSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableHeight = constraints.maxHeight;
        // Responsive cover size — ~35 % of the available height, capped
        // so the artwork doesn't dominate small windows.
        final double coverSize = (availableHeight * 0.35).clamp(160, 280);
        final double verticalPadding =
            (availableHeight * 0.05).clamp(8, 32);

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: verticalPadding,
          ),
          child: Column(
            children: [
              const Spacer(),
              CoverArtwork(cover: _cover, size: coverSize),
              const Spacer(),
              TrackInfo(
                player: widget.player,
                cover: _cover,
                coverWidth: _coverWidth,
                coverHeight: _coverHeight,
                availableHeight: availableHeight,
              ),
              // Sandwich [audio chips → 12 → slider → 12 → pos row] sits
              // as one cohesive block — the symmetric padding lives
              // inside Seeker. No flexible Spacer above the slider, or
              // the sandwich would be visually skewed.
              Seeker(player: widget.player),
              const Spacer(),
              TransportControls(
                player: widget.player,
                availableHeight: availableHeight,
              ),
              const Spacer(),
              VolumeControl(player: widget.player),
              const Spacer(),
            ],
          ),
        );
      },
    );
  }
}
