import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../../shared/property_cards.dart';

class AidPage extends StatelessWidget {
  final Player player;
  const AidPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PropertySectionHeader(title: 'Audio Track'),
        StreamBuilder<List<MpvTrack>>(
          stream: player.stream.tracks,
          initialData: player.state.tracks,
          builder: (context, tracksSnap) {
            final audioTracks = (tracksSnap.data ?? const <MpvTrack>[])
                .where((t) => t.type == 'audio' && !t.image && !t.albumart)
                .toList();
            return StreamBuilder<MpvTrack?>(
              stream: player.stream.currentAudioTrack,
              initialData: player.state.currentAudioTrack,
              builder: (context, currentSnap) {
                final current = currentSnap.data;
                final currentId = current?.id;

                final items = <DropdownMenuItem<int?>>[
                  const DropdownMenuItem(value: -1, child: Text('Auto')),
                  const DropdownMenuItem(value: -2, child: Text('No audio')),
                  ...audioTracks.map((t) {
                    final label = t.title?.isNotEmpty == true
                        ? '${t.id}: ${t.title}${t.lang != null ? ' [${t.lang}]' : ''}'
                        : '${t.id}${t.lang != null ? ' [${t.lang}]' : ''}';
                    return DropdownMenuItem(value: t.id, child: Text(label));
                  }),
                ];

                final selected = items.any((i) => i.value == currentId)
                    ? currentId
                    : -1;

                return DropdownPropertyCard<int?>(
                  title: 'Audio Track',
                  subtitle: current == null
                      ? 'no audio'
                      : 'aid=${current.id}'
                            '${current.lang != null ? ' (${current.lang})' : ''}',
                  icon: Icons.audiotrack_rounded,
                  value: selected,
                  items: items,
                  onChanged: (v) {
                    if (v == null) return;
                    final mode = switch (v) {
                      -1 => Track.auto,
                      -2 => Track.off,
                      _ => Track.id(v),
                    };
                    player.setAudioTrack(mode);
                  },
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
