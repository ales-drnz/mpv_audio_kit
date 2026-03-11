import 'package:flutter/material.dart';
import 'package:mpv_audio_pro_kit/mpv_audio_pro_kit.dart';
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
  StreamCategory(
    name: '5. Metadata & Headers',
    items: [
      StreamItem(
        label: 'Track with Extras Example',
        url: 'https://files.freemusicarchive.org/storage-freemusicarchive-org/music/WFMU/Broke_For_Free/Directionless_EP/Broke_For_Free_-_01_-_Night_Owl.mp3',
        extras: {
          'title': 'Night Owl (Extras Example)',
          'artist': 'Broke For Free',
        },
        httpHeaders: {
          'User-Agent': 'mpv_audio_pro_kit_example/1.0',
        },
      ),
    ],
  ),
];

class StreamLabTab extends StatelessWidget {
  final Player player;

  const StreamLabTab({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Icon(Icons.science, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              'Stream Laboratory',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: streamCategories.asMap().entries.map((entry) {
              final i = entry.key;
              final cat = entry.value;
              return Column(
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Icon(
                        i == 0 ? Icons.high_quality : i == 1 ? Icons.audiotrack : i == 2 ? Icons.music_note : Icons.layers,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                      ),
                      title: Text(
                        cat.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      children: cat.items.map((s) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: Text(s.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(s.url, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _CompactActionButton(
                              icon: Icons.play_arrow_rounded, 
                              onPressed: () => player.open(Media(s.url, extras: s.extras, httpHeaders: s.httpHeaders), play: true),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            _CompactActionButton(
                              icon: Icons.add_rounded, 
                              onPressed: () => player.add(Media(s.url, extras: s.extras, httpHeaders: s.httpHeaders)),
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                  if (i < streamCategories.length - 1)
                    Divider(
                      height: 1, 
                      indent: 50, 
                      endIndent: 20, 
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.1)
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  const _CompactActionButton({required this.icon, required this.onPressed, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
