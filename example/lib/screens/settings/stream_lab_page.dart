import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../models/stream_category.dart';
import '../../widgets/property_cards.dart';

const streamCategories = [
  StreamCategory(
    name: 'MP3 Reference',
    items: [
      StreamItem(
        label: 'MP3 128k Stereo (Standard)',
        url: 'https://streams.radiomast.io/ref-128k-mp3-stereo',
      ),
      StreamItem(
        label: 'MP3 128k Stereo (with Preroll)',
        url: 'https://streams.radiomast.io/ref-128k-mp3-stereo-preroll',
      ),
      StreamItem(
        label: 'MP3 32k Mono (Low-Bandwidth)',
        url: 'https://streams.radiomast.io/ref-32k-mp3-mono',
      ),
    ],
  ),
  StreamCategory(
    name: 'AAC Reference (Advanced Audio Coding)',
    items: [
      StreamItem(
        label: 'AAC-LC 128k Stereo',
        url: 'https://streams.radiomast.io/ref-128k-aaclc-stereo',
      ),
      StreamItem(
        label: 'HE-AAC v1 64k Stereo (SBR)',
        url: 'https://streams.radiomast.io/ref-64k-heaacv1-stereo',
      ),
      StreamItem(
        label: 'HE-AAC v2 64k Stereo (SBR+PS)',
        url: 'https://streams.radiomast.io/ref-64k-heaacv2-stereo',
      ),
      StreamItem(
        label: 'HE-AAC v1 24k Mono',
        url: 'https://streams.radiomast.io/ref-24k-heaacv1-mono',
      ),
    ],
  ),
  StreamCategory(
    name: 'Ogg / Open Formats',
    items: [
      StreamItem(
        label: 'Ogg Vorbis 64k Stereo',
        url: 'https://streams.radiomast.io/ref-64k-ogg-vorbis-stereo',
      ),
      StreamItem(
        label: 'Ogg Opus 64k Stereo',
        url: 'https://streams.radiomast.io/ref-64k-ogg-opus-stereo',
      ),
    ],
  ),
  StreamCategory(
    name: 'Lossless & High-Fidelity',
    items: [
      StreamItem(
        label: 'Ogg FLAC (16-bit Lossless)',
        url: 'https://streams.radiomast.io/ref-lossless-ogg-flac-stereo',
      ),
      StreamItem(
        label: 'Radio Paradise (Main Mix FLAC)',
        url: 'http://stream.radioparadise.com/flacm',
      ),
    ],
  ),
  StreamCategory(
    name: 'HLS (HTTP Live Streaming)',
    items: [
      StreamItem(
        label: 'MP3 128k HLS Adaptive',
        url: 'https://streams.radiomast.io/ref-128k-mp3-stereo/hls.m3u8',
      ),
      StreamItem(
        label: 'AAC-LC 128k HLS Adaptive',
        url: 'https://streams.radiomast.io/ref-128k-aaclc-stereo/hls.m3u8',
      ),
      StreamItem(
        label: 'Apple BipBop (HLS Audio)',
        url:
            'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear0/prog_index.m3u8',
      ),
    ],
  ),
];

class StreamLabPage extends StatelessWidget {
  final Player player;

  const StreamLabPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        ...streamCategories.map((cat) => _buildCategorySection(context, cat)),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, StreamCategory cat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PropertySectionHeader(title: cat.name.toUpperCase()),
        ...cat.items.map((item) => _StreamItemCard(player: player, item: item)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _StreamItemCard extends StatelessWidget {
  final Player player;
  final StreamItem item;

  const _StreamItemCard({required this.player, required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: cs.surfaceContainerLow.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        title: Text(
          item.label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StreamActionButton(
              icon: Icons.play_arrow_rounded,
              onPressed: () => player.open(
                Media(
                  item.url,
                  extras: {
                    ...?item.extras,
                    'title': item.label,
                    'artist': 'Stream Lab Reference',
                  },
                  httpHeaders: item.httpHeaders,
                ),
                play: true,
              ),
              color: cs.primary,
            ),
            const SizedBox(width: 8),
            _StreamActionButton(
              icon: Icons.add_rounded,
              onPressed: () => player.add(
                Media(
                  item.url,
                  extras: {
                    ...?item.extras,
                    'title': item.label,
                    'artist': 'Stream Lab Reference',
                  },
                  httpHeaders: item.httpHeaders,
                ),
              ),
              color: cs.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _StreamActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _StreamActionButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
