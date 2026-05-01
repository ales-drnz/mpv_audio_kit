import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../shared/property_cards.dart';

class _StreamItem {
  final String label;
  final String url;
  const _StreamItem({required this.label, required this.url});
}

class _StreamCategory {
  final String name;
  final List<_StreamItem> items;
  const _StreamCategory({required this.name, required this.items});
}

const _streamCategories = [
  _StreamCategory(
    name: 'MP3 Reference',
    items: [
      _StreamItem(
        label: 'MP3 128k Stereo (Standard)',
        url: 'https://streams.radiomast.io/ref-128k-mp3-stereo',
      ),
      _StreamItem(
        label: 'MP3 128k Stereo (with Preroll)',
        url: 'https://streams.radiomast.io/ref-128k-mp3-stereo-preroll',
      ),
      _StreamItem(
        label: 'MP3 32k Mono (Low-Bandwidth)',
        url: 'https://streams.radiomast.io/ref-32k-mp3-mono',
      ),
    ],
  ),
  _StreamCategory(
    name: 'AAC Reference (Advanced Audio Coding)',
    items: [
      _StreamItem(
        label: 'AAC-LC 128k Stereo',
        url: 'https://streams.radiomast.io/ref-128k-aaclc-stereo',
      ),
      _StreamItem(
        label: 'HE-AAC v1 64k Stereo (SBR)',
        url: 'https://streams.radiomast.io/ref-64k-heaacv1-stereo',
      ),
      _StreamItem(
        label: 'HE-AAC v2 64k Stereo (SBR+PS)',
        url: 'https://streams.radiomast.io/ref-64k-heaacv2-stereo',
      ),
      _StreamItem(
        label: 'HE-AAC v1 24k Mono',
        url: 'https://streams.radiomast.io/ref-24k-heaacv1-mono',
      ),
    ],
  ),
  _StreamCategory(
    name: 'Ogg / Open Formats',
    items: [
      _StreamItem(
        label: 'Ogg Vorbis 64k Stereo',
        url: 'https://streams.radiomast.io/ref-64k-ogg-vorbis-stereo',
      ),
      _StreamItem(
        label: 'Ogg Opus 64k Stereo',
        url: 'https://streams.radiomast.io/ref-64k-ogg-opus-stereo',
      ),
    ],
  ),
  _StreamCategory(
    name: 'Lossless & High-Fidelity',
    items: [
      _StreamItem(
        label: 'Ogg FLAC (16-bit Lossless)',
        url: 'https://streams.radiomast.io/ref-lossless-ogg-flac-stereo',
      ),
      _StreamItem(
        label: 'Radio Paradise (Main Mix FLAC)',
        url: 'http://stream.radioparadise.com/flacm',
      ),
    ],
  ),
  _StreamCategory(
    name: 'HLS (HTTP Live Streaming)',
    items: [
      _StreamItem(
        label: 'MP3 128k HLS Adaptive',
        url: 'https://streams.radiomast.io/ref-128k-mp3-stereo/hls.m3u8',
      ),
      _StreamItem(
        label: 'AAC-LC 128k HLS Adaptive',
        url: 'https://streams.radiomast.io/ref-128k-aaclc-stereo/hls.m3u8',
      ),
      _StreamItem(
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
        ..._streamCategories.map((cat) => _buildCategorySection(context, cat)),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, _StreamCategory cat) {
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
  final _StreamItem item;

  const _StreamItemCard({required this.player, required this.item});

  Media _toMedia() => Media(
        item.url,
        extras: {
          'title': item.label,
          'artist': 'Stream Lab Reference',
        },
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PropertyBaseCard(
      title: item.label,
      subtitle: item.url,
      // No icon: each row's title + URL identifies the entry on its own.
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StreamActionButton(
            icon: Icons.play_arrow_rounded,
            onPressed: () => player.open(_toMedia(), play: true),
            color: cs.primary,
          ),
          const SizedBox(width: 8),
          _StreamActionButton(
            icon: Icons.add_rounded,
            onPressed: () => player.add(_toMedia()),
            color: cs.secondary,
          ),
        ],
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
