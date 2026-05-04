import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../../shared/property_cards.dart';
import 'stream_action_button.dart';
import 'stream_catalog.dart';

class StreamItemCard extends StatelessWidget {
  final Player player;
  final StreamItem item;

  const StreamItemCard({super.key, required this.player, required this.item});

  Media _toMedia() => Media(
    item.url,
    extras: {'title': item.label, 'artist': 'Stream Lab Reference'},
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
          StreamActionButton(
            icon: Icons.play_arrow_rounded,
            onPressed: () => player.open(_toMedia(), play: true),
            color: cs.primary,
          ),
          const SizedBox(width: 8),
          StreamActionButton(
            icon: Icons.add_rounded,
            onPressed: () => player.add(_toMedia()),
            color: cs.secondary,
          ),
        ],
      ),
    );
  }
}
