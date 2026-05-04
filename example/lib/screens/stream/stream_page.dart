import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../../shared/property_cards.dart';
import 'widgets/stream_catalog.dart';
import 'widgets/stream_item_card.dart';

class StreamPage extends StatelessWidget {
  final Player player;

  const StreamPage({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        for (final cat in streamCategories)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PropertySectionHeader(title: cat.name.toUpperCase()),
              for (final item in cat.items)
                StreamItemCard(player: player, item: item),
              const SizedBox(height: 8),
            ],
          ),
        const SizedBox(height: 32),
      ],
    );
  }
}
