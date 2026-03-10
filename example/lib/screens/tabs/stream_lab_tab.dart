import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../models/stream_category.dart';

const streamCategories = [
  StreamCategory(
    name: '1. FLAC (Lossless Hi-Res)',
    items: [
      StreamItem(
        label: 'Radio Paradise (Main Mix)',
        url: 'http://stream.radioparadise.com/flacm',
      ),
      StreamItem(
        label: 'Sector Space (Ambient)',
        url: 'http://89.223.45.5:8000/space-flac',
      ),
    ],
  ),
  StreamCategory(
    name: '2. AAC / AAC+',
    items: [
      StreamItem(
        label: 'SomaFM Groove Salad (128k)',
        url: 'https://ice1.somafm.com/groovesalad-128-aac',
      ),
      StreamItem(
        label: '977 HITS (Icecast AAC)',
        url:
            'https://playerservices.streamtheworld.com/api/livestream-redirect/977_HITS_SC',
      ),
    ],
  ),
  StreamCategory(
    name: '3. MP3',
    items: [
      StreamItem(
        label: 'SomaFM Groove Salad (256k)',
        url: 'https://ice1.somafm.com/groovesalad-256-mp3',
      ),
      StreamItem(
        label: 'Vesti FM (Icecast 192k)',
        url: 'http://icecast.vgtrk.cdnvideo.ru/vestifm_mp3_192kbps',
      ),
    ],
  ),
  StreamCategory(
    name: '4. HLS / Adaptive Audio',
    items: [
      StreamItem(
        label: 'Apple HLS Audio (BipBop)',
        url:
            'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear0/prog_index.m3u8',
      ),
      StreamItem(
        label: 'Wowza ID3 (Metadata Test)',
        url:
            'https://playertest.longtailvideo.com/adaptive/wowzaid3/playlist.m3u8',
      ),
    ],
  ),
];

class StreamLabTab extends StatelessWidget {
  final MpvPlayer player;

  const StreamLabTab({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Stream Laboratory',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: streamCategories.length,
            itemBuilder: (context, i) {
              final cat = streamCategories[i];
              return ExpansionTile(
                title: Text(
                  cat.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                children: cat.items
                    .map(
                      (s) => ListTile(
                        dense: true,
                        title: Text(s.label),
                        subtitle: Text(
                          s.url,
                          style: const TextStyle(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton.filledTonal(
                              icon: const Icon(Icons.play_arrow, size: 18),
                              onPressed: () => player.open(s.url, play: true),
                              tooltip: 'Play (Replace)',
                            ),
                            const SizedBox(width: 4),
                            IconButton.filledTonal(
                              icon: const Icon(Icons.queue_music, size: 18),
                              onPressed: () => player.enqueue(s.url),
                              tooltip: 'Enqueue in background',
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
